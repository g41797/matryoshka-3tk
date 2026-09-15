<*
 Mailbox patterns, catalog entries 27 through 32.

 One mailbox, and the calls a single participant makes on it.
 Shapes that combine several mailboxes are in `shc::g_topology`.

 - `027-poll.c3` — a work loop that must not wait.
 - `028-receive_all.c3` — receiving everything in one call.
 - `029-out_of_band.c3` — a message that goes ahead of the queue.
 - `030-close_recovery.c3` — what `close` returns, and who frees it.
 - `031-release_a_refused_transfer.c3` — a refused `send` leaves the outer with the caller.
 - `032-wake_without_a_message.c3` — ending a wait with nothing to receive.
 - `062-send_with_limit.c3` — a cap on queued outers, per `typeid`.

 This module holds no code of its own.
*>
module shc::f_mailbox;
