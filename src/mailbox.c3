// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 A queue between threads that answers the hard questions.

 Many senders, many receivers. It does its own locking.
 It moves an `Inner*` and never learns your type.
 Nothing is allocated when an outer is sent, and nothing is freed when one arrives.

 ## Making one

 - `create` takes your allocator and keeps it for life.
 - `release` gives the memory back.
 - `release` runs after `close`, and after every call on the mailbox has returned.
 - A mailbox is made by this call, not by a helper.
 - `TYPE`, `to_inner` and `of` let a mailbox travel inside another mailbox or pool.

 ## Sending

 - `send` takes a full slot and empties it.
 - `send` takes an optional `limit`, and `0` is unbounded.
 - A `limit` counts only outers of the sender's own `typeid` already queued.
 - `send_oob` puts the outer at the front, for work that must not wait behind the rest.
 - `send_oob` takes no `limit`.

 ## Receiving

 - `poll` takes what is there and does not wait.
 - `receive` waits up to a timeout.
 - `receive_all` moves everything queued onto a queue of yours, in receive order.
 - `wake_all` returns every waiter at once.
 - Out-of-band outers come out first.

 ## What a call can end with

 The set is fixed per call, and there is nothing else.

 - `send` — `CLOSED`, `LIMIT`.
 - `send_oob` — `CLOSED`.
 - `poll` — `CLOSED`, `EMPTY`.
 - `receive` — `CLOSED`, `TIMEOUT`, `WOKEN`.
 - `receive_all` — `CLOSED`.
 - `wake_all` — `CLOSED`.
 - `close` cannot fail.

 ## Where the outer is afterwards

 - A `send` that worked leaves your slot empty.
 - A `send` refused with `CLOSED` or `LIMIT` leaves the outer in your slot.
 - So the slot answers it, and you do not have to remember which failure took it.
 - `poll` and `receive` fill an empty slot. Passing a full one is refused.

 ## Shutting down

 - `close` moves everything still queued onto a queue you pass in, and loses nothing.
 - You release those outers by your own rules, or give them back to a pool.
 - `close` on an already closed mailbox gives back nothing, and is not an error.
 - Every waiter in `receive` comes back with `CLOSED`.
 - `is_closed` is the state. `is_idle` says closed with no call still running.
 - `len` is how many outers are queued now.
*>
module mtk::mailbox;

<*
 Opaque handle to a mailbox instance.
*>
typedef Mailbox = void;

<*
 Identity description for using `Mailbox` as an outer inside another container.
*>
const typeid TYPE = _Mbox::typeid;

alias MBOX @private = helper::OF{_Mbox};

<*
 Retrieves the embedded `Inner*` for passing a mailbox through another mailbox or pool.
*>
macro Inner* to_inner(Mailbox* p) => MBOX.inner((_Mbox*)p);

<*
 Converts an `Inner*` back into a `Mailbox*`. Returns `null` if type mismatch occurs.
*>
macro Mailbox* of(Inner* inner) => (Mailbox*)MBOX.look(inner);

<*
 Allocates and initializes a new Mailbox.

 @param a : "the allocator the mailbox keeps for life"
*>
fn Mailbox*? create(Allocator a)
{
    _Mbox* mb = alloc::new_try(a, _Mbox)!;
    defer catch alloc::free(a, mb);

    MBOX.stamp(mb);
    mb._alloc = a;

    mb._mu.init()!;
    defer catch mb._mu.destroy();

    mb._cv.init()!;

    return (Mailbox*)mb;
}

<*
 Destroys a closed mailbox and frees its memory.
 Must only be called after `close()` has been called and all active threads have exited mailbox methods.

 @param mbox : "the mailbox to release"
*>
fn void Mailbox.release(&mbox)
{
    _Mbox* self = (_Mbox*)mbox;

    self._mu.lock();
    always_assert(self._closed && self._active == 0,
                  "releasing a mailbox with a call still running on it");
    self._mu.unlock();

    self._cv.destroy()!!;
    self._mu.destroy();
    Allocator a = self._alloc;
    alloc::free(a, self);
}

