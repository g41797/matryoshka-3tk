<*
 Cleanup idioms, catalog entries 5 through 10.

 An outer is always in one place: with the caller, in a `Slot`, on a queue, or inside a mailbox or pool.
 These examples free it exactly once on every path out of a function, fault paths included.

 - `005-null_safe_cleanup.c3` — a cleanup is safe on an empty `Slot`.
 - `006-defer_put_early.c3` — the `defer` comes before the `get`.
 - `007-defer_release_early.c3` — the same shape, with a release instead of a `put`.
 - `008-defer_for_received_outer.c3` — the receiver releases what it receives.
 - `009-refused_put_fallback.c3` — a refused transfer leaves the outer with the caller.
 - `010-no_raw_allocator_call.c3` — an outer is allocated and freed through the helper.

 The catalog lists these under "Slot and transfer idioms".
 They are a separate group here because cleanup is its own subject.
 The `Slot` mechanics they build on are in `shc::a_slot_and_transfer`.

 This module holds no code of its own.
*>
module shc::b_cleanup;
