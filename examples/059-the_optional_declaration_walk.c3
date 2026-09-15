<*
 A `while` that declares its `Inner*` keeps the variable inside the loop body.

 No variable is left over to misuse after the loop.

 - Sends three `Holder`s into a mailbox.
 - Receives them as a batch.
 - Walks the batch with `while (Inner* inner = q.pop_front())`, releasing each outer.
 - Checks that the walk saw three.
 - Checks that the batch is empty.
*>
module shc::k_new_in_3tk::the_optional_declaration_walk;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef THE_OPTIONAL_DECLARATION_WALK_FAILED;

fn usz walk_and_release(Allocator a, InnerQueue* q)
{
    usz n;
    while (Inner* inner = q.pop_front())
    {
        Slot s;
        s.fill(inner);
        HOLDER.release(a, &s);
        n++;
    }
    return n;
}

fn void? the_declaration_is_the_condition(Allocator a)
{
    Mailbox* mb = mtk::mailbox::create(a)!;
    defer { InnerQueue left; mb.close(&left); mb.release(); }

    for (int i = 0; i < 3; i++)
    {
        Slot s;
        defer HOLDER.release(a, &s);
        HOLDER.create(a, &s)!;
        mb.send(&s)!;
    }

    InnerQueue batch;
    mb.receive_all(&batch)!;

    usz n = walk_and_release(a, &batch);
    shc::helpers::expect(THE_OPTIONAL_DECLARATION_WALK_FAILED, n == 3, "the walk saw every inner the queue held")!;
    shc::helpers::expect(THE_OPTIONAL_DECLARATION_WALK_FAILED, batch.is_empty(), "pop_front left nothing behind")!;
}
