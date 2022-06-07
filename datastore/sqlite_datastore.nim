import std/os
import std/times

import pkg/questionable
import pkg/questionable/results
import pkg/sqlite3_abi
import pkg/stew/byteutils
import pkg/upraises

import ./datastore

export datastore

push: {.upraises: [].}

# Adapted from:
# https://github.com/status-im/nwaku/blob/master/waku/v2/node/storage/sqlite.nim

type
  AutoDisposed[T: ptr|ref] = object
    val: T

  NoParams* = tuple # empty tuple

  RawStmtPtr* = ptr sqlite3_stmt

  DataProc* = proc(s: RawStmtPtr) {.closure.}

  SQLite* = ptr sqlite3

  SQLiteStmt*[Params, Result] = distinct RawStmtPtr

  # feels odd to use `void` here but it fits with the rest of the SQLite
  # wrapper adapted from waku
  ContainsStmt = SQLiteStmt[(seq[byte]), void]

  DeleteStmt = SQLiteStmt[(seq[byte]), void]

  PutStmt = SQLiteStmt[(seq[byte], seq[byte], int64), void]

  SQLiteDatastore* = ref object of Datastore
    dbPath: string
    containsStmt: ContainsStmt
    deleteStmt: DeleteStmt
    env: SQLite
    putStmt: PutStmt
    readOnly: bool

const
  TableTitle* = "Store"

  IdTableType = "BLOB"
  DataTableType = "BLOB"
  TimestampTableType = "INTEGER"

  dbExt* = ".sqlite3"

proc timestamp*(): int64 =
  (epochTime() * 1_000_000).int64

template dispose(db: SQLite) =
  discard sqlite3_close(db)

template dispose(rawStmt: RawStmtPtr) =
  discard sqlite3_finalize(rawStmt)

template dispose(sqliteStmt: SQLiteStmt) =
  discard sqlite3_finalize(RawStmtPtr(sqliteStmt))

proc release[T](x: var AutoDisposed[T]): T =
  result = x.val
  x.val = nil

proc disposeIfUnreleased[T](x: var AutoDisposed[T]) =
  mixin dispose
  if x.val != nil: dispose(x.release)

template checkErr(op, cleanup: untyped) =
  if (let v = (op); v != SQLITE_OK):
    cleanup
    return failure $sqlite3_errstr(v)

template checkErr(op) =
  checkErr(op): discard

template prepare(
  env: SQLite,
  q: string,
  cleanup: untyped): RawStmtPtr =

  var
    s: RawStmtPtr

  checkErr sqlite3_prepare_v2(env, q.cstring, q.len.cint, addr s, nil):
    cleanup

  s

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
    var
      i = 1

    for param in fields(params):
      checkErr bindParam(s, i, param)
      inc i

  else:
    checkErr bindParam(s, 1, params)

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

proc new*(
  T: type SQLiteDatastore,
  basePath = "data",
  filename = "store" & dbExt,
  readOnly = false,
  inMemory = false): ?!T =

  # make it optional to enable WAL with it enabled being the default?

  # make it possible to specify a custom page size?
  # https://www.sqlite.org/pragma.html#pragma_page_size
  # https://www.sqlite.org/intern-v-extern-blob.html

  var
    env: AutoDisposed[SQLite]

  defer: disposeIfUnreleased(env)

  var
    basep, fname, dbPath: string

  if inMemory:
    if readOnly:
      return failure "SQLiteDatastore cannot be read-only and in-memory"
    else:
      dbPath = ":memory:"
  else:
    try:
      basep = normalizePathEnd(
        if basePath.isAbsolute: basePath
        else: getCurrentDir() / basePath)

      fname = filename.normalizePathEnd
      dbPath = basep / fname

      if readOnly and not fileExists(dbPath):
        return failure "read-only database does not exist: " & dbPath
      else:
        createDir(basep)

    except IOError as e:
      return failure e

    except OSError as e:
      return failure e

  let
    flags =
      if readOnly: SQLITE_OPEN_READONLY
      else: SQLITE_OPEN_READWRITE or SQLITE_OPEN_CREATE

  checkErr sqlite3_open_v2(dbPath.cstring, addr env.val, flags.cint, nil)

  template prepare(
    q: string,
    cleanup: untyped): RawStmtPtr =

    var
      s: RawStmtPtr

    checkErr sqlite3_prepare_v2(env.val, q.cstring, q.len.cint, addr s, nil):
      cleanup

    s

  template checkExec(s: RawStmtPtr) =
    if (let x = sqlite3_step(s); x != SQLITE_DONE):
      discard sqlite3_finalize(s)
      return failure $sqlite3_errstr(x)

    if (let x = sqlite3_finalize(s); x != SQLITE_OK):
      return failure $sqlite3_errstr(x)

  template checkExec(q: string) =
    let
      s = prepare(q): discard

    checkExec(s)

  template checkJournalModePragmaResult(journalModePragma: RawStmtPtr) =
    if (let x = sqlite3_step(journalModePragma); x != SQLITE_ROW):
      discard sqlite3_finalize(journalModePragma)
      return failure $sqlite3_errstr(x)

    if (let x = sqlite3_column_type(journalModePragma, 0); x != SQLITE3_TEXT):
      discard sqlite3_finalize(journalModePragma)
      return failure $sqlite3_errstr(x)

    if (let x = sqlite3_column_text(journalModePragma, 0);
        x != "memory" and x != "wal"):
      discard sqlite3_finalize(journalModePragma)
      return failure "Invalid pragma result: " & $x

  let
    journalModePragma = prepare("PRAGMA journal_mode = WAL;"): discard

  checkJournalModePragmaResult(journalModePragma)
  checkExec(journalModePragma)

  var
    containsStmt: RawStmtPtr
    deleteStmt: RawStmtPtr
    putStmt: RawStmtPtr

  if not readOnly:
    let
      createStmt = prepare("""
        CREATE TABLE IF NOT EXISTS """ & TableTitle & """ (
          id """ & IdTableType & """ NOT NULL PRIMARY KEY,
          data """ & DataTableType & """,
          timestamp """ & TimestampTableType & """ NOT NULL
        ) WITHOUT ROWID;
      """): discard

    checkExec createStmt

    # if an existing database does not have the expected schema, the following
    # `pepare()` will fail and `new` will return an error with message "SQL
    # logic error"

    deleteStmt = prepare("""
      DELETE FROM """ & TableTitle & """
      WHERE id = ?;
    """): discard

    putStmt = prepare("""
      REPLACE INTO """ & TableTitle & """ (
        id, data, timestamp
      ) VALUES (?, ?, ?);
      """
    ): discard

  # if a readOnly/existing database does not have the expected schema, the
  # following `pepare()` will fail and `new` will return an error with message
  # "SQL logic error"

  # https://stackoverflow.com/a/9756276
  containsStmt = prepare("""
    SELECT EXISTS(
      SELECT 1 FROM """ & TableTitle & """
      WHERE id = ?
    );
  """): discard

  success T(dbPath: dbPath, containsStmt: ContainsStmt(containsStmt),
            deleteStmt: DeleteStmt(deleteStmt), env: env.release,
            putStmt: PutStmt(putStmt), readOnly: readOnly)

