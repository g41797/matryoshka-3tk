<*
 Looking into a full `Slot` leaves it full.

 - Creates a `Holder` into a `Slot`.
 - Sets a field through `must_look`.
 - Checks that the `Slot` is still full.
 - Sends the `Holder` from the same `Slot`.
 - Receives the `Holder` back.
 - Releases it.
*>
module shc::c_crossing::reach_into_a_full_slot;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::time;

alias HOLDER = helper::OF{Holder};

faultdef REACH_INTO_A_FULL_SLOT_FAILED;

fn void? reach_in_then_send(Allocator a, Mailbox* mb)
{
    Slot s;
    defer HOLDER.release(a, &s);
    HOLDER.create(a, &s)!;
    HOLDER.must_look(&s).id = 42;
    shc::helpers::expect(REACH_INTO_A_FULL_SLOT_FAILED, s.is_full(), "reaching in with must() must leave the Slot full")!;
    mb.send(&s)!;

    Slot got;
    mb.receive(&got, time::ms(1000))!;
    HOLDER.release(a, &got);
}
