import std/options
import std/sequtils

import pkg/questionable
import pkg/questionable/results
from pkg/stew/results as stewResults import get, isErr, isOk
import pkg/unittest2

import ../datastore/key

suite "Datastore Namespace":
  test "init":
    var
      nsRes: Result[Namespace, ref CatchableError]

    nsRes = Namespace.init("a", "")

    check: nsRes.isErr

    nsRes = Namespace.init("a", ":")

    check: nsRes.isErr

    nsRes = Namespace.init("a", "/")

    check: nsRes.isErr

    nsRes = Namespace.init(":", "b")

    check: nsRes.isErr

    nsRes = Namespace.init("/", "b")

    check: nsRes.isErr

    nsRes = Namespace.init("", "b")

    check: nsRes.isOk

    nsRes = Namespace.init("a", "b")

    check: nsRes.isOk

    nsRes = Namespace.init("")

    check: nsRes.isErr

    nsRes = Namespace.init("/")

    check: nsRes.isErr

    nsRes = Namespace.init(":")

    check: nsRes.isErr

    nsRes = Namespace.init("a:b:c")

    check: nsRes.isErr

    nsRes = Namespace.init("a:")

    check: nsRes.isErr

    nsRes = Namespace.init("a")

    check: nsRes.isOk

    nsRes = Namespace.init(":b")

    check:
      nsRes.isOk

      Namespace.init("a").get == Namespace.init("a").get
      Namespace.init("a").get != Namespace.init("b").get
      Namespace.init("a:b").get == Namespace.init("a:b").get
      Namespace.init("a:b").get != Namespace.init("b:a").get

  test "accessors":
    var
      nsRes: Result[Namespace, ref CatchableError]
      ns: Namespace

    nsRes = Namespace.init("", "b")

    assert nsRes.isOk
    ns = nsRes.get

    check:
      ns.value == "b"
      ns.field.isNone

    nsRes = Namespace.init("a", "b")

    assert nsRes.isOk
    ns = nsRes.get

    check:
      ns.value == "b"
      ns.field.isSome
      ns.field.get == "a"
      ns.`type`.get == ns.field.get
      ns.kind.get == ns.field.get

    nsRes = Namespace.init(":b")

    assert nsRes.isOk
    ns = nsRes.get

    check:
      ns.value == "b"
      ns.field.isNone

    nsRes = Namespace.init("a:b")

    assert nsRes.isOk
    ns = nsRes.get

    check:
      ns.value == "b"
      ns.field.isSome
      ns.field.get == "a"
      ns.`type`.get == ns.field.get
      ns.kind.get == ns.field.get

  test "serialization":
    var
      nsRes: Result[Namespace, ref CatchableError]
      ns: Namespace

    nsRes = Namespace.init("", "b")

    assert nsRes.isOk
    ns = nsRes.get

    check: ns.id == "b"

    nsRes = Namespace.init("a", "b")

    assert nsRes.isOk
    ns = nsRes.get

    check: ns.id == "a:b"

    nsRes = Namespace.init(":b")

    assert nsRes.isOk
    ns = nsRes.get

    check: ns.id == "b"

    nsRes = Namespace.init("a:b")

    assert nsRes.isOk
    ns = nsRes.get

    check:
      ns.id == "a:b"

      $ns == "Namespace(" & ns.id & ")"

