import std/options
import std/os

import pkg/stew/results
import pkg/unittest2

import ../../datastore/filesystem_datastore
import ../../datastore/sqlite_datastore
import ../../datastore/tiered_datastore

suite "TieredDatastore":
  setup:
    discard

  teardown:
    discard

  test "new":
    check:
      true

  test "accessors":
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
