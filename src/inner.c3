// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 The inner, the Slot, the link and the crossings.

 You send and receive your own struct.
 The struct is the outer, and it is yours.
 You give the infrastructure one thing, an `Inner` embedded in it.
 From then on the infrastructure never sees your type.
 It moves `Inner*`, intrusively and with the type erased.

 `Inner` is the field you embed.
 The chain link and the identity, in one.
 The identity sits in the same field as the chain link.
 The identity says what the outer type is.
 A pointer to an embedded `Inner` is one outer, with the type forgotten.
 It is spelled `Inner*`, because that is all it is, and 3tk transports nothing else.
 `Slot` is a box that holds one `Inner*`, or nothing.
 A Slot starts empty.

 The Slot is how the toolkit tells you where an outer went.
 Read the Slot after every call that gives or takes an outer.

 The chain link is the other half of `Inner`.
 `reset` clears the chain link and not the identity.
 Every chain ends at an inner pointing at itself, never at null.
 That is what makes `is_linked` exact.

 You get your struct back by crossing once, from `Inner*` to `Outer*`.
 The identity in the `Inner` is what makes that crossing safe.

 `to_inner` goes from your pointer to the `Inner*`.
 Null in, null out.
 `from_inner` goes from an `Inner*` back to `$Type*`, and is null on an identity mismatch.
 A mismatch is an answer, not a failure.
 `must_from_inner` is the same, and it aborts on a mismatch.
 The abort names your line.
 The same three take the outer from a Slot, and five of them appear again as methods.
 `from_slot` looks, and the Slot is unchanged.
 `move_from_slot` takes, and on success the Slot is left empty.
 None of these moves an outer.
 Reading an identity and casting a pointer leave every container alone.
 No alias to declare, no instantiation, no registration.

 It is a module of its own so that it is a page of its own.
 A user reaches it through `import mtk;` and writes `Inner` and `Slot` unqualified, as before.
*>
module mtk::inner;

<*
 `Inner` is the field you embed.
 The chain link and the identity, in one.

 A small part of this module is yours to call directly: the Slot's five operations, the identity, and the five crossings written as methods.
 Everything else goes through the helper, and says so with `For internal usage.` at the head of its doc block.
*>
struct Inner
{
    any link;
}

<*
 The identity of the outer this inner is embedded in.

 Null for an inner that was never stamped.
 It exists so that no user ever writes `inner.link.type`.
 The helper cannot do this one for you: a dispatch switch reads the identity before it knows the type.
*>
fn typeid Inner.outer_tid(&self) @inline => self.link.type;

<*
 From an `Inner*` back to `$Type*`.

 Null on an identity mismatch.
 A mismatch is an answer, not a failure.

 @param $Type : "the outer type expected"
*>
macro Inner.to(&self, $Type) => internal::from_inner((Inner*)self, $Type);

<*
 From an `Inner*` back to `$Type*`, and it aborts on a mismatch.

 Use it where a mismatch would be your own defect.
 The abort names your line.

 @param $Type : "the outer type asserted"
 @require internal::is_mine((Inner*)self, $Type) : "the inner is not of this type"
*>
macro Inner.as(&self, $Type) => ($Type*)((char*)self - internal::inner_offset($Type));

<*
 A box that holds one `Inner*`, or nothing.

 Zero or one outer.
 A Slot starts empty.
*>
typedef Slot = Inner*;

<*
 Which of the two states it is in.
*>
fn bool Slot.is_empty(&self) @inline => !(Inner*)*self;

<*
 Which of the two states it is in.
*>
fn bool Slot.is_full(&self) @inline => (Inner*)*self != null;

<*
 Look without taking.

 Null on an empty Slot.
*>
fn Inner* Slot.peek(&self) @inline => (Inner*)*self;

<*
 Take the `Inner*` out and clear the Slot.

 Null on an empty Slot.
*>
fn Inner* Slot.take(&self) @inline
{
    Inner* inner = (Inner*)*self;
    *self = (Slot)(Inner*)null;
    return inner;
}

