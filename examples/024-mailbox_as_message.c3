<*
 A mailbox is sent like any other outer, and sending it does not close it.

 - Sends a second mailbox through a carrier mailbox.
 - Receives it back.
 - Checks that the received pointer is the one that was sent.
 - Checks that the received mailbox is still open.
*>
module shc::e_infrastructure::mailbox_as_message;
import mtk;
import mtk::mailbox;
import shc::helpers;
import std::time;

faultdef MAILBOX_AS_MESSAGE_FAILED;

fn void? send_mailbox(Mailbox* to, Mailbox* travelling)
{
    Slot s;
    s.fill(mtk::mailbox::to_inner(travelling));
    to.send(&s)!;
}

fn Mailbox* receive_mailbox(Slot* s) => mtk::mailbox::of(s.peek());

fn void? a_travelling_mailbox_stays_open(Allocator a)
{
    Mailbox* carrier = mtk::mailbox::create(a)!;
    defer { InnerQueue left; carrier.close(&left); carrier.release(); }

    Mailbox* travelling = mtk::mailbox::create(a)!;
    defer { InnerQueue left; travelling.close(&left); travelling.release(); }

    send_mailbox(carrier, travelling)!;

    Slot s;
    carrier.receive(&s, time::ms(1000))!;
    Mailbox* got = receive_mailbox(&s);

    shc::helpers::expect(MAILBOX_AS_MESSAGE_FAILED, got == travelling, "the mailbox that arrives must be the one that was sent")!;
    shc::helpers::expect(MAILBOX_AS_MESSAGE_FAILED, !got.is_closed(), "a mailbox that is travelling is still a working endpoint")!;
}
