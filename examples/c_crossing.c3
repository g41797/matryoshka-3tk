<*
 Crossing the border, catalog entries 11 through 16.

 The border lies between the `Inner` the toolkit keeps and the outer the caller defines.
 These examples give up a type on the way in and recover it on the way out.

 - `011-embedding_the_inner.c3` — the field that makes a struct an outer.
 - `012-type_crossing.c3` — one crossing, written three ways.
 - `013-recovering_the_type.c3` — the checked and the asserting crossings.
 - `015-walk_a_batch.c3` — reading a queue without consuming it.
 - `016-reach_into_a_full_slot.c3` — looking into a `Slot` without taking.

 Entry 14, "Stack outers are illegal", is a prohibition with no code of its own.
 It is why every outer in this tree is allocated.

 `012` and `013` are the only examples allowed to name a crossing below the helper.
 Every other example goes through `OuterHelper`.

 This module holds no code of its own.
*>
module shc::c_crossing;
