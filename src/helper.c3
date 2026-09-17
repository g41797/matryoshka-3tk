// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Per-type helper binding for user structures (outers).

 Typical usage: `alias MSG = helper::OF{Msg};`

 Handles type allocation, the `init` and `finish` hooks, type stamping,
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
 Returns `true` if the holder has an outer of type `Outer`.
 Returns `false` for an empty holder, and for any other type.
 An `any` whose `.type` is not `Outer` is not an outer of this type: an io event passes untouched.
 Aborts on an unstamped outer, and on an `any` whose `.type` and `otrtypeid` disagree.

 @param from : "a `Slot*`, an `Inner*` or an `any*`"
*>
macro bool OuterHelper.is(self, from)
{
    $switch:
        $case $Typeof(from) == Slot*:
            inner::internal::check_stamped(from.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::is_mine(from.peek(), Outer);
        $case $Typeof(from) == Inner*:
            inner::internal::check_stamped(from, "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::is_mine(from, Outer);
        $case $Typeof(from) == any*:
            return inner::internal::is_mine(inner::internal::from_any(from, Outer), Outer);
        $default:
            $error "is takes a Slot*, an Inner* or an any*";
    $endswitch
}

<*
 Retrieves an `Outer*` from a `Slot*`, `Inner*` or `any*` without modifying the holder.
 Returns `null` if the identity does not match `Outer`.

 @param from : "a `Slot*`, an `Inner*` or an `any*`"
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
        $case $Typeof(from) == any*:
            return inner::internal::from_inner(inner::internal::from_any(from, Outer), Outer);
        $default:
            $error "look takes a Slot*, an Inner* or an any*";
    $endswitch
}

<*
 Retrieves an `Outer*` from a `Slot*`, `Inner*` or `any*` without modifying the holder.
 Aborts if the type identity does not match `Outer`.

 @param from : "a `Slot*`, an `Inner*` or an `any*`"
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
        $case $Typeof(from) == any*:
            return inner::internal::must_from_inner(inner::internal::from_any(from, Outer), Outer);
        $default:
            $error "must_look takes a Slot*, an Inner* or an any*";
    $endswitch
}

<*
 Extracts the `Outer*` from a `Slot*` or `any*` and clears the holder on success.
 Returns `null` without clearing the holder if the type identity does not match.
 An outer taken from an `any` must not be linked.

 @param from : "a `Slot*` or an `any*`; empty afterwards on success"
*>
macro Outer* OuterHelper.take(self, from)
{
    $switch:
        $case $Typeof(from) == Slot*:
            inner::internal::check_stamped(from.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
            return inner::internal::move_from_slot(from, Outer);
        $case $Typeof(from) == any*:
            Inner* inner = inner::internal::from_any(from, Outer);
            Outer* outer = inner::internal::from_inner(inner, Outer);
            if (!outer) return null;
            mtk::@check(!inner::internal::is_linked(inner), "an outer crosses the border unlinked");
            inner::internal::clear_any(from);
            return outer;
        $default:
            $error "take takes a Slot* or an any*";
    $endswitch
}

<*
 Extracts the `Outer*` from a `Slot*` or `any*` and clears the holder.
 Aborts if the type identity does not match `Outer`.
 An outer taken from an `any` must not be linked.

 @param from : "a `Slot*` or an `any*`; empty afterwards"
*>
macro Outer* OuterHelper.must_take(self, from)
{
    $switch:
        $case $Typeof(from) == Slot*:
            inner::internal::check_stamped(from.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
            Outer* outer = inner::internal::must_from_slot(from, Outer);
            from.take();
            return outer;
        $case $Typeof(from) == any*:
            Inner* inner = inner::internal::from_any(from, Outer);
            Outer* outer = inner::internal::must_from_inner(inner, Outer);
            mtk::@check(!inner::internal::is_linked(inner), "an outer crosses the border unlinked");
            inner::internal::clear_any(from);
            return outer;
        $default:
            $error "must_take takes a Slot* or an any*";
    $endswitch
}

// --- The border: Slot and any ------------------------------------------------

<*
 Moves the outer from a `Slot` into an empty `any`, before a C3 container sends it.
 Returns `null` and leaves both untouched if the Slot is empty or holds another type.
 Aborts on an unstamped outer, a linked outer, or an `any` that is not empty.
 Both fields of the `any` are written.

 @param slot : "the Slot holding the outer; empty afterwards on success"
 @param a : "an `any` with `.ptr == null`; it holds the outer afterwards"
*>
macro Outer* OuterHelper.to_any(self, Slot* slot, any* a)
{
    inner::internal::check_stamped(slot.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
    Outer* outer = inner::internal::from_slot(slot, Outer);
    if (!outer) return null;
    mtk::@check(!inner::internal::is_linked(slot.peek()), "an outer crosses the border unlinked");
    mtk::@check(a.ptr == null, "never overwrite a full any");
    *a = outer;
    slot.take();
    return outer;
}

<*
 Moves the outer from a `Slot` into an empty `any`, before a C3 container sends it.
 Aborts if the Slot is empty or holds another type.
 Aborts on an unstamped outer, a linked outer, or an `any` that is not empty.

 @param slot : "the Slot holding the outer; empty afterwards"
 @param a : "an `any` with `.ptr == null`; it holds the outer afterwards"
*>
macro Outer* OuterHelper.must_to_any(self, Slot* slot, any* a)
{
    inner::internal::check_stamped(slot.peek(), "the outer was never stamped: make it with `create`, or call `stamp` once");
    Outer* outer = inner::internal::must_from_slot(slot, Outer);
    mtk::@check(!inner::internal::is_linked(slot.peek()), "an outer crosses the border unlinked");
    mtk::@check(a.ptr == null, "never overwrite a full any");
    *a = outer;
    slot.take();
    return outer;
}

<*
 Moves the outer from an `any` into an empty `Slot`, after it arrives from a C3 container.
 Returns `null` and leaves both untouched if the `any` is empty or holds another type.
 `.type` is checked first, then `otrtypeid` inside the outer.
 Aborts if they disagree, on an unstamped outer, a linked outer, or a full Slot.
 Both fields of the `any` are cleared.

 @param a : "the `any` holding the outer; empty afterwards on success"
 @param slot : "an empty Slot; it holds the outer afterwards"
*>
macro Outer* OuterHelper.to_slot(self, any* a, Slot* slot)
{
    Inner* inner = inner::internal::from_any(a, Outer);
    Outer* outer = inner::internal::from_inner(inner, Outer);
    if (!outer) return null;
    mtk::@check(!inner::internal::is_linked(inner), "an outer crosses the border unlinked");
    slot.fill(inner);
    inner::internal::clear_any(a);
    return outer;
}

<*
 Moves the outer from an `any` into an empty `Slot`, after it arrives from a C3 container.
 Aborts if the `any` is empty or holds another type.
 Aborts if `.type` and `otrtypeid` disagree, on an unstamped outer, a linked outer, or a full Slot.

 @param a : "the `any` holding the outer; empty afterwards"
 @param slot : "an empty Slot; it holds the outer afterwards"
*>
macro Outer* OuterHelper.must_to_slot(self, any* a, Slot* slot)
{
    Inner* inner = inner::internal::from_any(a, Outer);
    Outer* outer = inner::internal::must_from_inner(inner, Outer);
    mtk::@check(!inner::internal::is_linked(inner), "an outer crosses the border unlinked");
    slot.fill(inner);
    inner::internal::clear_any(a);
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