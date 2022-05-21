import pkg/questionable
import pkg/upraises

import ./key

export key

push: {.upraises: [].}

type
  Datastore* = ref object of RootObj

method delete*(
  self: Datastore,
  key: Key): void {.base.} =

  raiseAssert("Not implemented!")

method get*(
  self: Datastore,
  key: Key): ?seq[byte] {.base.} =

  raiseAssert("Not implemented!")

method contains*(
  self: Datastore,
  key: Key): bool {.base.} =

  raiseAssert("Not implemented!")

method put*(
  self: Datastore,
  key: Key,
  data: openArray[byte]): void {.base.} =

  raiseAssert("Not implemented!")

method query*(
  self: Datastore,
  key: Key): seq[seq[byte]] {.base.} =

  raiseAssert("Not implemented!")
