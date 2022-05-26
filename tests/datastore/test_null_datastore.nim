import pkg/questionable
import pkg/questionable/results
from pkg/stew/results as stewResults import get, isOk
import pkg/unittest2

import ../datastore/null_datastore

const
  oneByte = @[1.byte]

suite "NullDatastore":
  setup:
    let
      key = Key.init("a").get
      ds = NullDatastore.new()

  test "contains":
    check:
      ds.contains(key).isOk
      ds.contains(key).get == false

  test "delete":
    check: ds.delete(key).isOk

  test "get":
    check:
      ds.get(key).isOk
      ds.get(key).get.isNone

  test "put":
    check: ds.put(key, oneByte).isOk

  # test "query":
  #   check:
  #     ds.query(key, ...).isOk
  #     ds.query(key, ...).get.isNone
