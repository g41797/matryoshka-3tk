<*
 Dispatch, catalog entries 17 through 20.

 An outer arrives with its identity and nothing else.
 These four shapes get from that identity to the code that handles it.
 They are ordered by how many identities make each one worth writing.

 - `017-dispatch_outer_first.c3` — cross first, then branch on the typed pointer.
 - `018-dispatch_identity_first.c3` — branch on the identity, then cross.
 - `019-dispatch_switch.c3` — a `switch` over identities.
 - `020-dispatch_table.c3` — a table of handlers, looked up by identity.

 Entry 21, the last branch of a chain, is a rule with no code of its own.
 Entry 22, an identity names a type and not an instance, is a rule with no code of its own.

 This module holds no code of its own.
*>
module shc::d_dispatch;
