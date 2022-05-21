import std/sequtils
import std/strutils

import pkg/questionable
import pkg/questionable/results
from pkg/stew/results as stewResults import get, isErr
import pkg/upraises

push: {.upraises: [].}

type
  Namespace* = object
    field: ?string
    value: string

  Key* = object
    namespaces: seq[Namespace]

const
  delimiter = ":"
  separator = "/"

proc init*(T: type Namespace, field, value: string): ?!T =
  if value == "": return failure "value string must not be empty"

  if value.contains(delimiter):
    return failure "value string must not contain delimiter \"" &
      delimiter & "\""

  if value.contains(separator):
    return failure "value string must not contain separator \"" &
      separator & "\""

  if field != "":
    if field.contains(delimiter):
      return failure "field string must not contain delimiter \"" &
        delimiter & "\""

    if field.contains(separator):
      return failure "field string must not contain separator \"" &
        separator & "\""

    success T(field: field.some, value: value)
  else:
    success T(field: string.none, value: value)

proc init*(T: type Namespace, id: string): ?!T =
  if id == "":
    return failure "id string must not be empty"

  if id.contains(separator):
    return failure "id string must not contain separator \"" & separator & "\""

  if id == delimiter:
    return failure "value in id string \"[field]" & delimiter &
      "[value]\" must not be empty"

  let
    s = id.split(delimiter)

  if s.len > 2:
    return failure "id string must not contain more than one delimiter \"" &
      delimiter & "\""

  var
    field: ?string
    value: string

  if s.len == 1:
    value = s[0]
  else:
    if s[1] == "":
      return failure "value in id string \"[field]" & delimiter &
        "[value]\" must not be empty"
    else:
      if s[0] != "": field = s[0].some
      value = s[1]

  success T(field: field, value: value)

proc value*(self: Namespace): string =
  self.value

proc field*(self: Namespace): ?string =
  self.field

proc id*(self: Namespace): string =
  if field =? self.field:
    field & delimiter & self.value
  else:
    self.value

proc `$`*(namespace: Namespace): string =
  "Namespace(" & namespace.id & ")"

proc init*(T: type Key, namespaces: varargs[Namespace]): ?!T =
  if namespaces.len == 0:
    failure "namespaces must contain at least one Namespace"
  else:
    success T(namespaces: @namespaces)

proc init*(T: type Key, namespaces: varargs[string]): ?!T =
  if namespaces.len == 0:
    failure "namespaces must contain at least one Namespace id string"
  else:
    var
      nss: seq[Namespace]

    for s in namespaces:
      let
        nsRes = Namespace.init(s)

      if nsRes.isErr:
        return failure "namespaces contains an invalid Namespace: " &
          nsRes.error.msg

      else:
        nss.add nsRes.get

    success T(namespaces: nss)

proc init*(T: type Key, id: string): ?!T =
  if id == "":
    return failure "id string must contain at least one Namespace"
  else:
    Key.init(id.split(separator).filterIt(it != ""))

proc namespaces*(self: Key): seq[Namespace] =
  self.namespaces

proc id*(self: Key): string =
  separator & self.namespaces.mapIt(it.id).join(separator)

proc `$`*(key: Key): string =
  "Key(" & key.id & ")"
