import std/options
import std/os

import pkg/stew/results
import pkg/unittest2

import ../../datastore/sqlite_datastore

suite "SQLiteDatastore":
  setup:
    var
      ds: SQLiteDatastore

    # assumes tests/test_all is run from project root, e.g. with `nimble test`
    let
      basePath = "tests" / "test_data"
      basePathAbs = getCurrentDir() / basePath
      filename = "test_store" & dbExt
      dbPathAbs = basePathAbs / filename

    ds = nil
    removeDir(basePathAbs)
    require(not dirExists(basePathAbs))

  teardown:
    if not ds.isNil:
      ds.close
      ds = nil

    removeDir(basePathAbs)
    require(not dirExists(basePathAbs))

  test "new":
    var
      dsRes = SQLiteDatastore.new(basePathAbs, filename, readOnly = true)

    # for `readOnly = true` to succeed the database file must already exist
    check: dsRes.isErr

    dsRes = SQLiteDatastore.new(basePathAbs, filename)

    assert dsRes.isOk
    ds = dsRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    ds.close
    ds = nil
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    dsRes = SQLiteDatastore.new(basePath, filename)

    assert dsRes.isOk
    ds = dsRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    ds.close
    ds = nil

    # for `readOnly = true` to succeed the database file must already exist, so
    # the existing file (per previous step) is not deleted prior to the next
    # invocation of `SQLiteDatastore.new`

    dsRes = SQLiteDatastore.new(basePath, filename, readOnly = true)

    assert dsRes.isOk
    ds = dsRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    ds.close
    ds = nil
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    dsRes = SQLiteDatastore.new(inMemory = true)

    assert dsRes.isOk
    ds = dsRes.get

    check:
      not dirExists(basePathAbs)
      not fileExists(dbPathAbs)

    ds.close
    ds = nil

    dsRes = SQLiteDatastore.new(readOnly = true, inMemory = true)

    check: dsRes.isErr

  test "accessors":
    ds = SQLiteDatastore.new(basePath).get

    check: parentDir(ds.dbPath) == basePathAbs

    check: not ds.env.isNil

  # test "helpers":
  #   check:
  #     true

  test "put":
    let
      key = Key.init("a:b/c/d:e").get

    # for `readOnly = true` to succeed the database file must already exist
    ds = SQLiteDatastore.new(basePathAbs, filename).get
    ds.close
    ds = nil
    ds = SQLiteDatastore.new(basePathAbs, filename, readOnly = true).get

    var
      bytes: seq[byte]
      timestamp = timestamp()
      putRes = ds.put(key, bytes, timestamp)

    check: putRes.isErr

    ds.close
    ds = nil
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    ds = SQLiteDatastore.new(basePathAbs, filename).get

    timestamp = timestamp()
    putRes = ds.put(key, bytes, timestamp)

    check: putRes.isOk

    let
      rawQuery = "SELECT * FROM " & TableTitle & ";"

    var
      qId: string
      qData: seq[byte]
      qTimestamp: int64
      rowCount = 0

    proc onData(s: RawStmtPtr) {.closure.} =
      qId = ds.idCol(s)
      qData = ds.dataCol(s)
      qTimestamp = ds.timestampCol(s)
      inc rowCount

    var
      qRes = ds.rawQuery(rawQuery, onData)

    assert qRes.isOk

    check:
      qRes.get
      qId == key.id
      qData == bytes
      qTimestamp == timestamp
      rowCount == 1

    bytes = @[1.byte, 2.byte, 3.byte]
    timestamp = timestamp()
    putRes = ds.put(key, bytes, timestamp)

    check: putRes.isOk

    rowCount = 0
    qRes = ds.rawQuery(rawQuery, onData)
    assert qRes.isOk

    check:
      qRes.get
      qId == key.id
      qData == bytes
      qTimestamp == timestamp
      rowCount == 1

    bytes = @[4.byte, 5.byte, 6.byte]
    timestamp = timestamp()
    putRes = ds.put(key, bytes, timestamp)

    check: putRes.isOk

    rowCount = 0
    qRes = ds.rawQuery(rawQuery, onData)
    assert qRes.isOk

    check:
      qRes.get
      qId == key.id
      qData == bytes
      qTimestamp == timestamp
      rowCount == 1

  test "delete":
    check:
      true

  test "contains":
    check:
      true

  test "get":
    check:
      true

  # test "query":
  #   check:
  #     true
