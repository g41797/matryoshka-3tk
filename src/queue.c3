// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Non-allocating intrusive FIFO queue and iterator for `Inner*` items.
*>
module mtk::queue;

<*
 Intrusive FIFO queue holding `Inner*` elements.
*>
struct InnerQueue
{
    Inner* head;
    Inner* tail;
    usz    count;
}

<*
 Iterator for traversing `InnerQueue`.
*>
struct InnerQueueIterator
{
    Inner* cur;
}

<*
 Returns `true` if the queue is empty.
*>
fn bool InnerQueue.is_empty(&self) @inline => self.count == 0;

<*
 Returns the number of items in the queue.
*>
fn usz InnerQueue.len(&self) @inline => self.count;

<*
 Initializes an iterator starting at the head of the queue.
*>
fn InnerQueueIterator InnerQueue.iter(&self) @inline => { .cur = self.head };

<*
 Returns the next `Inner*` in the iteration sequence, or `null` when exhausted.
*>
fn Inner* InnerQueueIterator.next(&self)
{
    Inner* n = self.cur;
    if (n) self.cur = (n.points_to() == n) ? null : n.points_to();
    return n;
}

<*
 Appends an `Inner*` to the end of the queue.

 @param inner : "the item to append"
*>
fn void InnerQueue.push_back(&self, Inner* inner)
{
    self.@guard_insert(inner);
    inner.repoint_to(inner);
    if (self.tail) { self.tail.repoint_to(inner); } else { self.head = inner; }
    self.tail = inner;
    self.count++;
}

<*
 Extracts an item from `s` and appends it to the back of the queue.

 @param s : "the Slot to take from"
*>
fn void InnerQueue.push_back_slot(&self, Slot* s)
{
    mtk::@check(s.is_full(), "push_back_slot from an empty Slot");
    if (s.is_empty()) return;
    self.push_back(s.take());
}

<*
 Removes and returns the head item from the queue, or `null` if empty.
*>
fn Inner* InnerQueue.pop_front(&self)
{
    Inner* inner = self.head;
    if (!inner) return null;
    if (self.head == self.tail)
    {
        self.head = null;
        self.tail = null;
    }
    else
    {
        self.head = inner.points_to();
    }
    self.count--;
    inner::internal::reset(inner);
    return inner;
}

<*
 Removes all elements from the queue and returns them in a new `InnerQueue`.
*>
fn InnerQueue InnerQueue.take(&self) @inline
{
    InnerQueue out = *self;
    self.head = null;
    self.tail = null;
    self.count = 0;
    return out;
}

<*
 Moves all elements from `other` onto the end of this queue.

 @param other : "the queue to empty onto this one; empty afterwards"
*>
fn void InnerQueue.append_queue(&self, InnerQueue* other)
{
    mtk::@check(other != null, "append_queue with a null queue");
    mtk::@check(other != self, "a queue cannot be moved onto itself");
    if (other == self) return;
    if (other.is_empty()) return;

    if (self.tail) { self.tail.repoint_to(other.head); } else { self.head = other.head; }
    self.tail = other.tail;
    self.count += other.count;

    other.head = null;
    other.tail = null;
    other.count = 0;
}


import mtk;


//==============================================================================
// Internal Implementation Details
//==============================================================================

<*
 The insert guard shared by the intrusive containers. Not part of the public API.
*>
module mtk::queue::internal;

macro InnerQueue.@guard_insert(&self, Inner* inner)
{
    mtk::@check(inner != null, "insert of a null inner");
    mtk::@check(!inner::internal::is_linked(inner), "the outer is already on a chain");
    inner::internal::check_stamped(inner, "the outer was never stamped: make it with `create`, or call `stamp` once");
}


import mtk;