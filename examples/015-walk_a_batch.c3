<*
 `InnerQueue` is the one list type, walked two ways.

 - Sends three `Holder`s into a mailbox.
 - Receives them all at once into an `InnerQueue`.
 - Walks the queue with an iterator, which leaves it intact.
 - Checks that the queue still has all three.
 - Walks it again with `pop_front`, releasing each outer.
 - Checks that the queue is empty.
*>
module shc::c_crossing::walk_a_batch;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef WALK_A_BATCH_FAILED;

fn void? walk_a_received_batch(Allocator a)
{
    Mailbox* mb = mtk::mailbox::create(a)!;
    defer { InnerQueue left; mb.close(&left); mb.release(); }

    for (int i = 0; i < 3; i++)
    {
        Slot s;
        defer HOLDER.release(a, &s);
        HOLDER.create(a, &s)!;
        HOLDER.must_look(&s).id = i;
        mb.send(&s)!;
    }

    InnerQueue batch;
    mb.receive_all(&batch)!;

    usz seen;
    InnerQueueIterator it = batch.iter();
    while (Inner* inner = it.next()) { seen++; }
    shc::helpers::expect(WALK_A_BATCH_FAILED, seen == 3, "the iterator should see all three without consuming them")!;
    shc::helpers::expect(WALK_A_BATCH_FAILED, batch.len() == 3, "walking with an iterator must not consume the queue")!;

    while (Inner* inner = batch.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(a, &s);
    }
    shc::helpers::expect(WALK_A_BATCH_FAILED, batch.is_empty(), "pop_front should have emptied the queue")!;
}
