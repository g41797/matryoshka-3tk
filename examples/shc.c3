<*
 A pattern catalog for `mtk`, not part of the library.

 Every file here is real C3, compiled by the ordinary build.
 No file uses `@test`, `assert`, or anything else from the test code.
 Each file holds one pattern and is named `NNN-name.c3`.
 The number matches the file to its row in the pattern catalog.

 - `shc::outers` declares the demo outers shared by every example.
 - `shc::helpers` declares `shc::helpers::expect`, the one check an example may make.
 - Every other file is one pattern, with one public function.
 - That function takes an `Allocator` and reports by returning a fault, never by aborting.

 Each pattern belongs to a group.
 A group is a submodule with a file of its own, `<group>.c3`.
 That file describes the group and declares nothing.
 A pattern's module is `shc::<group>::<name>`.
 The eleven groups, in reading order:

 - `shc::a_slot_and_transfer` — the `Slot`, and what a transfer does to it.
 - `shc::b_cleanup` — freeing exactly once, on every path out.
 - `shc::c_crossing` — giving up a type and recovering it.
 - `shc::d_dispatch` — from an identity to the code that handles it.
 - `shc::e_infrastructure` — a mailbox and a pool are outers too.
 - `shc::f_mailbox` — one mailbox, and the calls made on it.
 - `shc::g_topology` — several mailboxes, arranged.
 - `shc::h_pool` — keeping outers and giving them back.
 - `shc::i_shutdown` — the ways a wait ends.
 - `shc::j_coordinator` — the two levels, and who keeps what.
 - `shc::k_new_in_3tk` — the shapes C3 makes cheap.

 A group segment starts with `a_` to `k_`, so the groups sort in order on the generated page.
 A module segment cannot start with a digit.
 The number stays in the filename, where it names the catalog row.

 Read a pattern's own file for what it shows.
 This module holds no code of its own.
*>
module shc;
