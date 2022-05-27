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
      rootAbs = getCurrentDir() / root

    removeDir(rootAbs)
    assert not dirExists(rootAbs)

  teardown:
    removeDir(rootAbs)
    assert not dirExists(rootAbs)

  test "new":
    var
      dsRes: Result[FileSystemDatastore, ref CatchableError]
      ds: FileSystemDatastore

    dsRes = FileSystemDatastore.new(rootAbs)

    assert dsRes.isOk
    ds = dsRes.get

    check: dirExists(rootAbs)

    removeDir(rootAbs)
    assert not dirExists(rootAbs)

    dsRes = FileSystemDatastore.new(root)

    assert dsRes.isOk
    ds = dsRes.get

    check: dirExists(rootAbs)


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