<*
 Enqueues an outer item.

 @param slot : "a full Slot; cleared on success, untouched on CLOSED or LIMIT"
 @param limit : "0 (default) for unbounded; otherwise the max already-queued outers of the same typeid"
 @return? mtk::CLOSED, mtk::LIMIT
*>
fn void? Mailbox.send(&mbox, Slot* slot, usz limit = 0) => ((_Mbox*)mbox).send_at(slot, false, limit);

<*
 Enqueues an outer item at the head of the queue (out-of-band delivery).

 @param slot : "a full Slot; cleared on success, untouched on CLOSED"
 @return? mtk::CLOSED
*>
fn void? Mailbox.send_oob(&mbox, Slot* slot) => ((_Mbox*)mbox).send_at(slot, true, 0);

<*
 Attempts to dequeue an item immediately without waiting.

 @param slot : "an empty Slot; filled on success"
 @return? mtk::CLOSED, mtk::EMPTY
*>
fn void? Mailbox.poll(&mbox, Slot* slot)
{
    _Mbox* self = (_Mbox*)mbox;

    mtk::@check(slot.is_empty(), "an acquisition asserts the Slot is empty on entry");

    if (self.@closed_fast()) return mtk::CLOSED~;

    self._mu.lock();
    defer self._mu.unlock();

    if (self._closed) return mtk::CLOSED~;

    self._active++;
    defer self._active--;

    Inner* inner = self.dequeue();
    if (!inner) return mtk::EMPTY~;
    slot.fill(inner);
}

<*
 Dequeues an item, blocking up to `timeout` if the mailbox is empty.

 @param slot : "an empty Slot; filled on success"
 @param timeout : "how long to wait"
 @return? mtk::CLOSED, mtk::TIMEOUT, mtk::WOKEN
*>
fn void? Mailbox.receive(&mbox, Slot* slot, Duration timeout)
{
    _Mbox* self = (_Mbox*)mbox;

    mtk::@check(slot.is_empty(), "an acquisition asserts the Slot is empty on entry");

    Time deadline = time::now() + timeout;

    self._mu.lock();
    defer self._mu.unlock();

    if (self._closed) return mtk::CLOSED~;

    self._active++;
    defer self._active--;

    usz gen = self._wake_gen;

    while (true)
    {
        if (self._closed) return mtk::CLOSED~;

        Inner* inner = self.dequeue();
        if (inner) { slot.fill(inner); return; }

        if (self._wake_gen != gen) return mtk::WOKEN~;

        if (catch f = self._cv.wait_until(&self._mu, deadline))
        {
            if (f != thread::WAIT_TIMEOUT) return f~;

            if (self._closed) return mtk::CLOSED~;
            inner = self.dequeue();
            if (inner) { slot.fill(inner); return; }
            if (self._wake_gen != gen) return mtk::WOKEN~;

            return mtk::TIMEOUT~;
        }
    }
}

<*
 Dequeues all pending items without closing the mailbox.

 @param out : "an empty queue; every queued outer is moved onto it, in receive order"
 @return? mtk::CLOSED
*>
fn void? Mailbox.receive_all(&mbox, InnerQueue* out)
{
    _Mbox* self = (_Mbox*)mbox;

    mtk::@check(out.is_empty(), "receive_all asserts the queue is empty on entry");

    if (self.@closed_fast()) return mtk::CLOSED~;

    self._mu.lock();
    defer self._mu.unlock();

    if (self._closed) return mtk::CLOSED~;

    self._active++;
    defer self._active--;

    out.append_queue(&self._oob);
    out.append_queue(&self._regular);
}

<*
 Interrupts all current receivers waiting on `receive`, causing them to return `mtk::WOKEN`.

 @return? mtk::CLOSED
