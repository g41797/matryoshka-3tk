<*
 The helper's crossings, and the methods they forward to.

 `HOLDER.look`, `must_look`, `take` and `must_take` are the forms to use.
 A `must_` form aborts on a mismatch.
 A plain form returns `null` on a mismatch.
 `take` empties the `Slot`.
 `look` leaves the `Slot` full.
 The `Inner` and `Slot` methods are the layer beneath, shown once.

 - Crosses an `Inner*` with `look` and with `Inner.to`.
 - Crosses an `Inner*` with `must_look` and with `Inner.as`.
 - Crosses a `Slot` with `look` and with `Slot.to`.
 - Checks that the `Slot` is still full.
 - Takes from the `Slot` with `take`.
 - Checks that the `Slot` is empty.
 - Refills the `Slot` for the deferred release.
*>
module shc::c_crossing::recovering_the_type;
import mtk;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef RECOVERING_THE_TYPE_FAILED;

fn void? recover_four_ways(Allocator a)
{
    Slot s;
    defer HOLDER.release(a, &s);
    HOLDER.create(a, &s)!;
    Inner* inner = s.peek();

    Holder* checked = HOLDER.look(inner);
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, checked != null, "look() did not find the Holder")!;
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, inner.to(Holder) == checked, "Inner.to() should match look()")!;

    Holder* asserted = HOLDER.must_look(inner);
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, asserted == checked, "must_look() should match look()")!;
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, inner.as(Holder) == checked, "Inner.as() should match must_look()")!;

    Holder* peeked = HOLDER.look(&s);
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, peeked == checked, "look() on a Slot should match look() on an inner")!;
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, s.to(Holder) == checked, "Slot.to() should match look()")!;
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, s.is_full(), "look() must leave the Slot full")!;

    Holder* taken = HOLDER.take(&s);
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, taken == checked, "take() should match look()")!;
    shc::helpers::expect(RECOVERING_THE_TYPE_FAILED, s.is_empty(), "take() must leave the Slot empty")!;

    s.fill(inner);
}
