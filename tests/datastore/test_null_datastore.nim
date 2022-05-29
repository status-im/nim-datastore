import pkg/questionable
from pkg/stew/results as stewResults import get, isOk
import pkg/unittest2

import ../../datastore/null_datastore

const
  oneByte = @[1.byte]

suite "NullDatastore":
  setup:
    let
      key = Key.init("a").get
      ds = NullDatastore.new()

  test "new":
    check: not ds.isNil

  test "put":
    check: ds.put(key, oneByte).isOk

  test "delete":
    check: ds.delete(key).isOk

  test "contains":
    check:
      ds.contains(key).isOk
      ds.contains(key).get == false

  test "get":
    check:
      ds.get(key).isOk
      ds.get(key).get.isNone

  # test "query":
  #   check:
  #     ds.query(...).isOk
  #     ds.query(...).get.isNone
