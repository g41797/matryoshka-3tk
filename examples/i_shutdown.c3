<*
 How a wait ends, and how a program shuts down.

 There is no cancellation.
 A wait ends on an outer, a close, a wake, or a timeout, and nothing else.
 Shutting down means reading which one happened and freeing what `close` returns.
 Stop producing first.
 Then close the mailbox that feeds the workers.
 Every waiting receiver gets `CLOSED`.
 Release what `close` returns, then join the workers.
 Close the pool only after the workers are joined.
 Close a mailbox or a pool before releasing it.
 To keep a mailbox open, send a marker outer that tells the worker to leave.

 - `shc::i_shutdown::reading_the_fault_on_a_receive` — the four outcomes of a wait.
*>
module shc::i_shutdown;
