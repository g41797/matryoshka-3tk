<*
 A thread gets one `void*`, and one pointer is enough.

 The context struct has everything the thread needs.
 Any field the thread and the joiner both touch is atomic.

 - Starts a worker with one `WorkerCtx` pointer.
 - Sends three `Holder`s.
 - In the worker, receives, releases and counts each `Holder`.
 - Joins the worker.
 - Checks that the worker counted three.
*>
module shc::j_coordinator::the_thread_is_given_one_pointer;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::thread;
import std::time;
import std::atomic::types;

alias HOLDER = helper::OF{Holder};

faultdef THE_THREAD_IS_GIVEN_ONE_POINTER_FAILED;

struct WorkerCtx
{
    Mailbox*    mbx;
    Allocator   alloc;
    usz         target;
    Atomic{usz} done;
}

fn void? mb_receive(Mailbox* mb, Slot* s) => mb.receive(s, time::ms(2000));

fn int worker_main(void* arg)
{
    WorkerCtx* ctx = (WorkerCtx*)arg;
    while (ctx.done.load(ACQUIRE) < ctx.target)
    {
        Slot s;
        if (catch mb_receive(ctx.mbx, &s)) break;
        HOLDER.release(ctx.alloc, &s);
        ctx.done.add(1);
    }
    return 0;
}

fn void? one_pointer_is_the_whole_context(Allocator a, Mailbox* mb)
{
    WorkerCtx ctx = { .mbx = mb, .alloc = a, .target = 3 };
    ctx.done.store(0, RELEASE);

    Thread t;
    t.create(&worker_main, &ctx)!!;

    for (int i = 0; i < 3; i++)
    {
        Slot s;
        defer HOLDER.release(a, &s);
        HOLDER.create(a, &s)!;
        mb.send(&s)!;
    }

    t.join()!!;

    shc::helpers::expect(THE_THREAD_IS_GIVEN_ONE_POINTER_FAILED, ctx.done.load(ACQUIRE) == 3, "the worker reached every outer through the one context pointer")!;
}
