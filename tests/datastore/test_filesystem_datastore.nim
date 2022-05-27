import std/os

import pkg/questionable
import pkg/questionable/results
from pkg/stew/results as stewResults import get, isErr, isOk
import pkg/unittest2

import ../../datastore/filesystem_datastore

suite "FileSystemDatastore":
  setup:
    # assumes tests/test_all is run from project root, e.g. with `nimble test`
    let
      root = "tests" / "data"

    removeDir(getCurrentDir() / root)

  teardown:
    removeDir(getCurrentDir() / root)

  test "new":
    var
      ds = FileSystemDatastore.new(getCurrentDir() / root)

    check:
      ds.isOk
      dirExists(getCurrentDir() / root)

    removeDir(getCurrentDir() / root)

    check: not dirExists(getCurrentDir() / root)

    ds = FileSystemDatastore.new(root)

    check:
      ds.isOk
      dirExists(getCurrentDir() / root)

  test "contains":
    check:
      true

  test "delete":
    check:
      true

  test "get":
    check:
      true

  test "put":
    check:
      true

  # test "query":
  #   check:
  #     true
