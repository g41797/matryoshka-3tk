<*
 `send`'s `limit` bounds how many outers of the same typeid may already be
 queued. `limit == 0`, the default, is the unbounded call every other example
 uses.

 - Send two `Holder`s with `limit = 1` and see the second refused with
   `LIMIT`, the Slot still full.
*>
module shc::f_mailbox::send_with_limit;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;

alias HOLDER = helper::OF{Holder};

faultdef SEND_WITH_LIMIT_FAILED;

fn void? one_over_the_limit(Allocator a, Mailbox* mb)
{
    Slot first;
    HOLDER.create(a, &first)!;
    mb.send(&first, 1)!;

    Slot second;
    HOLDER.create(a, &second)!;
    if (catch f = mb.send(&second, 1))
    {
        shc::helpers::expect(SEND_WITH_LIMIT_FAILED, f == mtk::LIMIT, "a full limit refuses with LIMIT")!;
    }
    else
    {
        return SEND_WITH_LIMIT_FAILED~;
    }
    shc::helpers::expect(SEND_WITH_LIMIT_FAILED, second.is_full(), "a refused send emptied the Slot")!;
    HOLDER.release(a, &second);

    Slot got;
    mb.poll(&got)!;
    HOLDER.release(a, &got);
}
