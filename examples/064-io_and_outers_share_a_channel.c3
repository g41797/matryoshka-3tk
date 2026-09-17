<*
 The io side tells its own events from outers, on one channel.

 The io side has no mailbox.
 It listens on an `UnboundedChannel{any}`.
 Its own io events and the outers a worker sends back arrive there together.

 - Creates the channel and starts a worker on the work mailbox.
 - Pushes three io events onto the channel, as an io layer would.
 - Pops each `any`, and asks `is` what it is.
 - An io event: creates an `Event` for it and sends it to the worker.
 - An outer: takes it back with `must_to_slot`, reads the answer and releases it.
 - The worker answers each `Event` and pushes it back as an `any`.
 - Closes the work mailbox and joins the worker.
 - Checks that every io event got its answer.

 ```
   io layer ───── io event as any ─────┐
                                       ▼
                               channel of any
                                       │
                                       ▼
                                    io side ───── Event in a Slot ─────► work mailbox
                                       ▲                                     │
                                       │                                     ▼
                                       └───────── Event as any ───────── worker
 ```
*>
module shc::l_bridge::io_and_outers_share_a_channel;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::thread;
import std::thread::channel;
import std::time;

alias EVENT = helper::OF{Event};

faultdef IO_AND_OUTERS_SHARE_A_CHANNEL_FAILED;

alias AnyChannel = UnboundedChannel{any};

struct IoEvent
{
    int request;
}

struct WorkerArgs
{
    AnyChannel* ch;
    Mailbox* work;
    Allocator a;
}

fn void? io_side_serves_both_kinds(Allocator a, Mailbox* work)
{
    AnyChannel* ch = channel::create_unbounded{any}(a)!;
    defer ch.destroy();

    WorkerArgs wargs = { .ch = ch, .work = work, .a = a };
    Thread worker;
    worker.create(&answer_until_closed, &wargs)!!;

    IoEvent[3] events = { { 1 }, { 2 }, { 3 } };
    foreach (&ev : events) ch.push(ev)!;

    int answers = serve(a, ch, work, events.len)!;

    stop_worker(a, work);
    worker.join()!!;

    shc::helpers::expect(IO_AND_OUTERS_SHARE_A_CHANNEL_FAILED, answers == 10 + 20 + 30, "every io event got its answer")!;
}

fn int? serve(Allocator a, AnyChannel* ch, Mailbox* work, usz expected)
{
    int answers = 0;
    usz answered = 0;
    while (answered < expected)
    {
        any got = ch.pop()!;
        if (EVENT.is(&got))
        {
            answers += take_the_answer(a, &got);
            answered++;
            continue;
        }
        if (got.type == IoEvent::typeid)
        {
            send_to_the_worker(a, (IoEvent*)got.ptr, work)!;
            continue;
        }
        unreachable("the io side met an any it was not written for");
    }
    return answers;
}

fn void? send_to_the_worker(Allocator a, IoEvent* ev, Mailbox* work)
{
    Slot s;
    defer EVENT.release(a, &s);
    EVENT.create(a, &s)!;
    EVENT.must_look(&s).code = ev.request;
    work.send(&s)!;
}

fn int take_the_answer(Allocator a, any* got)
{
    Slot s;
    defer EVENT.release(a, &s);
    return EVENT.must_to_slot(got, &s).code;
}

fn int answer_until_closed(void* arg)
{
    WorkerArgs* args = (WorkerArgs*)arg;
    while (true)
    {
        Slot s;
        defer EVENT.release(args.a, &s);
        if (catch f = args.work.receive(&s, time::ms(2000)))
        {
            if (f == mtk::CLOSED) return 0;
            continue;
        }
        EVENT.must_look(&s).code *= 10;
        send_back(args.ch, &s);
    }
}

fn void send_back(AnyChannel* ch, Slot* s)
{
    any out;
    EVENT.must_to_any(s, &out);
    if (catch ch.push(out)) EVENT.must_to_slot(&out, s);
}

fn void stop_worker(Allocator a, Mailbox* work)
{
    InnerQueue left;
    work.close(&left);
    while (Inner* inner = left.pop_front())
    {
        Slot s;
        s.fill(inner);
        EVENT.release(a, &s);
    }
}
