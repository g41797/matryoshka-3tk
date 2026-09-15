<*
 Coordinator patterns, catalog entries 49 through 53.

 These carry the "Two levels" rule.
 A coordinator runs the steps and keeps the resources.
 A step does one thing and keeps nothing.
 These are the longest examples, and the closest to a real program.

 - `049-the_coordinator.c3` — the structure that runs the steps.
 - `050-the_step.c3` — one step, doing one thing.
 - `051-acquiring_the_resources.c3` — the mailbox and pool a run needs.
 - `052-releasing_the_resources.c3` — giving them back, in order.
 - `053-the_thread_is_given_one_pointer.c3` — a worker reaches everything through its context.

 Entry 54, spawn and join in one step, has no code of its own.
 Entry 55, more than one coordinator, has no code of its own.
 Entry 56, pool and mailbox together, has no code of its own.

 This module holds no code of its own.
*>
module shc::j_coordinator;
