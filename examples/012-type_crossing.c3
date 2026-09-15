<*
 One crossing, written three ways.

 `EVENT.look(inner)` is the form to use.
 The other two are what it forwards to.
 Code with no helper bound uses them directly.

 - Creates an `Event` and peeks at its `Inner*`.
 - Crosses back with `EVENT.look`.
 - Crosses back with `inner::internal::from_inner` and checks that it matches.
 - Crosses back with `Inner.to` and checks that it matches.
 - Checks that all three reached the same `Event`.
*>
module shc::c_crossing::type_crossing;
import mtk;
import shc::outers;
import shc::helpers;

alias EVENT  = helper::OF{Event};

faultdef TYPE_CROSSING_FAILED;

fn void? cross_with_dollar_type(Allocator a)
{
    Slot s;
    defer EVENT.release(a, &s);
    EVENT.create(a, &s)!;
    Inner* inner = s.peek();

    Event* helper_form = EVENT.look(inner);
    shc::helpers::expect(TYPE_CROSSING_FAILED, helper_form != null, "EVENT.look did not find the Event")!;
    helper_form.code++;

    Event* free_form = inner::internal::from_inner(inner, Event);
    shc::helpers::expect(TYPE_CROSSING_FAILED, free_form == helper_form, "from_inner did not match EVENT.look")!;
    free_form.code++;

    Event* method_form = inner.to(Event);
    shc::helpers::expect(TYPE_CROSSING_FAILED, method_form == free_form, "inner.to(Event) did not match from_inner(inner, Event)")!;
    method_form.code++;

    shc::helpers::expect(TYPE_CROSSING_FAILED, free_form.code == 3, "all three crossings should have reached the same Event")!;
}
