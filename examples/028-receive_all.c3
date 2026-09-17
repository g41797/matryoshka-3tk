<*
 `receive_all` takes the lock once for the whole batch.

 After it returns, the outers are the caller's.

 - Sends three `Holder`s.
 - Receives all of them in one call.
 - Releases each `Holder` from the batch.
 - Checks that all three came back.
*>
module shc::f_mailbox::receive_all;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef RECEIVE_ALL_FAILED;

fn void? send_three(Allocator a, Mailbox* mb)
{
    for (int i = 0; i < 3; i++)
    {
        Slot s;
        HOLDER.create(a, &s)!;
        mb.send(&s)!;
    }
}

fn void? receive_all_at_once(Allocator a, Mailbox* mb)
{
    send_three(a, mb)!;

    InnerQueue batch;
    mb.receive_all(&batch)!;

    usz count = 0;
    while (Inner* inner = batch.pop_front())
    {
        Slot s;
        s.fill(inner);
        shc::helpers::expect(RECEIVE_ALL_FAILED, HOLDER.is(&s), "every received outer is the Holder that was sent")!;
        HOLDER.release(a, &s);
        count++;
    }
    shc::helpers::expect(RECEIVE_ALL_FAILED, count == 3, "all three outers came back in one call")!;
}
