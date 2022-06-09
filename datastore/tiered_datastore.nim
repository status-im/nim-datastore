import pkg/questionable
import pkg/questionable/results
import pkg/upraises

import ./datastore

export datastore

push: {.upraises: [].}

type
  TieredDatastore* = ref object of Datastore
    stores: seq[Datastore]

proc new*(
  T: type TieredDatastore,
  stores: varargs[Datastore]): ?!T =

  if stores.len == 0:
    failure "stores must contain at least one Datastore"
  else:
    T(stores: stores)

proc stores*(self: TieredDatastore): seq[Datastore] =
  self.stores

method contains*(
  self: TieredDatastore,
  key: Key): ?!bool {.locks: "unknown".} =

  success false

method delete*(
  self: TieredDatastore,
  key: Key): ?!void {.locks: "unknown".} =

  success()

method get*(
  self: TieredDatastore,
  key: Key): ?!(?seq[byte]) {.locks: "unknown".} =

  success seq[byte].none

method put*(
  self: TieredDatastore,
  key: Key,
  data: openArray[byte]): ?!void {.locks: "unknown".} =

  success()

# method query*(
#   self: TieredDatastore,
#   query: ...): ?!(?...) {.locks: "unknown".} =
#
#   success ....none
