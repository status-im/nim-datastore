import std/options
import std/os

import pkg/sqlite3_abi
import pkg/stew/byteutils
import pkg/stew/results
import pkg/unittest2

import ../../datastore/sqlite_datastore

suite "SQLiteDatastore":
  setup:
    # assumes tests/test_all is run from project root, e.g. with `nimble test`
    let
      dbPath = "tests" / "data" / "store" & dbExt
      dbPathAbs = getCurrentDir() / dbPath

    removeDir(dbPathAbs)
    assert not dirExists(dbPathAbs)

  teardown:
    removeDir(dbPathAbs)
    assert not dirExists(dbPathAbs)

  test "new":
    check:
      true

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
