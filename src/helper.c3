// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Per-type helper binding for user structures (outers).

 Typical usage: `alias MSG = helper::OF{Msg};`

 Handles type allocation, lifecycle hooks (`init` and `finish`), type stamping,
 and identity checking when converting between typeless `Inner` pointers / `Slot` instances
 and the typed user structure.

 Every outer type handled by this helper must declare two methods:
 `fn void? Outer.init(&self, Allocator a)`
 `fn void Outer.finish(&self, Allocator a)`

 If a structure requires no setup or cleanup, implement them with empty bodies.
 These hooks are verified at compile time.
*>
module mtk::helper <Outer>;

<*
 Typedef representing the per-outer helper instance.
 Used as a receiver for helper methods (e.g. `MSG.create(allocator, &slot)`).
*>
typedef OuterHelper = uptr;

<*
 Compile-time constant used to alias helper instances.
 Example: `alias MSG = helper::OF{Msg};`
*>
const OuterHelper OF = {};

// --- Allocating and freeing --------------------------------------------------

<*
 Allocates an outer structure, invokes its `init` hook, stamps its `Inner` header,
 and assigns the resulting `Inner*` into the provided `Slot`.

 Frees allocation and propagates the fault if `init` fails.

 @param a : "the allocator; it is passed to your `init` hook and it is not stored"
 @param slot : "an empty Slot, filled on success"
*>
macro void? OuterHelper.create(self, Allocator a, Slot* slot)
{
    mtk::@check(slot.is_empty(), "an acquisition asserts the Slot is empty on entry");
    Outer* outer = alloc::new_try(a, Outer)!;
    $assert $defined(outer.init) : "every outer the helper creates declares `fn void? Outer.init(&self, Allocator a)` — an empty body is fine";
    $assert $defined(outer.finish) : "every outer the helper creates declares `fn void Outer.finish(&self, Allocator a)` — an empty body is fine";
    if (catch f = outer.init(a))
    {
        alloc::free(a, outer);
        return f~;
    }
    inner::internal::stamp(outer);
    slot.fill(inner::internal::to_inner(outer));
}

<*
 Invokes the outer's `finish` hook, clears the `Slot`, and frees the allocated outer memory.
 Safe to call on an empty `Slot` (no-op).

 @param a : "the allocator the outer was created with"
 @param slot : "the Slot holding the outer; empty afterwards"
*>
macro void OuterHelper.release(self, Allocator a, Slot* slot)
{
    if (slot.is_empty()) return;
    Outer* outer = inner::internal::must_from_slot(slot, Outer);
    $assert $defined(outer.init) : "every outer the helper creates declares `fn void? Outer.init(&self, Allocator a)` — an empty body is fine";
    $assert $defined(outer.finish) : "every outer the helper creates declares `fn void Outer.finish(&self, Allocator a)` — an empty body is fine";
    outer.finish(a);
    slot.take();
    alloc::free(a, outer);
}


// --- Type Crossings ----------------------------------------------------------

<*
 Retrieves an `Outer*` from a `Slot*` or `Inner*` without modifying the slot.
 Returns `null` if the identity does not match `Outer`.

 @param from : "a `Slot*` or an `Inner*`"
*>
macro Outer* OuterHelper.look(self, from)
{
    $switch:
        $case $Typeof(from) == Slot*:
            inner::internal::check_stamped(from.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::from_slot(from, Outer);
        $case $Typeof(from) == Inner*:
            inner::internal::check_stamped(from, "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::from_inner(from, Outer);
        $default:
            $error "look takes a Slot* or an Inner*";
    $endswitch
}

<*
 Retrieves an `Outer*` from a `Slot*` or `Inner*` without modifying the slot.
 Aborts if the type identity does not match `Outer`.

 @param from : "a `Slot*` or an `Inner*`"
*>
macro Outer* OuterHelper.must_look(self, from)
{
    $switch:
        $case $Typeof(from) == Slot*:
            inner::internal::check_stamped(from.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::must_from_slot(from, Outer);
        $case $Typeof(from) == Inner*:
            inner::internal::check_stamped(from, "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::must_from_inner(from, Outer);
        $default:
            $error "must_look takes a Slot* or an Inner*";
    $endswitch
}

<*
 Extracts the `Outer*` from a `Slot*` and clears the slot on success.
 Returns `null` without clearing the slot if the type identity does not match.

 @param slot : "the Slot holding the outer; empty afterwards on success"
*>
macro Outer* OuterHelper.take(self, Slot* slot)
{
    inner::internal::check_stamped(slot.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
    return inner::internal::move_from_slot(slot, Outer);
}

<*
 Extracts the `Outer*` from a `Slot*` and clears the slot.
 Aborts if the type identity does not match `Outer`.

 @param slot : "the Slot holding the outer; empty afterwards"
*>
macro Outer* OuterHelper.must_take(self, Slot* slot)
{
    inner::internal::check_stamped(slot.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
    Outer* outer = inner::internal::must_from_slot(slot, Outer);
    slot.take();
    return outer;
}

// --- Utilities ---------------------------------------------------------------

<*
 Converts an `Outer*` to its embedded `Inner*` header.
 Validates type identity in safe builds. Returns `null` if given `null`.

 @param outer : "a pointer to the outer"
*>
macro Inner* OuterHelper.inner(self, Outer* outer)
{
    mtk::@check(outer == null || inner::internal::is_mine(inner::internal::to_inner(outer), Outer),
        "the outer was never stamped, or carries another type: make it with `create`, or call `stamp` once");
    return inner::internal::to_inner(outer);
}

<*
 Writes type identity metadata into an outer structure's embedded `Inner` field.
 Required when manually allocating structures without using `create()`.

 @param outer : "a pointer to the outer"
*>
macro void OuterHelper.stamp(self, Outer* outer) => inner::internal::stamp(outer);

<*
 Returns `true` if the item is currently linked inside a container queue or stack.

 @param from : "an `Outer*` or an `Inner*`"
*>
macro bool OuterHelper.linked(self, from)
{
    $switch:
        $case $Typeof(from) == Outer*:
            return inner::internal::is_linked(inner::internal::to_inner(from));
        $case $Typeof(from) == Inner*:
            return inner::internal::is_linked(from);
        $default:
            $error "linked takes an Outer* or an Inner*";
    $endswitch
}

import mtk;
import std::core::mem::alloc;