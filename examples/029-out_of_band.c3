<*
 An out-of-band outer is received before every regular one.

 There is one out-of-band level, not a priority queue.

 - Sends a `Holder` with `send`.
 - Sends a `Sensor` with `send_oob`.
 - Receives twice.
 - Checks that the `Sensor` arrives first.
 - Checks that the `Holder` arrives second.
*>
module shc::f_mailbox::out_of_band;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::time;

alias SENSOR = helper::OF{Sensor};
alias HOLDER = helper::OF{Holder};

faultdef OUT_OF_BAND_FAILED;

fn void free_outer(Allocator a, Slot* s)
{
    if (s.is_empty()) return;
    if (HOLDER.look(s))  { HOLDER.release(a, s); return; }
    if (SENSOR.look(s))  { SENSOR.release(a, s); return; }
    unreachable("free_outer met an identity it was not written for");
}

fn void? oob_arrives_first(Allocator a, Mailbox* mb)
{
    Slot ordinary;
    HOLDER.create(a, &ordinary)!;
    mb.send(&ordinary)!;

    Slot urgent;
    SENSOR.create(a, &urgent)!;
    mb.send_oob(&urgent)!;

    Slot first;
    mb.receive(&first, time::ms(1000))!;
    shc::helpers::expect(OUT_OF_BAND_FAILED, SENSOR.look(&first) != null, "the out-of-band outer arrives first")!;
    free_outer(a, &first);

    Slot second;
    mb.receive(&second, time::ms(1000))!;
    shc::helpers::expect(OUT_OF_BAND_FAILED, HOLDER.look(&second) != null, "the ordinary outer arrives second")!;
    free_outer(a, &second);
}
