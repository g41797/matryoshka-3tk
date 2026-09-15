<*
 One mailbox, and the calls a single participant makes on it.

 Shapes that combine several mailboxes are in `shc::g_topology`.

 - `shc::f_mailbox::poll` — a work loop that must not wait.
 - `shc::f_mailbox::receive_all` — receiving everything in one call.
 - `shc::f_mailbox::out_of_band` — a message that goes ahead of the queue.
 - `shc::f_mailbox::close_recovery` — what `close` returns, and who frees it.
 - `shc::f_mailbox::release_a_refused_transfer` — a refused `send` leaves the outer with the caller.
 - `shc::f_mailbox::wake_without_a_message` — ending a wait with nothing to receive.
 - `shc::f_mailbox::send_with_limit` — a cap on queued outers, per `typeid`.
*>
module shc::f_mailbox;
