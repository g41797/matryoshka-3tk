<*
 New in 3tk, catalog entries 57 through 62.

 These shapes have no entry in the port 3tk came from.
 They exist because C3 makes compile-time reflection, a `typeid` per type, and check-free builds cheap.

 - `057-the_allocator_in_the_outer.c3` — an outer that keeps its own allocator.
 - `058-an_identity_costs_no_registration.c3` — a new type needs no registration.
 - `059-the_optional_declaration_walk.c3` — walking a queue with `while`.
 - `060-guarding_an_expensive_check.c3` — a check a fast build drops.
 - `061-a_composite_outer_gives_back_its_parts.c3` — an outer made of outers.

 Entry 62, what a fast build stops checking, is text about the builds with no code of its own.
 Entry 42 is also 3tk-only, and sits with the pool patterns, where it is read.

 This module holds no code of its own.
*>
module shc::k_new_in_3tk;
