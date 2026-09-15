<*
 Keeping outers, and giving them back.

 The pool keeps outers the caller is finished with and gives them back on `get`.
 The pool has no policy of its own, so a pool cannot exist without hooks.
 When nothing is pooled, the caller's mode and the hooks decide what happens.
 A hook runs outside the pool's lock, and several hooks may run at once.
 A hook never calls back into the pool.
 When the pool closes, `on_close` gets every pooled outer.
 `on_close` may be called more than once.

 - `shc::h_pool::available_or_new` — reuse if possible, otherwise call `on_get`.
 - `shc::h_pool::new_only` — always call `on_get`.
 - `shc::h_pool::available_only` — never call `on_get`.
 - `shc::h_pool::seeding_a_fixed_size_pool` — hooks that stop creating.
 - `shc::h_pool::the_hooks_struct_is_the_context` — the hooks carry their own state.
 - `shc::h_pool::a_pool_of_several_identities` — one pool, one free list per identity.
*>
module shc::h_pool;
