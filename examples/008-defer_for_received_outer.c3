<*
 A deferred release covers both the normal path and the fault path of a receive.

 - Sends a `Holder` to a mailbox.
 - Receives it into a `Slot`, with the release deferred first.
 - Releases the received `Holder` on scope exit.
 - Receives again and gets `TIMEOUT`.
 - Runs the deferred release on the empty `Slot`, which does nothing.
*>
module shc::b_cleanup::defer_for_received_outer;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::time;

alias HOLDER = helper::OF{Holder};

faultdef DEFER_RECEIVED_FAILED;

fn void receive_and_release(Allocator a, Mailbox* mb, Duration timeout)
{
    Slot s;
    defer HOLDER.release(a, &s);
    if (catch mb.receive(&s, timeout)) return;
    HOLDER.must_look(&s).id++;
}

fn void? defer_covers_both_paths(Allocator a)
{
    Mailbox* mb = mtk::mailbox::create(a)!;
    defer { InnerQueue left; mb.close(&left); mb.release(); }

    Slot sent;
    defer HOLDER.release(a, &sent);
    HOLDER.create(a, &sent)!;
    mb.send(&sent)!;

    receive_and_release(a, mb, time::ms(100));            // the normal path: the outer is released after use
    receive_and_release(a, mb, time::ms(1));               // the fault path: TIMEOUT, and the empty Slot's defer does nothing
}
