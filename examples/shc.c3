<*
 Examples of `mtk` in use, not part of the library.

 Every file here is real C3, compiled by the ordinary build.
 No file uses `@test`, `assert`, or anything else from the test code.
 Each example is one module with one public function.
 That function takes an `Allocator` and reports by returning a fault, never by aborting.

 - `shc::outers` declares the demo outers shared by every example.
 - `shc::helpers` declares `shc::helpers::expect`, the one check an example may make.

 Examples are grouped by subject, in reading order:

 - `shc::a_slot_and_transfer` — the `Slot`, and what a transfer does to it.
 - `shc::b_cleanup` — freeing exactly once, on every path out.
 - `shc::c_crossing` — giving up a type and recovering it.
 - `shc::d_dispatch` — from an identity to the code that handles it.
 - `shc::e_infrastructure` — a mailbox and a pool are outers too.
 - `shc::f_mailbox` — one mailbox, and the calls made on it.
 - `shc::g_topology` — several mailboxes, arranged.
 - `shc::h_pool` — keeping outers and giving them back.
 - `shc::i_shutdown` — how a wait ends, and shutting down.
 - `shc::j_coordinator` — a coordinator and its steps.
 - `shc::k_new_in_3tk` — shapes that C3 makes cheap.
 - `shc::l_bridge` — outers leaving as `any`, and coming back.
*>
module shc;
