<*
 The `any` border: `is`, and `look`, `take`, `to_any`, `to_slot` on an `any*`.

 An `any` is a kind of Slot.
 - It is handled by address.
 - It is empty when `.ptr == null`.

 The aborts are negative programs, not tests:
 - `any_wrong_type_must`
 - `any_forged`
 - `any_unstamped`
 - `any_linked`
 - `any_full_target`
*>
module mtk_test;
import mtk;
import std::thread::channel;

<*
 `is` answers for every holder, and `false` is a normal answer.
*>
fn void is_answers_for_every_holder() @test
{
    Slot s;
    defer MSG.release(mem, &s);
    always_assert(!MSG.is(&s), "an empty Slot is not a Msg");
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }

    always_assert(MSG.is(&s), "is on a Slot");
    always_assert(MSG.is(s.peek()), "is on an Inner*");
    always_assert(!TWIN.is(&s), "a Msg is not a Twin");
    always_assert(!MSG.is((Inner*)null), "a null inner is not a Msg");

    any a;
    always_assert(!MSG.is(&a), "an empty any is not a Msg");
    MSG.must_to_any(&s, &a);
    always_assert(MSG.is(&a), "is on an any");
    always_assert(!TWIN.is(&a), "an any of a Msg is not a Twin");
    MSG.must_to_slot(&a, &s);
}

<*
 An io event is not an outer, and passes through untouched.
*>
fn void an_io_event_passes_untouched() @test
{
    int event = 42;
    any a = &event;
    Slot s;

    always_assert(!MSG.is(&a), "an int is not a Msg");
    always_assert(MSG.look(&a) == null, "look on an io event");
    always_assert(MSG.take(&a) == null, "take on an io event");
    always_assert(MSG.to_slot(&a, &s) == null, "to_slot on an io event");
    always_assert(a.ptr == &event && a.type == int::typeid, "the io event was touched");
    always_assert(s.is_empty(), "the Slot was filled");
}

<*
 An `any` of a pointer to the inner is not an outer.
*>
fn void an_any_of_an_inner_is_not_an_outer() @test
{
    Slot s;
    defer MSG.release(mem, &s);
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }

    any a = s.peek();
    always_assert(!MSG.is(&a), "an Inner* in an any was taken for a Msg");
}

<*
 The round trip: Slot → `any` → Slot.
*>
fn void slot_to_any_and_back() @test
{
    Slot s;
    defer MSG.release(mem, &s);
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }
    Msg* m = MSG.must_look(&s);
    m.id = 7;

    any a;
    always_assert(MSG.to_any(&s, &a) == m, "to_any did not give the outer");
    always_assert(s.is_empty(), "to_any did not empty the Slot");
    always_assert(a.ptr == m && a.type == Msg::typeid, "the any does not hold the outer");
    always_assert(MSG.look(&a) == m, "look on the any");
    always_assert(MSG.must_look(&a).id == 7, "must_look on the any");

    always_assert(MSG.to_slot(&a, &s) == m, "to_slot did not give the outer");
    always_assert(a.ptr == null && (void*)a.type == null, "to_slot did not clear both fields");
    always_assert(MSG.must_look(&s) == m, "the Slot does not hold the outer");
}

<*
 A plain form on a wrong type returns `null` and leaves both holders untouched.
*>
fn void a_plain_mismatch_leaves_both_untouched() @test
{
    Slot s;
    defer MSG.release(mem, &s);
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }
    Inner* inner = s.peek();

    any a;
    always_assert(TWIN.to_any(&s, &a) == null, "to_any crossed a Msg as a Twin");
    always_assert(s.peek() == inner && a.ptr == null, "a refused to_any moved something");

    Slot empty;
    always_assert(MSG.to_any(&empty, &a) == null, "to_any from an empty Slot");

    MSG.must_to_any(&s, &a);
    Slot t;
    always_assert(TWIN.to_slot(&a, &t) == null, "to_slot crossed a Msg as a Twin");
    always_assert(TWIN.take(&a) == null, "take crossed a Msg as a Twin");
    always_assert(a.ptr != null && t.is_empty(), "a refused to_slot moved something");
    MSG.must_to_slot(&a, &s);
}

<*
 `take` and `must_take` on an `any` clear both fields.
*>
fn void take_clears_the_any() @test
{
    Slot s;
    defer MSG.release(mem, &s);
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }
    Msg* m = MSG.must_look(&s);

    any a;
    MSG.must_to_any(&s, &a);
    always_assert(MSG.take(&a) == m, "take on the any");
    always_assert(a.ptr == null && (void*)a.type == null, "take did not clear both fields");

    a = m;
    always_assert(MSG.must_take(&a) == m, "must_take on the any");
    always_assert(a.ptr == null && (void*)a.type == null, "must_take did not clear both fields");

    s.fill(MSG.inner(m));
}

<*
 A stale `.type` in an empty `any` is harmless.
 - Getting sees an empty holder.
 - Putting writes both fields.
*>
fn void a_stale_type_is_harmless() @test
{
    Slot s;
    defer MSG.release(mem, &s);
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }

    any a = any_make(null, Msg::typeid);
    always_assert(!MSG.is(&a), "an any with a null .ptr is not empty");
    always_assert(MSG.look(&a) == null, "look on a stale any");

    a = any_make(null, Twin::typeid);
    Msg* m = MSG.must_to_any(&s, &a);
    always_assert(a.ptr == m && a.type == Msg::typeid, "to_any did not write both fields");
    MSG.must_to_slot(&a, &s);
}

<*
 The shape in use, over `UnboundedChannel(<any>)`, on one thread.
 - The sender: Slot → `any`, then `push`.
 - The receiver: `pop`, `is`, then `any` → Slot.
 - An io event on the same channel is the user's.
*>
fn void the_shape_over_a_channel() @test
{
    UnboundedChannel{any}* ch = channel::create_unbounded{any}(mem)!!;
    defer ch.destroy();

    Slot sent;
    defer MSG.release(mem, &sent);
    if (catch MSG.create(mem, &sent)) { always_assert(false, "create failed"); }
    Msg* m = MSG.must_look(&sent);

    int event = 1;
    ch.push(&event)!!;

    any out;
    MSG.must_to_any(&sent, &out);
    if (catch ch.push(out)) MSG.must_to_slot(&out, &sent);

    int outers;
    int events;
    for (int i = 0; i < 2; i++)
    {
        any a = ch.pop()!!;
        if (MSG.is(&a))
        {
            Slot s;
            always_assert(MSG.must_to_slot(&a, &s) == m, "the outer that arrived is not the one sent");
            sent.fill(s.take());
            outers++;
            continue;
        }
        events++;
    }
    always_assert(outers == 1 && events == 1, "the channel did not give one of each");
}

<*
 A failed `push` puts the outer back into its Slot.
*>
fn void a_failed_push_goes_back_to_the_slot() @test
{
    UnboundedChannel{any}* ch = channel::create_unbounded{any}(mem)!!;
    defer ch.destroy();
    ch.close();

    Slot s;
    defer MSG.release(mem, &s);
    if (catch MSG.create(mem, &s)) { always_assert(false, "create failed"); }

    any a;
    MSG.must_to_any(&s, &a);
    bool refused;
    if (catch ch.push(a)) { MSG.must_to_slot(&a, &s); refused = true; }
    always_assert(refused, "a closed channel took the push");
    always_assert(s.is_full() && a.ptr == null, "the outer did not go back to its Slot");
}

import std::core::mem::alloc;
