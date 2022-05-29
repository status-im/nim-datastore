import pkg/questionable
import pkg/questionable/results
import pkg/upraises

import ./key

export key

push: {.upraises: [].}

type
  Datastore* = ref object of RootObj

method contains*(
  self: Datastore,
  key: Key): ?!bool {.base.} =

  raiseAssert("Not implemented!")

method delete*(
  self: Datastore,
  key: Key): ?!void {.base.} =

  raiseAssert("Not implemented!")

method get*(
  self: Datastore,
  key: Key): ?!(?seq[byte]) {.base.} =

  raiseAssert("Not implemented!")

method put*(
  self: Datastore,
  key: Key,
  data: openArray[byte]): ?!void {.base.} =

  raiseAssert("Not implemented!")

# method query*(
#   self: Datastore,
#   query: ...): ?!(?...) {.base.} =
#
#   raiseAssert("Not implemented!")
