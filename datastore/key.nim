import std/algorithm
import std/sequtils
import std/strutils

import pkg/questionable
import pkg/questionable/results
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

# TODO for Key: `[]`, iterator, randomKey

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

proc `type`*(self: Namespace): ?string =
  self.field

proc kind*(self: Namespace): ?string =
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
      # if `without ns =? Namespace.init(s), e:` is used `e` is nil in the body
      # at runtime, why?
      without ns =? nsRes:
        return failure "namespaces contains an invalid Namespace: " &
          nsRes.error.msg

      nss.add ns

    success T(namespaces: nss)

proc init*(T: type Key, id: string): ?!T =
  if id == "":
    return failure "id string must contain at least one Namespace"
  else:
    let
      nsStrs = id.split(separator).filterIt(it != "")

    if nsStrs.len == 0:
      return failure "id string must not contain only one or more separator \"" & separator & "\""

    let
      keyRes = Key.init(nsStrs)
    # if `without key =? Key.init(nsStrs), e:` is used `e` is nil in the body
    # at runtime, why?
    without key =? keyRes:
      return failure "id string contains an invalid Namespace:" &
        keyRes.error.msg.split(":")[1..^1].join("")

    success key

proc namespaces*(self: Key): seq[Namespace] =
  self.namespaces

proc list*(self: Key): seq[Namespace] =
  self.namespaces

proc last*(self: Key): Namespace =
  self.namespaces[^1]

proc len*(self: Key): int =
  self.namespaces.len

proc reversed*(self: Key): Key =
  Key(namespaces: self.namespaces.reversed)

proc reverse*(self: Key): Key =
  self.reversed

proc name*(self: Key): string =
  self.last.value

proc `type`*(self: Key): ?string =
  self.last.field

proc kind*(self: Key): ?string =
  self.`type`

proc instance*(self: Key, value: Namespace): Key =
  let
    last = self.last

    inst =
      if self.last.field.isSome:
        @[Namespace(field: last.field, value: value.value)]
      else:
        @[Namespace(field: last.value.some, value: value.value)]

    namespaces =
      if self.namespaces.len == 1:
        inst
      else:
        self.namespaces[0..^2] & inst

  Key(namespaces: namespaces)

proc instance*(self: Key, value: Key): Key =
  self.instance(value.last)

proc instance*(self: Key, id: string): ?!Key =
  without key =? Key.init(id), e:
    return failure e

  success self.instance(key)

proc isTopLevel*(self: Key): bool =
  self.len == 1

proc parent*(self: Key): ?!Key =
  if self.isTopLevel:
    failure "key has no parent"
  else:
    success Key(namespaces: self.namespaces[0..^2])

proc parent*(self: ?!Key): ?!Key =
  let
    key = ? self

  key.parent

proc path*(self: Key): ?!Key =
  let
    parent = ? self.parent

  without kind =? self.last.kind:
    return success parent

  success Key(namespaces: parent.namespaces & @[Namespace(value: kind)])

proc path*(self: ?!Key): ?!Key =
  let
    key = ? self

  key.path

proc child*(self: Key, ns: Namespace): Key =
  Key(namespaces: self.namespaces & @[ns])

proc child*(self: Key, nss: varargs[Namespace]): Key =
  Key(namespaces: self.namespaces & @nss)

proc child*(self: Key, key: Key): Key =
  Key(namespaces: self.namespaces & key.namespaces)

proc child*(self: Key, keys: varargs[Key]): Key =
  Key(namespaces: self.namespaces & concat(keys.mapIt(it.namespaces)))

proc child*(self: Key, ids: varargs[string]): ?!Key =
  if ids.len == 0:
    failure "ids must contain at least one Key id string"
  else:
    var
      keys: seq[Key]

    for id in ids:
      let
        key = ? Key.init(id)

      keys.add key

    success self.child(keys)

proc isAncestorOf*(self, other: Key): bool =
  if other.len <= self.len:
    false
  else:
    other.namespaces[0..<self.len] == self.namespaces

proc isDescendantOf*(self, other: Key): bool =
  other.isAncestorOf(self)

proc id*(self: Key): string =
  separator & self.namespaces.mapIt(it.id).join(separator)

proc `$`*(key: Key): string =
  "Key(" & key.id & ")"
