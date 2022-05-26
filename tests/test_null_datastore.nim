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
      nds = NullDatastore.new()

  test "contains":
    check:
      nds.contains(key).isOk
      nds.contains(key).get == false

  test "delete":
    check: nds.delete(key).isOk

  test "get":
    check:
      nds.get(key).isOk
      nds.get(key).get.isNone

  test "put":
    check: nds.put(key, oneByte).isOk

  # test "query":
  #   check:
  #     nds.query(key, ...).isOk
  #     nds.query(key, ...).get.isNone
