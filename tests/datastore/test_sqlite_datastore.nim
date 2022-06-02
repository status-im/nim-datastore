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
      db: SQLiteDatastore

    # assumes tests/test_all is run from project root, e.g. with `nimble test`
    let
      basePath = "tests" / "test_data"
      basePathAbs = getCurrentDir() / basePath
      filename = "test_store" & dbExt
      dbPathAbs = basePathAbs / filename

    db = nil
    removeDir(dbPathAbs)
    assert not dirExists(basePathAbs)

  teardown:
    if not db.isNil:
      db.close
      db = nil

    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

  test "new":
    var
      dbRes: Result[SQLiteDatastore, ref CatchableError]

    dbRes = SQLiteDatastore.new(basePathAbs, filename)

    assert dbRes.isOk
    db = dbRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    db.close
    db = nil
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    dbRes = SQLiteDatastore.new(basePath, filename)

    assert dbRes.isOk
    db = dbRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    db.close
    db = nil

    # for `readOnly = true` to succeed the database file must already exist on
    # disk, so the existing file (per previous step) is not deleted prior to
    # the next invocation of SQLiteDatastore.new

    dbRes = SQLiteDatastore.new(basePath, filename, readOnly = true)

    assert dbRes.isOk
    db = dbRes.get

    check:
      dirExists(basePathAbs)
      fileExists(dbPathAbs)

    db.close
    db = nil
    removeDir(basePathAbs)
    assert not dirExists(basePathAbs)

    dbRes = SQLiteDatastore.new(inMemory = true)

    assert dbRes.isOk
    db = dbRes.get

    check:
      not dirExists(basePathAbs)
      not fileExists(dbPathAbs)

    ds.close
    ds = nil

    dbRes = SQLiteDatastore.new(readOnly = true, inMemory = true)

    assert dbRes.isOk
    db = dbRes.get

    check:
      not dirExists(basePathAbs)
      not fileExists(dbPathAbs)

  test "accessors":
    check:
      true

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
