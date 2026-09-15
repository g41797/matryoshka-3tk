<*
 Shapes that C3 makes cheap.

 C3 has compile-time reflection, a `typeid` for every type, and builds that drop their checks.
 A fast build drops every contract check.
 Releasing an open mailbox or an open pool aborts in every build.
 Test in a checking build.

 - `shc::k_new_in_3tk::the_allocator_in_the_outer` — an outer that keeps its own allocator.
 - `shc::k_new_in_3tk::identity_costs_nothing` — a new type needs no registration.
 - `shc::k_new_in_3tk::the_optional_declaration_walk` — walking a queue with `while`.
 - `shc::k_new_in_3tk::guarding_an_expensive_check` — a check a fast build drops.
 - `shc::k_new_in_3tk::composite_outer_gives_back` — an outer made of outers.
*>
module shc::k_new_in_3tk;
