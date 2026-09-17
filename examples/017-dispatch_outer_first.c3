<*
 An outer-first dispatch chain releases a `Slot` of any identity it knows.

 - Declares the chain once, over the three demo identities.
 - Creates one outer of each identity in turn.
 - Releases each one through the chain.
 - Checks after each release that the `Slot` is empty.
*>
module shc::d_dispatch::dispatch_outer_first;
import mtk;
import shc::outers;
import shc::helpers;

alias EVENT  = helper::OF{Event};
alias SENSOR = helper::OF{Sensor};
alias HOLDER = helper::OF{Holder};

faultdef DISPATCH_OUTER_FIRST_FAILED;

fn void free_outer(Allocator a, Slot* s)
{
    if (s.is_empty()) return;
    if (EVENT.is(s))  { EVENT.release(a, s);  return; }
    if (SENSOR.is(s)) { SENSOR.release(a, s); return; }
    if (HOLDER.is(s)) { HOLDER.release(a, s); return; }
    unreachable("free_outer met an identity it was not written for");
}

fn void? dispatch_releases_every_identity(Allocator a)
{
    Slot s;

    EVENT.create(a, &s)!;
    free_outer(a, &s);
    shc::helpers::expect(DISPATCH_OUTER_FIRST_FAILED, s.is_empty(), "the chain must empty the Slot for Event")!;

    SENSOR.create(a, &s)!;
    free_outer(a, &s);
    shc::helpers::expect(DISPATCH_OUTER_FIRST_FAILED, s.is_empty(), "the chain must empty the Slot for Sensor")!;

    HOLDER.create(a, &s)!;
    free_outer(a, &s);
    shc::helpers::expect(DISPATCH_OUTER_FIRST_FAILED, s.is_empty(), "the chain must empty the Slot for Holder")!;
}
