<*
 `mtk::CHECKED` is the `@check` condition as a value.

 It guards a block too expensive to write inside a `@check` argument.

 - Sends one `Holder` into a mailbox.
 - Receives it back as a batch of one.
 - Pops its `Inner*`.
 - Runs a queue walk that happens only when `mtk::CHECKED` is true.
 - Fills a `Slot` with the `Inner*`.
 - Checks that the `Slot` is full.
*>
module shc::k_new_in_3tk::guarding_an_expensive_check;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef GUARDING_AN_EXPENSIVE_CHECK_FAILED;

fn void guarded_walk(InnerQueue* q, Inner* inner)
{
    mtk::@check(inner != null, "this walk was given an inner");

    if (mtk::CHECKED)
    {
        usz n;
        InnerQueueIterator it = q.iter();
        while (Inner* each = it.next()) { n++; }
        mtk::@check(n == q.len(), "the queue's kept count matches its chain");
    }
}

fn void? the_guard_costs_nothing_in_a_fast_build(Allocator a)
{
    Mailbox* mb = mtk::mailbox::create(a)!;
    defer { InnerQueue left; mb.close(&left); mb.release(); }

    Slot s;
    defer HOLDER.release(a, &s);
    HOLDER.create(a, &s)!;
    mb.send(&s)!;

    InnerQueue batch;
    mb.receive_all(&batch)!;
    Inner* inner = batch.pop_front();
    guarded_walk(&batch, inner);

    Slot got;
    got.fill(inner);
    defer HOLDER.release(a, &got);
    shc::helpers::expect(GUARDING_AN_EXPENSIVE_CHECK_FAILED, got.is_full(), "the guarded check did not disturb the inner")!;
}
