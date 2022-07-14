import std/options
import std/os

import pkg/asynctest/unittest2
import pkg/chronos
import pkg/stew/results

import ../../datastore/sqlite_datastore
import ./templates

suite "SQLiteDatastore":
  var
    ds: SQLiteDatastore

  # assumes tests/test_all is run from project root, e.g. with `nimble test`
  let
    basePath = "tests" / "test_data"
    basePathAbs = getCurrentDir() / basePath
    filename = "test_store" & dbExt
    dbPathAbs = basePathAbs / filename

  setup:
    removeDir(basePathAbs)
    require(not dirExists(basePathAbs))

  teardown:
    if not ds.isNil: ds.close
    ds = nil
    removeDir(basePathAbs)
    require(not dirExists(basePathAbs))

  asyncTest "new":
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
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    dsRes = SQLiteDatastore.new(basePath, filename)

    assert dsRes.isOk
    ds = dsRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    ds.close

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
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    dsRes = SQLiteDatastore.new(inMemory = true)

    assert dsRes.isOk
    ds = dsRes.get

    check:
      not dirExists(basePathAbs)
      not fileExists(dbPathAbs)

    ds.close

    dsRes = SQLiteDatastore.new(readOnly = true, inMemory = true)

    check: dsRes.isErr

  asyncTest "accessors":
    ds = SQLiteDatastore.new(basePath).get

    check:
      parentDir(ds.dbPath) == basePathAbs
      not ds.env.isNil

  asyncTest "helpers":
    ds = SQLiteDatastore.new(basePath).get

    ds.close

    check:
      ds.env.isNil
      timestamp(10.123_456) == 10_123_456.int64

  asyncTest "put":
    let
      key = Key.init("a:b/c/d:e").get

    # for `readOnly = true` to succeed the database file must already exist
    ds = SQLiteDatastore.new(basePathAbs, filename).get
    ds.close
    ds = SQLiteDatastore.new(basePathAbs, filename, readOnly = true).get

    var
      bytes: seq[byte]
      timestamp = timestamp()
      putRes = await ds.put(key, bytes, timestamp)

    check: putRes.isErr

    ds.close
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    ds = SQLiteDatastore.new(basePathAbs, filename).get

    timestamp = timestamp()
    putRes = await ds.put(key, bytes, timestamp)

    check: putRes.isOk

    let
      prequeryRes = NoParamsStmt.prepare(
        ds.env, "SELECT timestamp AS foo, id AS baz, data AS bar FROM " &
          tableName & ";")

    assert prequeryRes.isOk

    let
      prequery = prequeryRes.get
      idCol = idCol(RawStmtPtr(prequery), 1)
      dataCol = dataCol(RawStmtPtr(prequery), 2)
      timestampCol = timestampCol(RawStmtPtr(prequery), 0)

    var
      qId: string
      qData: seq[byte]
      qTimestamp: int64
      rowCount = 0

    proc onData(s: RawStmtPtr) {.closure.} =
      qId = idCol()
      qData = dataCol()
      qTimestamp = timestampCol()
      inc rowCount

    var
      qRes = prequery.query((), onData)

    assert qRes.isOk

    check:
      qRes.get
      qId == key.id
      qData == bytes
      qTimestamp == timestamp
      rowCount == 1

    bytes = @[1.byte, 2.byte, 3.byte]
    timestamp = timestamp()
    putRes = await ds.put(key, bytes, timestamp)

    check: putRes.isOk

    rowCount = 0
    qRes = prequery.query((), onData)
    assert qRes.isOk

    check:
      qRes.get
      qId == key.id
      qData == bytes
      qTimestamp == timestamp
      rowCount == 1

    bytes = @[4.byte, 5.byte, 6.byte]
    timestamp = timestamp()
    putRes = await ds.put(key, bytes, timestamp)

    check: putRes.isOk

    rowCount = 0
    qRes = prequery.query((), onData)
    assert qRes.isOk

    check:
      qRes.get
      qId == key.id
      qData == bytes
      qTimestamp == timestamp
      rowCount == 1

    prequery.dispose

  asyncTest "delete":
    let
      bytes = @[1.byte, 2.byte, 3.byte]

    var
      key = Key.init("a:b/c/d:e").get

    # for `readOnly = true` to succeed the database file must already exist
    ds = SQLiteDatastore.new(basePathAbs, filename).get
    ds.close
    ds = SQLiteDatastore.new(basePathAbs, filename, readOnly = true).get

    var
      delRes = await ds.delete(key)

    check: delRes.isErr

    ds.close
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    ds = SQLiteDatastore.new(basePathAbs, filename).get

    let
      putRes = await ds.put(key, bytes)

    assert putRes.isOk

    let
      query = "SELECT * FROM " & tableName & ";"

    var
      rowCount = 0

    proc onData(s: RawStmtPtr) {.closure.} =
      inc rowCount

    var
      qRes = ds.env.query(query, onData)

    assert qRes.isOk
    check: rowCount == 1
    delRes = await ds.delete(key)

    check: delRes.isOk

    rowCount = 0
    qRes = ds.env.query(query, onData)
    assert qRes.isOk

    check:
      delRes.isOk
      rowCount == 0

    key = Key.init("X/Y/Z").get

    delRes = await ds.delete(key)

    check: delRes.isOk

  asyncTest "contains":
    let
      bytes = @[1.byte, 2.byte, 3.byte]

    var
      key = Key.init("a:b/c/d:e").get

    ds = SQLiteDatastore.new(basePathAbs, filename).get

    let
      putRes = await ds.put(key, bytes)

    assert putRes.isOk

    var
      containsRes = await ds.contains(key)

    assert containsRes.isOk

    check: containsRes.get == true

    key = Key.init("X/Y/Z").get

    containsRes = await ds.contains(key)
    assert containsRes.isOk

    check: containsRes.get == false

  asyncTest "get":
    ds = SQLiteDatastore.new(basePathAbs, filename).get

    var
      bytes: seq[byte]
      key = Key.init("a:b/c/d:e").get
      putRes = await ds.put(key, bytes)

    assert putRes.isOk

    var
      getRes = await ds.get(key)
      getOpt = getRes.get

    check: getOpt.isSome and getOpt.get == bytes

    bytes = @[1.byte, 2.byte, 3.byte]
    putRes = await ds.put(key, bytes)

    assert putRes.isOk

    getRes = await ds.get(key)
    getOpt = getRes.get

    check: getOpt.isSome and getOpt.get == bytes

    key = Key.init("X/Y/Z").get

    assert not (await ds.contains(key)).get

    getRes = await ds.get(key)
    getOpt = getRes.get

    check: getOpt.isNone

  # asyncTest "query":
  #   check:
  #     true
