// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 The two small types every other module is written against.

 `Inner` is the part you put inside your own struct.
 `Slot` is the place where one outer may be, or may not.
 The mailbox and the pool see an `Inner*` and nothing else.

 ## The inner

 `Inner` has two fields, and both are for the toolkit.

 - `link` is the next inner on the chain.
 - `link` is the inner itself when it is the last one on a chain.
 - `link` is `null` when the outer is on no chain.
 - `otrtypeid` is the `typeid` of the outer the inner sits in.
 - `otrtypeid` is written once, by `stamp`, and never again.
 - `outer_tid` reads it back, before anyone knows the type.

 An `any` is not used here, and that is a decision.

 - An `any` is C3's own border type.
 - It is converted at the border, by `mtk::helper`, and stored nowhere.
 - Two named fields cost the same sixteen bytes and say what they are.

 ## Exactly one inner per outer

 - The offset of the `Inner` field is computed at compile time.
 - So nothing is stored to find the way back: no back-pointer, no map.
 - The field goes anywhere in your struct. First, last, or in the middle.
 - Zero `Inner` fields, or two, is a compile error.
 - The check runs when the toolkit first uses the struct as an outer.
 - Declaring such a struct and never using it is not an error.

 ## The slot

 A slot has one `Inner*`, or nothing, and you read which.

 - `is_empty` and `is_full` answer the question.
 - `peek` reads the `Inner*` and leaves it there.
 - `take` reads it and empties the slot.
 - `fill` puts one in. A second `fill` on a full slot is refused.
 - `fill` of a `null` inner is refused.

 ## Getting your type back

 Three endings, and the ending is the promise.

 - `to` returns your pointer, or `null` when the type does not match.
 - `must` aborts instead of returning `null`.
 - `as` aborts too, and is the `Inner*` spelling of `must`.
 - `Slot.to`, `Slot.must` and `Slot.move` read a slot.
 - `Slot.move` empties the slot when the type matched, and only then.
 - `Inner.to` and `Inner.as` read a bare `Inner*`.

 An abort here is a contract, so it is there in safe mode only.

 Most code uses `mtk::helper` instead, and never names a type twice.
*>
module mtk::inner;

<*
 Intrusive header embedded within user structures (`outer`).

 `link` is the chain link: the next inner on the chain, itself when it is the
 last, or `null` when the outer is on no chain.
 `otrtypeid` is the `typeid` of the outer it sits in, written once by `stamp`.
*>
struct Inner
{
    Inner* link;
    typeid otrtypeid;
}

<*
 Returns the `typeid` of the enclosing outer structure.
*>
fn typeid Inner.outer_tid(&self) @inline => self.otrtypeid;

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


macro bool is_mine(Inner* inner, $Type) => inner != null && inner.otrtypeid == $Type::typeid;

<*
 @require $defined($Typeof(*outer)::members) : "not a struct that embeds an Inner"
*>
macro void stamp(outer)
{
    Inner* inner = (Inner*)((char*)outer + inner_offset($Typeof(*outer)));
    inner.otrtypeid = $Typeof(*outer)::typeid;
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


macro Inner* from_any(any* a, $Type)
{
    if (a.ptr == null || a.type != $Type::typeid) return null;
    Inner* inner = to_inner(($Type*)a.ptr);
    mtk::@check((void*)inner.outer_tid() == null || inner.outer_tid() == $Type::typeid,
        "the any says one type and the outer carries another: it was built by hand, or it points at the wrong thing");
    check_stamped(inner, "the outer was never stamped: make it with `create`, or call `stamp` once");
    return inner;
}


macro void clear_any(any* a) => *a = (any){};


fn void Inner.repoint_to(&self, Inner* to) @inline
    => self.link = to;


fn Inner* Inner.points_to(&self) @inline => self.link;


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