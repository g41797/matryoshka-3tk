<*
 A mailbox and a pool are outers too.

 A mailbox and a pool each embed an `Inner` and carry an identity.
 Either one can be sent through a mailbox or kept on a queue like any other outer.

 - `shc::e_infrastructure::infrastructure_wrapper` — a wrapper, when the mailbox alone is not enough.
 - `shc::e_infrastructure::mailbox_as_message` — sending a mailbox through a mailbox.
 - `shc::e_infrastructure::worker_finish_signal` — the outer that says a worker is done.
 - `shc::e_infrastructure::pool_as_message` — sending a pool the same way.
*>
module shc::e_infrastructure;
