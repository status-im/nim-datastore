import std/options
import std/os

import pkg/sqlite3_abi
import pkg/stew/byteutils
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
    removeDir(dbPathAbs)
    require(not dirExists(basePathAbs))

  teardown:
    if not ds.isNil:
      ds.close
      ds = nil

    removeDir(basePathAbs)
    require(not dirExists(basePathAbs))

  test "new":
    var
      dsRes: Result[SQLiteDatastore, ref CatchableError]

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

    # for `readOnly = true` to succeed the database file must already exist on
    # disk, so the existing file (per previous step) is not deleted prior to
    # the next invocation of SQLiteDatastore.new

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

    assert dsRes.isOk
    ds = dsRes.get

    check:
      not dirExists(basePathAbs)
      not fileExists(dbPathAbs)

  test "accessors":
    ds = SQLiteDatastore.new(basePath).get

    check: parentDir(ds.dbPath) == basePathAbs

    check: not ds.env.isNil

  test "helpers":
    check:
      true

  test "put":
    check:
      true

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
