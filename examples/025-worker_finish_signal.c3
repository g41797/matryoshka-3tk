<*
 A worker sends its own mailbox to signal that it has finished.

 A real program joins the worker thread after this.

 - Queues a `Holder` on the worker's mailbox.
 - Sends the worker's mailbox to the inbox.
 - Receives the worker's mailbox from the inbox.
 - Checks that the pointer matches.
 - Closes the worker's mailbox.
 - Releases each outer that `close` returns.
 - Releases the worker's mailbox.
*>
module shc::e_infrastructure::worker_finish_signal;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::time;

alias HOLDER = helper::OF{Holder};

faultdef WORKER_FINISH_SIGNAL_FAILED;

fn void free_outer(Allocator a, Slot* s)
{
    if (s.is_empty()) return;
    if (HOLDER.is(s)) { HOLDER.release(a, s); return; }
    unreachable("free_outer met an identity it was not written for");
}

fn void? finish_signal(Allocator a, Mailbox* inbox, Mailbox* worker_mbx)
{
    Slot s;
    inbox.receive(&s, time::ms(1000))!;

    Mailbox* got = mtk::mailbox::of(s.take());
    if (got != worker_mbx) return WORKER_FINISH_SIGNAL_FAILED~;

    InnerQueue left;
    got.close(&left);
    while (Inner* inner = left.pop_front())
    {
        Slot each;
        each.fill(inner);
        free_outer(a, &each);
    }
    got.release();
}

fn void? finish_signal_is_a_real_pointer_check(Allocator a)
{
    Mailbox* inbox = mtk::mailbox::create(a)!;
    defer { InnerQueue left; inbox.close(&left); inbox.release(); }

    Mailbox* worker_mbx = mtk::mailbox::create(a)!;

    Slot left_over;
    defer HOLDER.release(a, &left_over);
    HOLDER.create(a, &left_over)!;
    worker_mbx.send(&left_over)!;

    Slot s;
    s.fill(mtk::mailbox::to_inner(worker_mbx));
    inbox.send(&s)!;

    finish_signal(a, inbox, worker_mbx)!;
}
