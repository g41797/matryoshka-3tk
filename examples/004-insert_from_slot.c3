<*
 `push_back_slot` empties the `Slot` itself, so no line has to clear it.

 - Creates a `Holder` into a `Slot`.
 - Sets a field.
 - Pushes the `Holder` onto a queue from the `Slot`.
 - Checks that the `Slot` is empty.
 - Pops each outer off the queue and releases it.
*>
module shc::a_slot_and_transfer::insert_from_slot;
import mtk;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef INSERT_FROM_SLOT_FAILED;

fn void? insert_from_a_slot(Allocator a)
{
    InnerQueue q;
    Slot s;
    defer HOLDER.release(a, &s);
    HOLDER.create(a, &s)!;
    HOLDER.must_look(&s).id = 7;

    q.push_back_slot(&s);
    shc::helpers::expect(INSERT_FROM_SLOT_FAILED, s.is_empty(), "push_back_slot left the Slot full")!;

    while (Inner* inner = q.pop_front())
    {
        Slot popped;
        popped.fill(inner);
        HOLDER.release(a, &popped);
    }
}
