<*
 Freeing an outer exactly once, on every path out of a function.

 An outer is always in one place: with the caller, in a `Slot`, on a queue, or inside a mailbox or pool.
 A fault path needs the same care as the normal path.
 The `defer` that frees an outer comes before the call that fills its `Slot`.
 A release on an empty `Slot` does nothing.
 The `Slot` mechanics these build on are in `shc::a_slot_and_transfer`.

 - `shc::b_cleanup::null_safe_cleanup` — a cleanup is safe on an empty `Slot`.
 - `shc::b_cleanup::defer_put_early` — the `defer` comes before the `get`.
 - `shc::b_cleanup::defer_release_early` — the same shape, with a release instead of a `put`.
 - `shc::b_cleanup::defer_for_received_outer` — the receiver releases what it receives.
 - `shc::b_cleanup::refused_put_fallback` — a refused transfer leaves the outer with the caller.
 - `shc::b_cleanup::no_raw_allocator_call` — an outer is allocated and freed through the helper.
*>
module shc::b_cleanup;
