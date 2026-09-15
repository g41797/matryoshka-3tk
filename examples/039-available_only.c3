<*
 `AVAILABLE_ONLY` takes only pooled outers.

 `NOT_AVAILABLE` is the normal end, not a failure.

 - Creates two `Holder`s with `NEW_ONLY` and puts both back.
 - Gets with `AVAILABLE_ONLY` until the pool returns `NOT_AVAILABLE`.
 - Releases each outer it gets.
 - Checks that both pooled outers were taken.
 - Checks that `on_get` did not run.
*>
module shc::h_pool::available_only;
import mtk;
import mtk::pool;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef AVAILABLE_ONLY_FAILED;

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

fn usz drain(Allocator a, Pool* p)
{
    usz taken;
    while (true)
    {
        Slot s;
        if (catch f = p.get(Holder::typeid, AVAILABLE_ONLY, &s))
        {
            break; // NOT_AVAILABLE is the end condition
        }
        taken++;
        HOLDER.release(a, &s);
    }
    return taken;
}

fn void? drain_stops_at_not_available(Allocator a)
{
    CountingHooks hooks;
    hooks.alloc = a;
    typeid[1] tags = { Holder::typeid };
    Pool* p = mtk::pool::create(a, &tags, &hooks)!;
    defer { p.close(); p.release(); }

    for (int i = 0; i < 2; i++)
    {
        Slot s;
        p.get(Holder::typeid, NEW_ONLY, &s)!;
        p.put(&s);
    }
    int seeded = hooks.created;

    usz taken = drain(a, p);
    shc::helpers::expect(AVAILABLE_ONLY_FAILED, taken == 2, "both kept outers must be drained")!;
    shc::helpers::expect(AVAILABLE_ONLY_FAILED, hooks.created == seeded, "the hook must not run on this path")!;
}
