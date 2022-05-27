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

  test "accessors":
    let
      ds = FileSystemDatastore.new(root).get

    check: ds.root == rootAbs

  test "helpers":
      let
        ds = FileSystemDatastore.new(root).get

      check:
        # see comment in ../../datastore/filesystem_datastore re: whether path
        # equivalence of e.g. Key(/a:b) and Key(/a/b) is problematic
        ds.path(Key.init("a").get) == rootAbs / "a.obj"
        ds.path(Key.init("a:b").get) == rootAbs / "a" / "b.obj"
        ds.path(Key.init("a/b").get) == rootAbs / "a" / "b.obj"
        ds.path(Key.init("a:b/c").get) == rootAbs / "a" / "b" / "c.obj"
        ds.path(Key.init("a/b/c").get) == rootAbs / "a" / "b" / "c.obj"
        ds.path(Key.init("a:b/c:d").get) == rootAbs / "a" / "b" / "c" / "d.obj"
        ds.path(Key.init("a/b/c:d").get) == rootAbs / "a" / "b" / "c" / "d.obj"
        ds.path(Key.init("a/b/c/d").get) == rootAbs / "a" / "b" / "c" / "d.obj"

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
