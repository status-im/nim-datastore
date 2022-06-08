import pkg/questionable
import pkg/questionable/results
import pkg/sqlite3_abi
import pkg/upraises

# ? can be removed ?
export sqlite3_abi

push: {.upraises: [].}

# Adapted from:
# https://github.com/status-im/nwaku/blob/master/waku/v2/node/storage/sqlite.nim

type
  AutoDisposed*[T: ptr|ref] = object
    # ? can be private ?
    val*: T

  DataProc* = proc(s: RawStmtPtr) {.closure.}

  NoParams* = tuple # empty tuple

  NoParamsStmt* = SQLiteStmt[NoParams, void]

  RawStmtPtr* = ptr sqlite3_stmt

  SQLite* = ptr sqlite3

  SQLiteStmt*[Params, Res] = distinct RawStmtPtr

proc bindParam(
  s: RawStmtPtr,
  n: int,
  val: auto): cint =

  when val is openarray[byte]|seq[byte]:
    if val.len > 0:
      sqlite3_bind_blob(s, n.cint, unsafeAddr val[0], val.len.cint, nil)
    else:
      sqlite3_bind_blob(s, n.cint, nil, 0.cint, nil)
  elif val is int32:
    sqlite3_bind_int(s, n.cint, val)
  elif val is uint32:
    sqlite3_bind_int(s, int(n).cint, int(val).cint)
  elif val is int64:
    sqlite3_bind_int64(s, n.cint, val)
  elif val is float64:
    sqlite3_bind_double(s, n.cint, val)
  # Note: bind_text not yet supported in sqlite3_abi wrapper
  # elif val is string:
  #   # `-1` implies string length is number of bytes up to first null-terminator
  #   sqlite3_bind_text(s, n.cint, val.cstring, -1, nil)
  else:
    {.fatal: "Please add support for the '" & $typeof(val) & "' type".}

template bindParams(
  s: RawStmtPtr,
  params: auto) =

  when params is tuple:
    when params isnot NoParams:
      var
        i = 1

      for param in fields(params):
        checkErr bindParam(s, i, param)
        inc i

  else:
    checkErr bindParam(s, 1, params)

template checkErr*(op, cleanup: untyped) =
  if (let v = (op); v != SQLITE_OK):
    cleanup
    return failure $sqlite3_errstr(v)

template checkErr*(op) =
  checkErr(op): discard

template dispose*(db: SQLite) =
  discard sqlite3_close(db)

template dispose*(rawStmt: RawStmtPtr) =
  discard sqlite3_finalize(rawStmt)

template dispose*(sqliteStmt: SQLiteStmt) =
  discard sqlite3_finalize(RawStmtPtr(sqliteStmt))

proc disposeIfUnreleased*[T](x: var AutoDisposed[T]) =
  mixin dispose
  if x.val != nil: dispose(x.release)

proc exec*[P](
  s: SQLiteStmt[P, void],
  params: P): ?!void =

  let
    s = RawStmtPtr(s)

  bindParams(s, params)

  let
    res =
      if (let v = sqlite3_step(s); v != SQLITE_DONE):
        failure $sqlite3_errstr(v)
      else:
        success()

  # release implict transaction
  discard sqlite3_reset(s) # same return information as step
  discard sqlite3_clear_bindings(s) # no errors possible

  res

proc prepare*[Params, Res](
  T: type SQLiteStmt[Params, Res],
  env: SQLite,
  stmt: string): ?!T =

  var
    s: RawStmtPtr

  checkErr sqlite3_prepare_v2(env, stmt.cstring, stmt.len.cint, addr s, nil)

  success T(s)

proc query*[P](
  s: SQLiteStmt[P, void],
  params: P,
  onData: DataProc): ?!bool =

  let
    s = RawStmtPtr(s)

  bindParams(s, params)

  var
    res = success false

  while true:
    let
      v = sqlite3_step(s)

    case v
    of SQLITE_ROW:
      onData(s)
      res = success true
    of SQLITE_DONE:
      break
    else:
      res = failure $sqlite3_errstr(v)

  # release implict transaction
  discard sqlite3_reset(s) # same return information as step
  discard sqlite3_clear_bindings(s) # no errors possible

  res

proc query*(
  env: SQLite,
  query: string,
  onData: DataProc): ?!bool =

  let
    s = ? NoParamsStmt.prepare(env, query)
    res = s.query((), onData)

  # NB: dispose of the prepared query statement and free associated memory
  s.dispose

  res

proc release*[T](x: var AutoDisposed[T]): T =
  result = x.val
  x.val = nil
