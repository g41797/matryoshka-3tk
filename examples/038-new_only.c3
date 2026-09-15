<*
 `NEW_ONLY` always calls `on_get`, even when a pooled outer is available.

 - Gets a `Holder` with `NEW_ONLY`.
 - Puts it back, so the pool has one.
 - Checks that `on_get` ran once.
 - Gets again with `NEW_ONLY`.
 - Checks that `on_get` ran a second time.
 - Puts the second `Holder` back on scope exit.
*>
module shc::h_pool::new_only;
import mtk;
import mtk::pool;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef NEW_ONLY_FAILED;

struct CountingHooks (PoolHooks) { Allocator alloc; int created; }

fn void CountingHooks.on_get(&self, typeid want, usz in_pool, Slot* slot) @dynamic
{
    self.created++;
    if (catch HOLDER.create(self.alloc, slot)) return;
}

fn void CountingHooks.on_put(&self, usz in_pool, Slot* slot, InnerQueue* extra) @dynamic {}

fn void CountingHooks.on_close(&self, InnerQueue remaining) @dynamic
{
    while (Inner* inner = remaining.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(self.alloc, &s);
    }
}

fn void? new_ignores_what_is_kept(Allocator a)
{
    CountingHooks hooks;
    hooks.alloc = a;
    typeid[1] tags = { Holder::typeid };
    Pool* p = mtk::pool::create(a, &tags, &hooks)!;
    defer { p.close(); p.release(); }

    Slot seed;
    p.get(Holder::typeid, NEW_ONLY, &seed)!;
    p.put(&seed);
    shc::helpers::expect(NEW_ONLY_FAILED, hooks.created == 1, "the seed itself came from the hook")!;

    Slot s;
    p.get(Holder::typeid, NEW_ONLY, &s)!;
    defer p.put(&s);
    shc::helpers::expect(NEW_ONLY_FAILED, hooks.created == 2, "NEW_ONLY must ask the hook even though one outer was kept")!;
}
