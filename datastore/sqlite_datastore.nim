import std/os

import pkg/questionable
import pkg/questionable/results
import pkg/sqlite3_abi
import pkg/upraises

import ./datastore

export datastore

push: {.upraises: [].}

type
  SQLiteDatastore* = ref object of Datastore
    # db field with db connection
    dbPath: string

const
  dbExtension = ".sqlite3"
  dbExt* = dbExtension

proc new*(
  T: type SQLiteDatastore,
  dbPath = getCurrentDir() / "data" / "data" & dbExtension): ?!T =

  # should initialize the db file, but should connection be open or closed when
  # `new` returns?
  success T(dbPath: dbPath)

proc dbPath*(self: SQLiteDatastore): string =
  self.dbPath

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
