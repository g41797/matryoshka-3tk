<*
 A coordinator and its steps.

 A coordinator runs the steps and keeps the resources.
 A step does one thing and keeps nothing.
 When nothing happens between spawning and joining workers, the two are one step.
 Each coordinator takes down its own resources.
 The pool is where an outer comes from and goes back to.
 The mailbox is how an outer travels.

 - `shc::j_coordinator::the_coordinator` — the structure that runs the steps.
 - `shc::j_coordinator::the_step` — one step, doing one thing.
 - `shc::j_coordinator::acquiring_the_resources` — the mailbox and pool a run needs.
 - `shc::j_coordinator::releasing_the_resources` — giving them back, in order.
 - `shc::j_coordinator::the_thread_is_given_one_pointer` — a worker reaches everything through its context.
*>
module shc::j_coordinator;
