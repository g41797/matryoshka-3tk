<*
 From an outer's identity to the code that handles it.

 An outer arrives with its identity and nothing else.
 An identity names a type, not an instance.
 A dispatch chain always ends with a final branch.
 For a closed set of identities, that branch is `unreachable`.
 For an open set, it counts, reports, or returns a fault.
 It cannot release an outer of an unknown identity.

 - `shc::d_dispatch::dispatch_outer_first` — cross first, then branch on the typed pointer.
 - `shc::d_dispatch::dispatch_identity_first` — branch on the identity, then cross.
 - `shc::d_dispatch::dispatch_switch` — a `switch` over identities.
 - `shc::d_dispatch::dispatch_table` — a table of handlers, looked up by identity.
*>
module shc::d_dispatch;