<*
 Put an `Inner*` in.

 A null inner is a defect.
 Overwriting a full Slot is a defect.

 @param inner : "the inner to place; must not be null"
*>
fn void Slot.fill(&self, Inner* inner) @inline
{
    mtk::@check(inner != null, "Slot.fill with a null inner");
    // [3tk: Part 9.2 rule 1]
    mtk::@check(self.is_empty(), "never overwrite a full Slot");
    *self = (Slot)inner;
}


<*
 From the Slot back to `$Type*`. It looks, and the Slot is unchanged.

 Null on an identity mismatch.
 A mismatch is an answer, not a failure.

 @param $Type : "the outer type expected"
*>
macro Slot.to(&self, $Type) => internal::from_slot(self, $Type);

<*
 From the Slot back to `$Type*`, and it aborts on a mismatch. The Slot is unchanged.

 Use it where a mismatch would be your own defect.
 The abort names your line.

 @param $Type : "the outer type asserted"
*>
macro Slot.must(&self, $Type) => internal::must_from_slot(self, $Type);

<*
 From the Slot back to `$Type*`, and it takes.

 On success the Slot is left empty.
 On failure it is unchanged.

 @param $Type : "the outer type expected"
*>
macro Slot.move(&self, $Type) => internal::move_from_slot(self, $Type);


import mtk;


//==============================================================================
// For internal usage.
//==============================================================================
module mtk::inner::internal;


macro bool is_mine(Inner* inner, $Type) => inner != null && inner.link.type == $Type::typeid;

<*
 @require $defined($Typeof(*outer)::members) : "not a struct that embeds an Inner"
*>
macro void stamp(outer)
{
    Inner* inner = (Inner*)((char*)outer + inner_offset($Typeof(*outer)));
    inner.link = any_make(inner.link.ptr, $Typeof(*outer)::typeid);
}


macro check_stamped(Inner* inner, $msg)
{
    mtk::@check(inner == null || (void*)inner.outer_tid() != null, $msg);
}

<*
 @require $defined($Typeof(*outer)::members) : "not a struct that embeds an Inner"
*>
macro Inner* to_inner(outer)
    => outer ? (Inner*)((char*)outer + inner_offset($Typeof(*outer))) : null;


macro from_inner(Inner* inner, $Type)
{
    if (!is_mine(inner, $Type)) return ($Type*)null;
    return ($Type*)((char*)inner - inner_offset($Type));
}

<*
 @require is_mine(inner, $Type) : "the inner is not of this type"
*>
macro must_from_inner(Inner* inner, $Type) => ($Type*)((char*)inner - inner_offset($Type));


macro from_slot(Slot* s, $Type) => from_inner(s.peek(), $Type);


macro must_from_slot(Slot* s, $Type) => must_from_inner(s.peek(), $Type);


macro move_from_slot(Slot* s, $Type)
{
    Inner* inner = s.peek();
    if (!is_mine(inner, $Type)) return ($Type*)null;
    s.take();
    return ($Type*)((char*)inner - inner_offset($Type));
}


fn void Inner.repoint_to(&self, Inner* to) @inline
    => self.link = any_make(to, self.link.type);


fn Inner* Inner.points_to(&self) @inline => (Inner*)self.link.ptr;


fn bool is_linked(Inner* inner) @inline => inner != null && inner.points_to() != null;


fn void reset(Inner* inner) @inline
{
    if (!inner) return;
    inner.repoint_to(null);
}


macro usz inner_offset($Type)
{
    var $off = -1;
    var $seen = 0;
    $foreach $m : $Type::members:
        $if $m.type == Inner:
            $off = $m.offset;
            $seen = $seen + 1;
        $endif
    $endforeach
    $assert $seen != 0 : "type " +++ $Type::name +++ " has no Inner field; it cannot be a Matryoshka outer";
    // [3tk: Part 4.4]
    $assert $seen == 1 : "type " +++ $Type::name +++ " has more than one Inner field; exactly one is allowed";
    return $off;
}


import mtk;
