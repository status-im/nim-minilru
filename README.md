# minilru

Efficient implementation of classic LRU cache with a tightly packed
doubly-linked list and robin-hood style hash table.

## Usage

In `.nimble`:

```nim
requires "minilru"
```

In code:

```nim
# Create cache that holds up to 2 items
var lru = LruCache[int, int].init(2)

lru.put(10, 10)
lru.put(20, 20)

assert lru.get(10) == Opt.some(10)

lru.put(30, 30)

# 10 was more recent
assert lru.get(20).isNone()

# Allow capacity to grow to 3 items if needed
lru.capacity = 3

# Accessed to evicted 20
for (evicted, key, value) in lru.putWithEvicted(40, 40):
  assert evicted and key == 20

assert lru.get(20).isNone()
```

## Features

* Low overhead (~18-20 bytes) and no separate allocation per entry
* Single copy of key and value
* Heterogenous lookup
  * Different type can be used for lookup as long as `==` and `hash` is implemented and equal
* No exceptions

## Implementation notes

The list links, keys and values are stored in a contiguous `seq` with
links being `uint32` indices - as a consequence, capacity is capped at
2**32 entries even on 64-bit platforms.

The table similarly maps hashes to indices resulting in a tight packing
for the buckets and low memory overhead. Robin-hood open addressing is
used for resolving collisions.

Overhead at roughly 18-20 bytes per item in addition to storage for key
and value - `8` for the linked list and `(8/0.8 + rounding)` for hash
buckets.

Items are moved to the front on access and add and evicted from the back
when full.

The table supports heterogenous lookups, ie using a different key type
than is assigned to the table. When doing so, the types must be
comparable for both equality (`==`) and hash (`hash`).

Robin-hood hashing:
* https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf
* https://codecapsule.com/2013/11/11/robin-hood-hashing/
* https://programming.guide/robin-hood-hashing.html

The layout of the LRU node list was inspired by:
* https://github.com/phuslu/lru
* https://github.com/goossaert/hashmap

## Other LRU implementations

* [lrucache.nim](https://github.com/jackhftang/lrucache.nim)
* [nim-cache](https://github.com/PMunch/nim-cache)
* [stew/keyed_queue](https://github.com/status-im/nim-stew/blob/master/stew/keyed_queue.nim)
