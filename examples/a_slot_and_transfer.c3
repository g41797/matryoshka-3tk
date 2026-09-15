<*
 The `Slot`, and what a transfer does to it.

 A `Slot` is how an outer moves from one place to another.
 A `Slot` is never overwritten.
 `Slot.fill` checks that the `Slot` is empty.
 Every later group builds on these examples.
 Freeing what a `Slot` holds is in `shc::b_cleanup`.

 - `shc::a_slot_and_transfer::empty_slot` — a declared `Slot` starts empty.
 - `shc::a_slot_and_transfer::transfer_empties_slot` — a transfer leaves the `Slot` empty.
 - `shc::a_slot_and_transfer::insert_from_slot` — an insert takes the outer from a `Slot`.
*>
module shc::a_slot_and_transfer;
