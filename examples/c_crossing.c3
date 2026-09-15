<*
 Giving up an outer's type, and recovering it.

 The border lies between the `Inner` the toolkit keeps and the outer the caller defines.
 An outer is never on the stack.
 Its address is computed from its `Inner` at every crossing, and a stack address goes stale.
 Only `shc::c_crossing::type_crossing` and `shc::c_crossing::recovering_the_type` name a crossing below the helper.
 Every other example goes through `OuterHelper`.

 - `shc::c_crossing::embedding_the_inner` — the field that makes a struct an outer.
 - `shc::c_crossing::type_crossing` — one crossing, written three ways.
 - `shc::c_crossing::recovering_the_type` — the checked and the asserting crossings.
 - `shc::c_crossing::walk_a_batch` — reading a queue without consuming it.
 - `shc::c_crossing::reach_into_a_full_slot` — looking into a `Slot` without taking.
*>
module shc::c_crossing;
