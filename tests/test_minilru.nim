import minilru, unittest2

type
  A = object
    v: int

  B = object
    v: int

func hash(v: A): Hash =
  Hash(v.v)
func hash(v: B): Hash =
  Hash(v.v)
func `==`(a: A, b: B): bool =
  a.v == b.v

suite "minilru":
  test "small":
    var lru: LruCache[int, int]

    lru.put(0, 0)
    check:
      0 notin lru

    lru.put(1, 1)
    check:
      1 notin lru

    lru.capacity = 1

    lru.put(1, 1)
    check:
      1 in lru
      0 notin lru

    lru.del(1)
    check:
      1 notin lru
      0 notin lru

    lru.put(2, 2)
    check:
      2 in lru
      1 notin lru
      0 notin lru

    lru.put(3, 3)
    check:
      3 in lru
      2 notin lru
      0 notin lru

    lru.capacity = 2
    lru.put(4, 4)
    check:
      4 in lru
      3 in lru
      2 notin lru
      0 notin lru

    debugEcho lru
    lru.del(3)
    debugEcho lru
    lru.del(4)

    check:
      4 notin lru
      3 notin lru
      2 notin lru
      0 notin lru

  test "simple ops":
    var lru = LruCache[int, int].init(10)

    for i in 0 ..< 10:
      lru.put(i, i)

      check:
        i in lru

    check:
      not lru.update(100, 100)

    lru.del(5)

    check:
      5 notin lru

    lru.put(11, 11) # should take the spot of 5

    check:
      0 in lru
      11 in lru

      lru.update(1, 100)

      1 in lru
      lru.get(1) == Opt.some(100)

    lru.put(12, 12)

    check:
      0 notin lru # 0 was added first, 11 took 5's place
      1 in lru

    lru.put(13, 13)

    check:
      2 notin lru # 1 should have been shifted to front
      1 in lru

    check:
      lru.peek(3) == Opt.some(3)

    lru.put(14, 14)
    check:
      3 notin lru # peek should not reorder

  test "growth":
    var lru: LruCache[int, int]

    for i in 0 ..< 100000:
      lru.capacity = i + 1
      lru.put(i, i)
      check i in lru

    for i in 0 ..< 100000:
      lru.del(i)

    for i in 0 ..< 100001:
      # No growth
      lru.put(i, i)
      check i in lru

    check:
      0 notin lru

  test "heterogenous lookup":
    var lru = LruCache[A, int].init(10)

    lru.put(A(v: 10), 10)

    check:
      B(v: 10) in lru

  test "readme example":
    var lru = LruCache[int, int].init(2)

    lru.put(10, 10)
    lru.put(20, 20)

    assert lru.get(10) == Opt.some(10)

    lru.put(30, 30)

    # 10 was more recent
    assert lru.get(20).isNone()

    # Allow capacity to grow to 3 items if needed
    lru.capacity = 3

    lru.put(40, 40) # Evicts 20

    assert lru.get(20).isNone()
