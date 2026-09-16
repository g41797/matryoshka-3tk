// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Thread-safe pool managing outer structures grouped by `typeid`.
 Delegates allocation and recycling rules to user-supplied `PoolHooks`.
*>
module mtk::pool;

<*
 Retrieval policies for `Pool.get`.
*>
enum GetMode
{
    <*
     Return a pooled instance if available, otherwise call `on_get` to allocate.
    *>
    AVAILABLE_OR_NEW,

    <*
     Bypass pooled instances and force `on_get` allocation.
    *>
    NEW_ONLY,

    <*
     Return a pooled instance or fail with `mtk::NOT_AVAILABLE`. Never invokes `on_get`.
    *>
    AVAILABLE_ONLY,
}

<*
 Opaque handle to a pool instance.
*>
typedef Pool = void;

<*
 Identity description for using `Pool` as an outer inside another container.
*>
const typeid TYPE = _Pool::typeid;

alias POOL @private = helper::OF{_Pool};

<*
 Retrieves the embedded `Inner*` for passing a pool through a mailbox.
*>
macro Inner* to_inner(Pool* p) => POOL.inner((_Pool*)p);

<*
 Converts an `Inner*` back into a `Pool*`. Returns `null` if type mismatch occurs.
*>
macro Pool* of(Inner* inner) => (Pool*)POOL.look(inner);

<*
 Allocates and initializes a new Pool instance for a fixed set of type identities.

 @param a : "the allocator the pool keeps for life"
 @param tags : "the identities this pool holds. Not empty, and no duplicates — both checked"
 @param hooks : "the policy"
*>
fn Pool*? create(Allocator a, typeid[] tags, PoolHooks hooks)
{
    mtk::@check(tags.len > 0, "the set of identities is not empty");
    mtk::@check(hooks != null, "a pool cannot exist without hooks");

    $if mtk::CHECKED:
        foreach (i, t : tags)
        {
            foreach (j, u : tags)
            {
                if (i < j) mtk::@check(t != u, "the pool's set of identities has a duplicate");
            }
        }
    $endif

    _Pool* p = alloc::new_try(a, _Pool)!;
    defer catch alloc::free(a, p);

    POOL.stamp(p);
    p._alloc = a;
    p._hooks = hooks;

    p._mu.init()!;
    defer catch p._mu.destroy();

    p._cv.init()!;
    defer catch p._cv.destroy()!!;

    p._buckets = alloc::new_array_try(a, PoolBucket, tags.len)!;
    foreach (i, t : tags)
    {
        p._buckets[i].tag = t;
        p._buckets[i].free = {};
    }
    return (Pool*)p;
}

<*
 Destroys a closed pool and frees its memory.

 @param pool : "the pool to release"
*>
fn void Pool.release(&pool)
{
    _Pool* self = (_Pool*)pool;

    self._mu.lock();
    always_assert(self._closed && self._active == 0,
                  "releasing a pool with a call still running on it");
    self._mu.unlock();

    self._cv.destroy()!!;
    self._mu.destroy();
    Allocator a = self._alloc;
    alloc::free(a, self._buckets);
    alloc::free(a, self);
}

<*
 Fetches an instance from the pool according to `mode`.

 @param want : "the identity wanted"
 @param mode : "which of the three modes"
 @param slot : "an empty Slot; filled on success"
 @return? mtk::CLOSED, mtk::NOT_AVAILABLE, mtk::NOT_CREATED, mtk::UNKNOWN_IDENTITY
*>
fn void? Pool.get(&pool, typeid want, GetMode mode, Slot* slot)
{
    _Pool* self = (_Pool*)pool;

    mtk::@check(slot.is_empty(), "an acquisition asserts the Slot is empty on entry");

    if (self.@closed_fast()) return mtk::CLOSED~;

    self._mu.lock();

    if (self._closed) { self._mu.unlock(); return mtk::CLOSED~; }

    self._active++;

    PoolBucket* b = self.bucket_for(want);
    mtk::@check(b != null, "Pool.get for an identity the pool was not created with");
    if (!b) { self._active--; self._mu.unlock(); return mtk::UNKNOWN_IDENTITY~; }

    if (mode != NEW_ONLY)
    {
        Inner* inner = b.free.pop();
        if (inner)
        {
            self._active--;
            self._mu.unlock();
            slot.fill(inner);
            return;
        }
    }

    if (mode == AVAILABLE_ONLY)
    {
        self._active--;
        self._mu.unlock();
        return mtk::NOT_AVAILABLE~;
    }

    usz in_pool = b.free.len();

    self._mu.unlock();
    self._hooks.on_get(want, in_pool, slot);

    self._mu.lock();
    self._active--;
    self._mu.unlock();

    if (slot.is_empty()) return mtk::NOT_CREATED~;

    mtk::@check(slot.peek().outer_tid() == want, "the get hook returned an outer of a different identity");
}

