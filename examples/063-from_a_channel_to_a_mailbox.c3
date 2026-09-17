<*
 Outers cross from a channel of `any` into a mailbox.

 - Creates an `UnboundedChannel{any}`.
 - Starts a C3 thread that makes three `Event`s and pushes each as an `any`.
 - Pops every `any` until the channel is closed and empty.
 - Moves each into a `Slot` with `must_to_slot` and sends it to the mailbox.
 - Receives everything from the mailbox and releases each outer.
 - Checks that all three codes arrived.
*>
module shc::l_bridge::from_a_channel_to_a_mailbox;
import mtk;
import mtk::mailbox;
import shc::outers;
import shc::helpers;
import std::thread;
import std::thread::channel;

alias EVENT = helper::OF{Event};

faultdef FROM_A_CHANNEL_TO_A_MAILBOX_FAILED;

alias AnyChannel = UnboundedChannel{any};

struct ProducerArgs
{
    AnyChannel* ch;
    Allocator a;
}

fn void? outers_cross_from_a_channel_to_a_mailbox(Allocator a, Mailbox* mbx)
{
    AnyChannel* ch = channel::create_unbounded{any}(a)!;
    defer ch.destroy();

    ProducerArgs pargs = { .ch = ch, .a = a };
    Thread producer;
    producer.create(&push_three_events, &pargs)!!;

    int forwarded = forward_until_closed(a, ch, mbx);
    producer.join()!!;

    int codes = receive_and_release(a, mbx)!;

    shc::helpers::expect(FROM_A_CHANNEL_TO_A_MAILBOX_FAILED, forwarded == 3, "three outers came off the channel")!;
    shc::helpers::expect(FROM_A_CHANNEL_TO_A_MAILBOX_FAILED, codes == 1 + 2 + 3, "every code reached the mailbox")!;
}

fn int push_three_events(void* arg)
{
    ProducerArgs* args = (ProducerArgs*)arg;
    defer args.ch.close();
    for (int code = 1; code <= 3; code++)
    {
        Slot s;
        defer EVENT.release(args.a, &s);
        if (catch EVENT.create(args.a, &s)) return 0;
        EVENT.must_look(&s).code = code;
        push_as_any(args.ch, &s);
    }
    return 0;
}

fn void push_as_any(AnyChannel* ch, Slot* s)
{
    any out;
    EVENT.must_to_any(s, &out);
    if (catch ch.push(out)) EVENT.must_to_slot(&out, s);
}

fn int forward_until_closed(Allocator a, AnyChannel* ch, Mailbox* mbx)
{
    int forwarded = 0;
    while (true)
    {
        any? got = ch.pop();
        if (catch got) return forwarded;
        any in = got;
        Slot s;
        defer EVENT.release(a, &s);
        EVENT.must_to_slot(&in, &s);
        if (catch mbx.send(&s)) continue;
        forwarded++;
    }
}

fn int? receive_and_release(Allocator a, Mailbox* mbx)
{
    InnerQueue batch;
    mbx.receive_all(&batch)!;

    int codes = 0;
    while (Inner* inner = batch.pop_front())
    {
        Slot s;
        s.fill(inner);
        codes += EVENT.must_look(&s).code;
        EVENT.release(a, &s);
    }
    return codes;
}
