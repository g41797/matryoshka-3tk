<*
 Several mailboxes and threads, arranged.

 Each shape combines the mailbox calls in `shc::f_mailbox`.
 None adds a new mechanism.

 - `shc::g_topology::request_response` — one side asks, the other answers.
 - `shc::g_topology::pipeline` — each stage receives, transforms and sends on.
 - `shc::g_topology::fan_in` — many senders, one mailbox.
 - `shc::g_topology::fan_out` — one mailbox, many workers receiving from it.
*>
module shc::g_topology;
