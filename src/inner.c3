// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Core type erasure primitives: embedded header (`Inner`), target container (`Slot`),
 and address conversion utilities.

 Users embed `Inner` into domain structures (`outer`). System containers interact
 strictly with `Inner*` pointers, ignoring the layout or type of the outer structure.
*>
module mtk::inner;

<*
 Intrusive header embedded within user structures (`outer`).
 Holds intrusive links and type identity metadata (`typeid`).
*>
struct Inner
{
    any link;
}

<*
 Returns the `typeid` of the enclosing outer structure.
*>
fn typeid Inner.outer_tid(&self) @inline => self.link.type;

<*
 Converts `Inner*` to `$Type*`. Returns `null` if types do not match.

 @param $Type : "the outer type expected"
*>
macro Inner.to(&self, $Type) => internal::from_inner((Inner*)self, $Type);

<*
 Converts `Inner*` to `$Type*`. Aborts if types do not match.

 @param $Type : "the outer type asserted"
 @require internal::is_mine((Inner*)self, $Type) : "the inner is not of this type"
*>
macro Inner.as(&self, $Type) => ($Type*)((char*)self - internal::inner_offset($Type));

<*
 Single-element container holding an `Inner*` or `null`.
*>
typedef Slot = Inner*;

<*
 Returns `true` if the slot holds no `Inner*`.
*>
fn bool Slot.is_empty(&self) @inline => !(Inner*)*self;

<*
 Returns `true` if the slot holds an `Inner*`.
*>
fn bool Slot.is_full(&self) @inline => (Inner*)*self != null;

<*
 Inspects the `Inner*` in the slot without removing it.
*>
fn Inner* Slot.peek(&self) @inline => (Inner*)*self;

<*
 Extracts and returns the `Inner*` from the slot, setting the slot to `null`.
*>
fn Inner* Slot.take(&self) @inline
{
    Inner* inner = (Inner*)*self;
    *self = (Slot)(Inner*)null;
    return inner;
}

<*
 Places an `Inner*` into an empty slot. Asserts if the slot is already full.

 @param inner : "the inner to place; must not be null"
*>
fn void Slot.fill(&self, Inner* inner) @inline
{
    mtk::@check(inner != null, "Slot.fill with a null inner");
    mtk::@check(self.is_empty(), "never overwrite a full Slot");
    *self = (Slot)inner;
}

<*
 Retrieves `$Type*` from the slot without clearing it. Returns `null` on type mismatch.

 @param $Type : "the outer type expected"
*>
macro Slot.to(&self, $Type) => internal::from_slot(self, $Type);

<*
 Retrieves `$Type*` from the slot without clearing it. Aborts on type mismatch.

 @param $Type : "the outer type asserted"
*>
macro Slot.must(&self, $Type) => internal::must_from_slot(self, $Type);

<*
 Extracts `$Type*` from the slot and clears it on success. Returns `null` on mismatch.

 @param $Type : "the outer type expected"
*>
macro Slot.move(&self, $Type) => internal::move_from_slot(self, $Type);


import mtk;


//==============================================================================
// Internal Implementation Details
//==============================================================================
<*
 Internal crossing macros, chain-link primitives, and the compile-time
 field-offset macro. Not part of the public API.
*>
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
    $assert $seen == 1 : "type " +++ $Type::name +++ " has more than one Inner field; exactly one is allowed";
    return $off;
}


import mtk;