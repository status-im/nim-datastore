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

const
  objectExtension = ".obj"

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

proc root*(self: FileSystemDatastore): string =
  self.root

proc path*(self: FileSystemDatastore, key: Key): string =
  var
    segments: seq[string]

  for ns in key:
    without field =? ns.field:
      segments.add ns.value
      continue

    segments.add(field / ns.value)

  # is it problematic that per this logic Key(/a:b) evaluates to the same path
  # as Key(/a/b)? may need to check if/how other Datastore implementations
  # distinguish them

  self.root / joinPath(segments) & objectExtension

method contains*(
  self: FileSystemDatastore,
  key: Key): ?!bool =

  try:
    success fileExists(self.path(key))

  except CatchableError as e:
    failure e

method delete*(
  self: FileSystemDatastore,
  key: Key): ?!void =

  let
    path = self.path(key)

  try:
    removeFile(path)
    success()

    # removing an empty directory might lead to surprising behavior depending
    # on what the user specified as the `root` of the FileSystemDatastore, so
    # until further consideration, empty directories will be left in place

  except OSError as e:
    failure e

method get*(
  self: FileSystemDatastore,
  key: Key): ?!(?seq[byte]) =

  success seq[byte].none

method put*(
  self: FileSystemDatastore,
  key: Key,
  data: openArray[byte]): ?!void =

  let
    path = self.path(key)

  try:
    createDir(parentDir(path))
    if data.len > 0:
      writeFile(path, data)
    else:
      writeFile(path, "")
    success()

  except IOError as e:
    failure e

  except OSError as e:
    failure e

# method query*(
#   self: FileSystemDatastore,
#   query: ...): ?!(?seq[seq[byte]]) =
#
#   success seq[seq[byte]].none