suite "Datastore Key":
  test "init":
    var
      keyRes: Result[Key, ref CatchableError]

    var
      nss: seq[Namespace]

    keyRes = Key.init(nss)

    check: keyRes.isErr

    nss = @[Namespace.init("a").get]

    keyRes = Key.init(nss)

    check: keyRes.isOk

    var
      nsStrs: seq[string]

    keyRes = Key.init(nsStrs)

    check: keyRes.isErr

    nsStrs = @[":"]

    keyRes = Key.init(nsStrs)

    check: keyRes.isErr

    nsStrs = @["/"]

    keyRes = Key.init(nsStrs)

    check: keyRes.isErr

    nsStrs = @["a:b"]

    keyRes = Key.init(nsStrs)

    check: keyRes.isOk

    keyRes = Key.init("")

    check: keyRes.isErr

    keyRes = Key.init(":")

    check: keyRes.isErr

    keyRes = Key.init("::")

    check: keyRes.isErr

    keyRes = Key.init("/")

    check: keyRes.isErr

    keyRes = Key.init("///")

    check: keyRes.isErr

    keyRes = Key.init("a:b")

    check: keyRes.isOk

    keyRes = Key.init("a:b/c")

    check: keyRes.isOk

    keyRes = Key.init("/a:b/c/")

    check: keyRes.isOk

    keyRes = Key.init("///a:b///c///")

    check:
      keyRes.isOk

      Key.init("a:b/c").get == Key.init("a:b/c").get
      Key.init("a:b/c").get != Key.init("c:b/a").get
      Key.init("a:b/c").get == Key.init("/a:b/c/").get
      Key.init("a:b/c").get == Key.init("///a:b///c///").get
      Key.init("a:b/c").get != Key.init("///a:b///d///").get

  test "accessors and helpers":
    var
      keyRes: Result[Key, ref CatchableError]
      key: Key

    keyRes = Key.init("/a:b/c/d:e")

    assert keyRes.isOk
    key = keyRes.get

    check:
      key.namespaces == @[
        Namespace.init("a:b").get,
        Namespace.init("c").get,
        Namespace.init("d:e").get
      ]

      key.list == key.namespaces

      key[1] == Namespace.init("c").get
      key[1..^1] == @[Namespace.init("c").get, Namespace.init("d:e").get]
      key[^1] == Namespace.init("d:e").get

      key.last == Namespace.init("d:e").get
      key.last == key.namespaces[^1]

      key.len == 3
      key.len == key.namespaces.len

    var
      nss: seq[Namespace]

    for ns in key:
      nss.add ns

    check:
      nss == @[
        Namespace.init("a:b").get,
        Namespace.init("c").get,
        Namespace.init("d:e").get
      ]

    check:
      key.reversed.namespaces == @[
        Namespace.init("d:e").get,
        Namespace.init("c").get,
        Namespace.init("a:b").get
      ]

      key.reverse == key.reversed

      key.name == "e"

      key.`type` == "d".some
      key.kind == key.`type`

      key.instance(Namespace.init("f:g").get) == Key.init("a:b/c/d:g").get

      Key.init("a:b").get.instance(Namespace.init(":c").get) ==
        Key.init("a:c").get

      Key.init(":b").get.instance(Namespace.init(":c").get) ==
        Key.init("b:c").get

      Key.init(":b").get.instance(key) == Key.init("b:e").get

      Key.init(":b").get.instance("").isErr

      Key.init(":b").get.instance(":").isErr

      Key.init(":b").get.instance("/").isErr

      Key.init(":b").get.instance("//").isErr

      Key.init(":b").get.instance("///").isErr

      Key.init(":b").get.instance("a").get == Key.init("b:a").get

      Key.init(":b").get.instance(":b").get == Key.init("b:b").get

      Key.init(":b").get.instance("a:b").get == Key.init("b:b").get

      Key.init(":b").get.instance("/a:b/c/d:e").get == Key.init("b:e").get

      Key.init(":b").get.isTopLevel

      not Key.init(":b/c").get.isTopLevel

      Key.init(":b").get.parent.isErr

      Key.init(":b").parent.isErr

      key.parent.get == Key.init("a:b/c").get

      key.parent.parent.get == Key.init("a:b").get

      key.parent.parent.parent.isErr

      key.parent.get.path.get == Key.init("a:b").get

      key.path.get == Key.init("a:b/c/d").get

      Key.init("a:b/c").path.get == Key.init("a:b").get

      Key.init("a:b/c/d:e").path.get == Key.init("a:b/c/d").get

      key.child(Namespace.init("f:g").get) ==
        Key.init("a:b/c/d:e/f:g").get

      key / Namespace.init("f:g").get == Key.init("a:b/c/d:e/f:g").get

      key.child(Namespace.init("f:g").get, Namespace.init("h:i").get) ==
        Key.init("a:b/c/d:e/f:g/h:i").get

      key.child(@[Namespace.init("f:g").get]
        .filterIt(it != Namespace.init("f:g").get)) == key

      key.child(Key.init("f:g").get) == Key.init("a:b/c/d:e/f:g").get

      key / Key.init("f:g").get == Key.init("a:b/c/d:e/f:g").get

      key.child(Key.init("f:g").get, Key.init("h:i").get) ==
        Key.init("a:b/c/d:e/f:g/h:i").get

      key.child(@[Key.init("f:g").get]
        .filterIt(it != Key.init("f:g").get)) == key

      key.child("f:g", ":::").isErr

      key.child("f:g", "h:i").get == Key.init("a:b/c/d:e/f:g/h:i").get

      key.child("").get == key

      key.child("", "", "").get == key

      (key / "f:g").get == Key.init("a:b/c/d:e/f:g").get

      (key / "").get == key

      not key.isAncestorOf(Key.init("f:g").get)

      key.isAncestorOf(key.child(Key.init("f:g").get))

      key.isDescendantOf(key.parent.get)

      not Key.init("f:g").get.isDescendantOf(key.parent.get)

  test "serialization":
    var
      keyRes: Result[Key, ref CatchableError]
      key: Key

    let
      idStr = "/a:b/c/d:e"

    keyRes = Key.init(idStr)

    assert keyRes.isOk
    key = keyRes.get

    check:
      key.id == idStr

      $key == "Key(" & key.id & ")"
