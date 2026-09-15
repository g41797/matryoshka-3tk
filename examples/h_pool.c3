<*
 Pool patterns, catalog entries 37 through 45.

 The pool keeps outers the caller is finished with and gives them back on `get`.
 It has no policy of its own.
 When nothing is pooled, the caller's mode and the hooks decide what happens.

 - `037-available_or_new.c3` — reuse if possible, otherwise call `on_get`.
 - `038-new_only.c3` — always call `on_get`.
 - `039-available_only.c3` — never call `on_get`.
 - `040-seeding_a_fixed_size_pool.c3` — hooks that stop creating.
 - `042-the_hook_object_is_the_context.c3` — the hooks carry their own state.
 - `045-a_pool_of_several_identities.c3` — one pool, one free list per identity.

 Entry 41, the pool has no policy, has no code of its own.
 Entry 43, a hook runs outside the lock, has no code of its own.
 Entry 44, the `on_close` hook, has no code of its own.

 This module holds no code of its own.
*>
module shc::h_pool;
