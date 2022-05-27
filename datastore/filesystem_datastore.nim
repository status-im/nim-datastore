import std/os

import pkg/questionable
import pkg/questionable/results
import pkg/upraises

import ./datastore

export datastore

push: {.upraises: [].}

type
  FileSystemDatastore* = ref object of Datastore
    root: string

proc new*(T: type FileSystemDatastore, root = getCurrentDir() / "data"): ?!T =
  try:
    let
      root = if root.isAbsolute: root else: getCurrentDir() / root

    createDir(root)
    success T(root: root)

  except IOError as e:
    failure e

  except OSError as e:
    failure e

method contains*(
  self: FileSystemDatastore,
  key: Key): ?!bool =

  success false

method delete*(
  self: FileSystemDatastore,
  key: Key): ?!void =

  success()

method get*(
  self: FileSystemDatastore,
  key: Key): ?!(?seq[byte]) =

  success seq[byte].none

method put*(
  self: FileSystemDatastore,
  key: Key,
  data: openArray[byte]): ?!void =

  success()

# method query*(
#   self: FileSystemDatastore,
#   query: ...): ?!(?seq[seq[byte]]) =
#
#   success seq[seq[byte]].none
