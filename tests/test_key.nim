import std/options

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