<*
 Fetches an instance, waiting up to `timeout` if none are available. Does not invoke `on_get`.

 @param want : "the identity wanted"
 @param slot : "an empty Slot; filled on success"
 @param timeout : "how long to wait"
 @return? mtk::CLOSED, mtk::TIMEOUT, mtk::UNKNOWN_IDENTITY
*>
fn void? Pool.get_wait(&pool, typeid want, Slot* slot, Duration timeout)
{
    _Pool* self = (_Pool*)pool;

    mtk::@check(slot.is_empty(), "an acquisition asserts the Slot is empty on entry");

    Time deadline = time::now() + timeout;

    self._mu.lock();
    defer self._mu.unlock();

    PoolBucket* b = self.bucket_for(want);
    mtk::@check(b != null, "Pool.get_wait for an identity the pool was not created with");
    if (!b) return mtk::UNKNOWN_IDENTITY~;

    if (self._closed) return mtk::CLOSED~;

    self._active++;
    defer self._active--;

    while (true)
    {
        if (self._closed) return mtk::CLOSED~;

        Inner* inner = b.free.pop();
        if (inner) { slot.fill(inner); return; }

        if (catch f = self._cv.wait_until(&self._mu, deadline))
        {
            if (f != thread::WAIT_TIMEOUT) return f~;

            if (self._closed) return mtk::CLOSED~;

            inner = b.free.pop();
            if (inner) { slot.fill(inner); return; }
            return mtk::TIMEOUT~;
        }
    }
}

<*
 Returns an outer structure to the pool and runs `on_put`.

 @param slot : "a full Slot; cleared if the pool took the outer"
*>
fn void Pool.put(&pool, Slot* slot)
{
    _Pool* self = (_Pool*)pool;

    if (slot.is_empty()) return;

    if (self.@closed_fast()) return;

    self._mu.lock();

    if (self._closed) { self._mu.unlock(); return; }

    self._active++;

    Inner* inner = slot.peek();
    PoolBucket* b = self.bucket_for(inner.outer_tid());
    mtk::@check(b != null, "Pool.put of an identity the pool was not created with");
    if (!b) { self._active--; self._mu.unlock(); return; }

    usz in_pool = b.free.len();

    Slot mine;
    mine.fill(slot.take());

    InnerQueue extra;

    self._mu.unlock();
    self._hooks.on_put(in_pool, &mine, &extra);
    self._mu.lock();

    if (self._closed)
    {
        InnerQueue stragglers;
        if (mine.is_full()) stragglers.push_back(mine.take());
        stragglers.append_queue(&extra);

        self._mu.unlock();
        if (!stragglers.is_empty()) self._hooks.on_close(stragglers.take());

        self._mu.lock();
        self._active--;
        self._mu.unlock();
        return;
    }

    self.take_back(&mine);

    while (Inner* e = extra.pop_front()) self.take_back_inner(e);

    self._cv.broadcast();
    self._active--;
    self._mu.unlock();
}

<*
 Closes the pool and flushes all pooled structures into `on_close`.
*>
fn void Pool.close(&pool)
{
    _Pool* self = (_Pool*)pool;

    self._mu.lock();

    if (self._closed) { self._mu.unlock(); return; }

    self._active++;

    InnerQueue remaining;
    self._close(&remaining);

    self._mu.unlock();

    self._hooks.on_close(remaining.take());

    self._mu.lock();
    self._active--;
    self._mu.unlock();
}

<*
 Returns `true` if the pool is closed.
*>
fn bool Pool.is_closed(&pool) => ((_Pool*)pool).@closed_fast();

<*
 Returns `true` if closed and no operations are in flight.
*>
fn bool Pool.is_idle(&pool)
{
    _Pool* self = (_Pool*)pool;
    self._mu.lock();
    defer self._mu.unlock();
    return self._closed && self._active == 0;
}

<*
 Returns the current count of free pooled instances for type `t`.