*>
fn void? Mailbox.wake_all(&mbox)
{
    _Mbox* self = (_Mbox*)mbox;

    if (self.@closed_fast()) return mtk::CLOSED~;

    self._mu.lock();
    defer self._mu.unlock();

    if (self._closed) return mtk::CLOSED~;

    self._active++;
    defer self._active--;

    self._wake_gen++;
    self._cv.broadcast();
}

<*
 Closes the mailbox and moves remaining items into `out`.

 @param out : "an empty queue; the remainder is moved onto it, in receive order"
*>
fn void Mailbox.close(&mbox, InnerQueue* out)
{
    _Mbox* self = (_Mbox*)mbox;

    mtk::@check(out.is_empty(), "close asserts the queue is empty on entry");

    self._mu.lock();
    defer self._mu.unlock();

    self._active++;
    defer self._active--;

    self._close(out);
}

<*
 Returns `true` if the mailbox is closed.
*>
fn bool Mailbox.is_closed(&mbox) => ((_Mbox*)mbox).@closed_fast();

<*
 Returns `true` if closed and no operations are in flight.
*>
fn bool Mailbox.is_idle(&mbox)
{
    _Mbox* self = (_Mbox*)mbox;
    self._mu.lock();
    defer self._mu.unlock();
    return self._closed && self._active == 0;
}

<*
 Returns the total count of queued outers (out-of-band and regular).
*>
fn usz Mailbox.len(&mbox)
{
    _Mbox* self = (_Mbox*)mbox;
    self._mu.lock();
    defer self._mu.unlock();
    self._active++;
    defer self._active--;
    return self._oob.len() + self._regular.len();
}

import mtk;
import std::thread;
import std::time;
import std::core::mem::alloc;
import std::atomic::types;


//==============================================================================
// Internal Implementation Details
//==============================================================================
<*
 The real mailbox (`_Mbox`) behind the opaque `Mailbox` handle. Not part of
 the public API.
*>
module mtk::mailbox::internal;


macro bool _Mbox.@closed_fast(&self) => self._closed_fast.load(ACQUIRE);


fn void _Mbox.enqueue(&self, Inner* inner, bool oob) @inline
{
    if (oob) { self._oob.push_back(inner); } else { self._regular.push_back(inner); }
}

fn Inner* _Mbox.dequeue(&self) @inline
{
    Inner* inner = self._oob.pop_front();
    return inner ? inner : self._regular.pop_front();
}


fn bool _Mbox.has_queued(&self) @inline
    => !self._oob.is_empty() || !self._regular.is_empty();


fn void _Mbox._close(&self, InnerQueue* out)
{
    if (self._closed) return;

    self._closed = true;
    self._closed_fast.store(true, RELEASE);

    out.append_queue(&self._oob);
    out.append_queue(&self._regular);

    self._cv.broadcast();
}


fn void? _Mbox.send_at(&self, Slot* slot, bool oob, usz limit)
{
    mtk::@check(slot.is_full(), "Mailbox.send from an empty Slot");
    if (slot.is_empty()) return;

    if (self.@closed_fast()) return mtk::CLOSED~;

    self._mu.lock();
    defer self._mu.unlock();

    if (self._closed) return mtk::CLOSED~;

    self._active++;
    defer self._active--;

    if ((!oob) && (limit > 0))
    {
        typeid tid = slot.peek().outer_tid();
        InnerQueue* target = &self._regular;
        if(target.len() >= limit)
        {
            usz count = 0;
            InnerQueueIterator it = target.iter();
            while (Inner* inner = it.next())
            {
                if (inner.outer_tid() == tid) count++;

                if (count >= limit) return mtk::LIMIT~;
            }
        }
    }

    self.enqueue(slot.take(), oob);
    self._cv.signal();
}

struct _Mbox
{
    Inner inner;

    Mutex             _mu;
    ConditionVariable _cv;

    Allocator         _alloc;

    bool         _closed;
    Atomic{bool} _closed_fast;
    usz          _active;

    InnerQueue _oob;
    InnerQueue _regular;

    usz _wake_gen;
}


import mtk;
import std::thread;
import std::time;
import std::core::mem::alloc;
import std::atomic::types;