import pkg/questionable
import pkg/questionable/results
import pkg/upraises

import ./datastore

export datastore

push: {.upraises: [].}

type
  NullDatastore* = ref object of Datastore

proc new*(T: type NullDatastore): T =
  T()

method contains*(
  self: NullDatastore,
  key: Key): ?!bool =

  success false

method delete*(
  self: NullDatastore,
  key: Key): ?!void =

  success()

method get*(
  self: NullDatastore,
  key: Key): ?!(?seq[byte]) =

  success seq[byte].none

method put*(
  self: NullDatastore,
  key: Key,
  data: openArray[byte]): ?!void =

  success()

# method query*(
#   self: NullDatastore,
#   query: ...): ?!(?seq[seq[byte]]) =
#
#   success seq[seq[byte]].none