*>
fn usz Pool.count_of(&pool, typeid t)
{
    _Pool* self = (_Pool*)pool;
    self._mu.lock();
    defer self._mu.unlock();
    self._active++;
    defer self._active--;
    PoolBucket* b = self.bucket_for(t);
    return b ? b.free.len() : 0;
}


import mtk;
import std::thread;
import std::time;
import std::core::mem::alloc;
import std::atomic::types;

//==============================================================================
// Hooks
//==============================================================================

<*
 User-defined policy hooks invoked by `mtk::pool::Pool`.
 Handles outer allocation, recycling reset, and pool closure cleanup.
*>
module mtk::pool::hooks;

<*
 Policy interface for custom outer allocation, recycling, and teardown.
*>
interface PoolHooks
{
    <*
     Invoked when a caller requests an outer structure from the pool and none are free.

     @param want : "the identity asked for"
     @param in_pool : "how many of this identity remain, AFTER the removal. A hint, and stale"
     @param slot : "empty on entry; fill it or leave it"
    *>
    fn void on_get(typeid want, usz in_pool, Slot* slot);

    <*
     Invoked when an outer structure is returned to the pool via `put()`.

     @param in_pool : "how many of this identity are held, BEFORE the addition. A hint"
     @param slot : "full on entry"
     @param extra : "an empty queue; outers added here are taken the same way, with the same checks"
    *>
    fn void on_put(usz in_pool, Slot* slot, InnerQueue* extra);

    <*
     Invoked when the pool is closing to empty remaining pooled structures.

     @param remaining : "everything the pool still held, flattened across every identity, by value. No order is promised"
    *>
    fn void on_close(InnerQueue remaining);
}

import mtk;

//==============================================================================
// Internal Implementation Details
//==============================================================================
<*
 The real pool (`_Pool`), its buckets, and the intrusive free stack
 (`InnerStack`). Not part of the public API.
*>
module mtk::pool::internal;


struct PoolBucket
{
    typeid     tag;
    InnerStack free;
}

macro bool _Pool.@closed_fast(&self) => self._closed_fast.load(ACQUIRE);


fn PoolBucket* _Pool.bucket_for(&self, typeid t)
{
    foreach (&b : self._buckets) if (b.tag == t) return b;
    return null;
}


fn void _Pool._close(&self, InnerQueue* out)
{
    if (self._closed) return;

    self._closed = true;
    self._closed_fast.store(true, RELEASE);

    foreach (&b : self._buckets)
    {
        while (Inner* inner = b.free.pop()) out.push_back(inner);
    }

    self._cv.broadcast();
}


fn void _Pool.take_back(&self, Slot* s)
{
    if (s.is_empty()) return;
    self.take_back_inner(s.take());
}


fn void _Pool.take_back_inner(&self, Inner* inner)
{
    PoolBucket* b = self.bucket_for(inner.outer_tid());
    mtk::@check(b != null, "the put hook returned an identity the pool was not created with");
    b.free.push(inner);
}

struct _Pool
{
    Inner inner;

    Mutex             _mu;
    ConditionVariable _cv;

    Allocator         _alloc;

    bool         _closed;
    Atomic{bool} _closed_fast;
    usz          _active;

    PoolBucket[] _buckets;
    PoolHooks    _hooks;
}


struct InnerStack
{
    Inner* top;
    usz    count;
}

macro InnerStack.@guard_insert(&self, Inner* inner)
{
    mtk::@check(inner != null, "insert of a null inner");
    mtk::@check(!inner::internal::is_linked(inner), "the outer is already on a chain");
    inner::internal::check_stamped(inner, "the outer was never stamped: make it with `create`, or call `stamp` once");
}


fn bool InnerStack.is_empty(&self) @inline => self.count == 0;

fn usz InnerStack.len(&self) @inline => self.count;

fn void InnerStack.push(&self, Inner* inner)
{
    self.@guard_insert(inner);
    inner.repoint_to(self.top ? self.top : inner);
    self.top = inner;
    self.count++;
}

fn Inner* InnerStack.pop(&self)
{
    Inner* inner = self.top;
    if (!inner) return null;
    self.top = (inner.points_to() == inner) ? null : inner.points_to();
    self.count--;
    inner::internal::reset(inner);
    return inner;
}


import mtk;
import std::thread;
import std::time;
import std::core::mem::alloc;
import std::atomic::types;