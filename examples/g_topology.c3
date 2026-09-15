<*
 Topology patterns, catalog entries 33 through 36.

 Each one combines the mailbox calls in `shc::f_mailbox`.
 None adds a new mechanism.
 They differ only in how mailboxes and threads are arranged.

 - `033-request_response.c3` — one side asks, the other answers.
 - `034-pipeline.c3` — each stage receives, transforms and sends on.
 - `035-fan_in.c3` — many senders, one mailbox.
 - `036-fan_out.c3` — one mailbox, many workers receiving from it.

 This module holds no code of its own.
*>
module shc::g_topology;
