<*
 An outer keeps its allocator only if its own `init` hook stores it.

 The toolkit never stores one.
 `release` takes the allocator as an argument.
 Nothing in the toolkit reads the stored field.

 - Creates a `Holder`, whose `init` stores the allocator.
 - Checks that the `Holder` kept the allocator.
 - Releases it, passing the same allocator.
 - Checks that the `Slot` is empty.
*>
module shc::k_new_in_3tk::the_allocator_in_the_outer;
import mtk;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef THE_ALLOCATOR_IN_THE_OUTER_FAILED;

fn void? the_outer_keeps_what_it_chose_to_keep(Allocator a)
{
    Slot s;
    HOLDER.create(a, &s)!;
    shc::helpers::expect(THE_ALLOCATOR_IN_THE_OUTER_FAILED, s.is_full(), "create filled the Slot")!;

    shc::helpers::expect(THE_ALLOCATOR_IN_THE_OUTER_FAILED, HOLDER.must_look(&s).alloc == a, "the outer's own init hook did not keep the allocator")!;

    HOLDER.release(a, &s);
    shc::helpers::expect(THE_ALLOCATOR_IN_THE_OUTER_FAILED, s.is_empty(), "release freed the outer with the allocator it was given")!;
}
