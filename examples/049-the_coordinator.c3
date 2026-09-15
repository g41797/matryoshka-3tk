<*
 A coordinator runs discrete steps, and its `run` body shows them at a glance.

 No step reaches around another to touch a `Slot` or an `Inner*`.

 - `seed_the_work` gets outers from the pool and sends them.
 - `process_the_work` receives each outer and puts it back.
 - `shut_down` closes the mailbox, then closes the pool.
*>
module shc::j_coordinator::the_coordinator;
import mtk;
import mtk::mailbox;
import mtk::pool;
import shc::outers;
import shc::helpers;
import std::time;

alias HOLDER = helper::OF{Holder};

faultdef THE_COORDINATOR_FAILED;

struct CoordinatorHooks (PoolHooks) { Allocator alloc; }

fn void CoordinatorHooks.on_get(&self, typeid want, usz in_pool, Slot* slot) @dynamic
{
    if (catch HOLDER.create(self.alloc, slot)) return;
}

fn void CoordinatorHooks.on_put(&self, usz in_pool, Slot* slot, InnerQueue* extra) @dynamic {}

fn void CoordinatorHooks.on_close(&self, InnerQueue remaining) @dynamic
{
    while (Inner* inner = remaining.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(self.alloc, &s);
    }
}

struct Master
{
    Allocator alloc;
    Mailbox*  mbx;
    Pool*     pool;
    usz       processed;
}

fn void? Master.seed_the_work(&self)
{
    for (usz i = 0; i < 3; i++)
    {
        Slot s;
        self.pool.get(Holder::typeid, AVAILABLE_OR_NEW, &s)!;
        self.mbx.send(&s)!;
    }
}

fn void? Master.process_the_work(&self)
{
    for (usz i = 0; i < 3; i++)
    {
        Slot s;
        self.mbx.receive(&s, time::ms(2000))!;
        self.pool.put(&s);
        self.processed++;
    }
}

fn void Master.shut_down(&self)
{
    InnerQueue left;
    self.mbx.close(&left);
    while (Inner* inner = left.pop_front())
    {
        Slot s;
        s.fill(inner);
        self.pool.put(&s);
    }
    self.mbx.release();
    self.pool.close();
    self.pool.release();
}

fn void? Master.run(&self)
{
    self.seed_the_work()!;
    self.process_the_work()!;
    self.shut_down();
    if (self.processed == 0) return THE_COORDINATOR_FAILED~;
}
