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
    let
      ds = FileSystemDatastore.new("tests" / "data")

    check:
      ds.isOk
      dirExists(getCurrentDir() / root)