proc dbPath*(self: SQLiteDatastore): string =
  self.dbPath

proc env*(self: SQLiteDatastore): SQLite =
  self.env

proc close*(self: SQLiteDatastore) =
  discard sqlite3_close(self.env)
  self[] = SQLiteDatastore()[]

proc idCol*(
  self: SQLiteDatastore,
  s: RawStmtPtr): string =

  const
    index = 0

  let
    idBytes = cast[ptr UncheckedArray[byte]](sqlite3_column_blob(s, index))
    idLen = sqlite3_column_bytes(s, index)

  string.fromBytes(@(toOpenArray(idBytes, 0, idLen - 1)))

proc dataCol*(
  self: SQLiteDatastore,
  s: RawStmtPtr): seq[byte] =

  const
    index = 1

  let
    dataBytes = cast[ptr UncheckedArray[byte]](sqlite3_column_blob(s, index))
    dataLen = sqlite3_column_bytes(s, index)

  @(toOpenArray(dataBytes, 0, dataLen - 1))

proc timestampCol*(
  self: SQLiteDatastore,
  s: RawStmtPtr): int64 =

  const
    index = 2

  sqlite3_column_int64(s, index)

proc rawQuery*(
  self: SQLiteDatastore,
  query: string,
  onData: DataProc): ?!bool =

  var
    s = prepare(self.env, query): discard

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

  # release implicit transaction
  discard sqlite3_reset(s) # same return information as step
  discard sqlite3_clear_bindings(s) # no errors possible
  # NB: dispose of the prepared query statement and free associated memory
  discard sqlite3_finalize(s)

  res

proc prepareStmt*(
  self: SQLiteDatastore,
  stmt: string,
  Params: type,
  Res: type): ?!SQLiteStmt[Params, Res] =

  var
    s: RawStmtPtr

  checkErr sqlite3_prepare_v2(
    self.env, stmt.cstring, stmt.len.cint, addr s, nil)

  success SQLiteStmt[Params, Res](s)

method contains*(
  self: SQLiteDatastore,
  key: Key): ?!bool =

  var
    exists = false

  proc onData(s: RawStmtPtr) {.closure.} =
    let
      v = sqlite3_column_int64(s, 0)

    if v == 1: exists = true

  discard self.containsStmt.query((key.id.toBytes), onData)

  success exists

method delete*(
  self: SQLiteDatastore,
  key: Key): ?!void =

  if self.readOnly:
    failure "database is read-only":
  else:
    self.deleteStmt.exec((key.id.toBytes))

method get*(
  self: SQLiteDatastore,
  key: Key): ?!(?seq[byte]) =

  success seq[byte].none

method put*(
  self: SQLiteDatastore,
  key: Key,
  data: openArray[byte],
  timestamp = timestamp()): ?!void =

  if self.readOnly:
    failure "database is read-only"
  else:
    self.putStmt.exec((key.id.toBytes, @data, timestamp))

# method query*(
#   self: SQLiteDatastore,
#   query: ...): ?!(?...) =
#
#   success ....none
