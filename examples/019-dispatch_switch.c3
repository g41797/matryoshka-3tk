<*
 A `switch` over a `typeid` is a dispatch shape ztk cannot write.

 - Creates one outer of each identity in turn.
 - Switches on its identity and updates a field in the matching case.
 - Checks that the matching case ran.
 - Releases the outer.
*>
module shc::d_dispatch::dispatch_switch;
import mtk;
import shc::outers;
import shc::helpers;

alias EVENT  = helper::OF{Event};
alias SENSOR = helper::OF{Sensor};
alias HOLDER = helper::OF{Holder};

faultdef DISPATCH_SWITCH_FAILED;

fn void touch_by_switch(Inner* inner)
{
    switch (inner.link.type)
    {
        case Event::typeid:
            EVENT.must_look(inner).code++;
        case Sensor::typeid:
            SENSOR.must_look(inner).reading++;
        case Holder::typeid:
            HOLDER.must_look(inner).id++;
        default:
            unreachable("closed set: every identity is a prong");
    }
}

fn void? dispatch_by_switch(Allocator a)
{
    Slot s;

    EVENT.create(a, &s)!;
    touch_by_switch(s.peek());
    shc::helpers::expect(DISPATCH_SWITCH_FAILED, EVENT.must_look(&s).code == 1, "the Event prong must run")!;
    EVENT.release(a, &s);

    SENSOR.create(a, &s)!;
    touch_by_switch(s.peek());
    shc::helpers::expect(DISPATCH_SWITCH_FAILED, SENSOR.must_look(&s).reading == 1, "the Sensor prong must run")!;
    SENSOR.release(a, &s);

    HOLDER.create(a, &s)!;
    touch_by_switch(s.peek());
    shc::helpers::expect(DISPATCH_SWITCH_FAILED, HOLDER.must_look(&s).id == 1, "the Holder prong must run")!;
    HOLDER.release(a, &s);
}
