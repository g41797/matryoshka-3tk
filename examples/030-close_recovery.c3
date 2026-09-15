<*
 `close` returns every outer the mailbox kept.

 The mailbox never touches an outer.
 Run the release loop every time.
 It is correct whether the mailbox kept outers, kept none, or was already closed.

 - Sends a `Holder`.
 - Closes the mailbox and releases what `close` returns.
 - Checks that the `Holder` came back.
 - Closes the mailbox again.
 - Runs the same release loop on the empty queue.
 - Checks that nothing came back.
*>
module shc::f_mailbox::close_recovery;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef CLOSE_RECOVERY_FAILED;

fn void drain(Allocator a, InnerQueue* q, usz* freed)
{
    while (Inner* inner = q.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(a, &s);
        (*freed)++;
    }
}

fn void? close_recovers_what_is_left(Allocator a, Mailbox* mb)
{
    Slot s;
    HOLDER.create(a, &s)!;
    mb.send(&s)!;

    InnerQueue left;
    mb.close(&left);
    usz freed = 0;
    drain(a, &left, &freed);
    shc::helpers::expect(CLOSE_RECOVERY_FAILED, freed == 1, "the Holder sent before close came back from close")!;

    InnerQueue left_again;
    mb.close(&left_again);
    usz freed_again = 0;
    drain(a, &left_again, &freed_again);
    shc::helpers::expect(CLOSE_RECOVERY_FAILED, freed_again == 0, "a second close gives back an empty queue")!;

    mb.release();
}
