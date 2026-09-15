<*
 Shutdown, catalog entries 46 through 48.

 3tk has no cancellation.
 A wait ends on an outer, a close, a wake, or a timeout, and nothing else.
 Shutting down means reading which one happened and freeing what `close` returns.

 - `046-reading_the_fault_on_a_receive.c3` — the four outcomes of a wait.

 Entry 47, the shutdown order, is a numbered order with no code of its own.
 Entry 48, shutdown by message, is a diagram with no code of its own.

 This module holds no code of its own.
*>
module shc::i_shutdown;
