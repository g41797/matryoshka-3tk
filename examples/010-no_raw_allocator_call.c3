<*
 An outer is never allocated with a raw allocator call.

 - Shows the wrong shape as a commented-out line.
 - Creates a `Holder` with `HOLDER.create`, which runs `init` and stamps the identity.
 - Checks that the `Holder` carries its identity.
*>
module shc::b_cleanup::no_raw_allocator_call;
import mtk;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef NO_RAW_ALLOCATOR_CALL_FAILED;

fn void? never_a_raw_allocator_call(Allocator a)
{
    // Wrong: a raw allocator call skips the `init` hook and the stamp.
    // Holder* outer = a.new(Holder);

    Slot s;
    defer HOLDER.release(a, &s);
    HOLDER.create(a, &s)!;

    shc::helpers::expect(NO_RAW_ALLOCATOR_CALL_FAILED, HOLDER.is(&s), "the outer carries no identity")!;
}
