<*
 The border between Matryoshka and C3, and the calls that cross it.

 An outer leaves as an `any` and comes back as an `any`.
 An `any` is handled like a `Slot`, by address.
 An `any` is empty when `.ptr` is null.
 An outer crosses unlinked, in both directions.
 `.type` is a hint, and the identity stamped inside the outer is the truth.
 What happens to an `any` on the C3 side is the user's.

 - `shc::l_bridge::from_a_channel_to_a_mailbox` — outers arrive as `any` and go on through a mailbox.
 - `shc::l_bridge::io_and_outers_share_a_channel` — the io side tells its own events from outers.
*>
module shc::l_bridge;
