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
    createDir(root)
    success T(root: root)
  except OSError as e:
    failure "OSError: " & e.msg
