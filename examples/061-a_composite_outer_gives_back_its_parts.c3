<*
 `on_put` can return extra outers through `extra`.

 The pool takes them the same way as the `Slot`, with the same checks.
 A composite outer returns its parts to their free lists this way.
 A hook never calls back into the pool.
 Here `extra` stays empty, because a `Holder` has no parts.

 - Gets a `Holder` from a pool whose hooks count `on_put` calls.
 - Puts it back.
 - Checks that `on_put` ran once.
*>
module shc::k_new_in_3tk::composite_outer_gives_back;
import mtk;
import mtk::pool;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef A_COMPOSITE_OUTER_GIVES_BACK_ITS_PARTS_FAILED;

struct PartHooks (PoolHooks) { Allocator alloc; int on_put_calls; }

fn void PartHooks.on_get(&self, typeid want, usz in_pool, Slot* slot) @dynamic
{
    if (catch HOLDER.create(self.alloc, slot)) return;
}

fn void PartHooks.on_put(&self, usz in_pool, Slot* slot, InnerQueue* extra) @dynamic
{
    Holder* outer = HOLDER.must_look(slot);
    outer.id = 0;
    self.on_put_calls++;
    // A composite outer pushes its parts onto `extra` here.
    // A `Holder` has no parts, so `extra` stays empty.
}

fn void PartHooks.on_close(&self, InnerQueue remaining) @dynamic
{
    while (Inner* inner = remaining.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(self.alloc, &s);
    }
}

fn void? extra_is_taken_the_same_way_as_the_slot(Allocator a)
{
    PartHooks hooks;
    hooks.alloc = a;
    typeid[1] tags = { Holder::typeid };
    Pool* p = mtk::pool::create(a, &tags, &hooks)!;
    defer { p.close(); p.release(); }

    Slot s;
    p.get(Holder::typeid, AVAILABLE_OR_NEW, &s)!;
    p.put(&s);
    shc::helpers::expect(A_COMPOSITE_OUTER_GIVES_BACK_ITS_PARTS_FAILED, hooks.on_put_calls == 1, "on_put ran once for the outer put back")!;
}
