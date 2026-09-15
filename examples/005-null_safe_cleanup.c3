<*
 A cleanup on an empty `Slot` does nothing.

 - Gets a pooled `Holder` into a `Slot`, with the `put` deferred first.
 - Pushes it onto a queue, so its `Slot` is empty when cleanup runs.
 - Checks that the pooled `Slot` is empty.
 - Creates a second `Holder`, with the release deferred first.
 - Releases the second `Holder` on scope exit.
 - Runs the deferred `put` on the empty `Slot`, which does nothing.
*>
module shc::b_cleanup::null_safe_cleanup;
import mtk;
import mtk::pool;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef NULL_SAFE_CLEANUP_FAILED;

struct AlwaysCreateHooks (PoolHooks)
{
    Allocator alloc;
}

fn void AlwaysCreateHooks.on_get(&self, typeid want, usz in_pool, Slot* slot) @dynamic
{
    if (catch HOLDER.create(self.alloc, slot)) return;
}

fn void AlwaysCreateHooks.on_put(&self, usz in_pool, Slot* slot, InnerQueue* extra) @dynamic {}

fn void AlwaysCreateHooks.on_close(&self, InnerQueue remaining) @dynamic
{
    while (Inner* inner = remaining.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(self.alloc, &s);
    }
}

fn void? cleanup_survives_an_empty_slot(Allocator a)
{
    AlwaysCreateHooks hooks = { .alloc = a };
    typeid[1] tags = { Holder::typeid };
    Pool* p = mtk::pool::create(a, &tags, &hooks)!;
    defer { p.close(); p.release(); }

    InnerQueue q;
    defer
    {
        while (Inner* inner = q.pop_front())
        {
            Slot s;
            s.fill(inner);
            HOLDER.release(a, &s);
        }
    }

    Slot pooled;
    defer p.put(&pooled);                       // no-op: the queue already took it
    p.get(Holder::typeid, AVAILABLE_OR_NEW, &pooled)!;
    q.push_back_slot(&pooled);
    shc::helpers::expect(NULL_SAFE_CLEANUP_FAILED, pooled.is_empty(), "the pooled Slot is not empty")!;

    Slot heaped;
    defer HOLDER.release(a, &heaped);    // has work to do
    HOLDER.create(a, &heaped)!;
}
