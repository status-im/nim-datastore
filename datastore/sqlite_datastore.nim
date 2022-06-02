import std/os

import pkg/questionable
import pkg/questionable/results
import pkg/sqlite3_abi
import pkg/upraises

import ./datastore

export datastore

push: {.upraises: [].}

# Adapted from:
# https://github.com/status-im/nwaku/blob/master/waku/v2/node/storage/sqlite.nim

type
  AutoDisposed[T: ptr|ref] = object
    val: T

  NoParams = tuple # empty tuple

  RawStmtPtr = ptr sqlite3_stmt

  SQLite = ptr sqlite3

  SQLiteDatastore* = ref object of Datastore
    dbPath: string
    env: SQLite

  SQLiteStmt[Params, Result] = distinct RawStmtPtr

const
  TableTitle = "Store"
  TimestampTableType = "INTEGER"

  dbExt* = ".sqlite3"

template dispose(db: SQLite) =
  discard sqlite3_close(db)

template dispose(rawStmt: RawStmtPtr) =
  discard sqlite3_finalize(rawStmt)

template dispose(sqliteStmt: SQLiteStmt) =
  discard sqlite3_finalize(RawStmtPtr sqliteStmt)

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
    dbPath = ":memory:"
  else:
    try:
      basep = normalizePathEnd(
        if basePath.isAbsolute: basePath
        else: getCurrentDir() / basePath)

      fname = filename.normalizePathEnd
      dbPath = basep / fname

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
    cleanup: untyped): ptr sqlite3_stmt =

    var
      stmt: ptr sqlite3_stmt

    checkErr sqlite3_prepare_v2(env.val, q, q.len.cint, addr stmt, nil):
      cleanup

    stmt

  template checkExec(s: ptr sqlite3_stmt) =
    if (let x = sqlite3_step(s); x != SQLITE_DONE):
      discard sqlite3_finalize(s)
      return failure $sqlite3_errstr(x)

    if (let x = sqlite3_finalize(s); x != SQLITE_OK):
      return failure $sqlite3_errstr(x)

  template checkExec(q: string) =
    let
      s = prepare(q): discard

    checkExec(s)

  template checkJournalModePragmaResult(journalModePragma: ptr sqlite3_stmt) =
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

  if not readOnly:
    let
      createStmt = prepare("""
        CREATE TABLE IF NOT EXISTS """ & TableTitle & """ (
            key BLOB NOT NULL PRIMARY KEY,
            data BLOB,
            timestamp """ & TimestampTableType & """ NOT NULL
        ) WITHOUT ROWID;
        """
      ): discard

    checkExec createStmt

  success T(dbPath: dbPath, env: env.release)

proc dbPath*(self: SQLiteDatastore): string =
  self.dbPath

proc env*(self: SQLiteDatastore): SQLite =
  self.env

proc close*(self: SQLiteDatastore) =
  discard sqlite3_close(self.env)
  self[] = SQLiteDatastore()[]

method contains*(
  self: SQLiteDatastore,
  key: Key): ?!bool =

  success false

method delete*(
  self: SQLiteDatastore,
  key: Key): ?!void =

  success()

method get*(
  self: SQLiteDatastore,
  key: Key): ?!(?seq[byte]) =

  success seq[byte].none

method put*(
  self: SQLiteDatastore,
  key: Key,
  data: openArray[byte]): ?!void =

  success()

# method query*(
#   self: SQLiteDatastore,
#   query: ...): ?!(?...) =
#
#   success ....none
