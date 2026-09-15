<*
 A wrapper outer carries what a mailbox alone cannot, such as a job id.

 - Creates a `WorkerInbox`.
 - Sets its mailbox and its job id.
 - Sends the `WorkerInbox`.
 - Receives it back.
 - Checks that the mailbox pointer and the job id arrived unchanged.
*>
module shc::e_infrastructure::infrastructure_wrapper;
import mtk;
import mtk::mailbox;
import shc::helpers;
import std::time;

faultdef INFRASTRUCTURE_WRAPPER_FAILED;

alias WORKER_INBOX = helper::OF{WorkerInbox};

struct WorkerInbox
{
    Inner       inner;
    Allocator   alloc;
    Mailbox*    mbx;
    int         job_id;
}

// Both hooks are required.
// The fields are set after `create`, so `init` has nothing to do.
// Nothing is acquired, so `finish` has nothing to free.
fn void? WorkerInbox.init(&self, Allocator a) { return; }
fn void  WorkerInbox.finish(&self, Allocator a) { }

fn void? wrap_and_send(Allocator a, Mailbox* to, Mailbox* inbox, int job_id)
{
    Slot s;
    defer WORKER_INBOX.release(a, &s);
    WORKER_INBOX.create(a, &s)!;

    WorkerInbox* w = WORKER_INBOX.must_look(&s);
    w.mbx = inbox;
    w.job_id = job_id;

    to.send(&s)!;
}

fn void? wrapper_carries_the_job_id(Allocator a, Mailbox* to, Mailbox* inbox)
{
    wrap_and_send(a, to, inbox, 42)!;

    Slot s;
    defer WORKER_INBOX.release(a, &s);
    to.receive(&s, time::ms(1000))!;

    WorkerInbox* w = WORKER_INBOX.must_look(&s);
    shc::helpers::expect(INFRASTRUCTURE_WRAPPER_FAILED, w.mbx == inbox, "the wrapper must carry the same inbox pointer")!;
    shc::helpers::expect(INFRASTRUCTURE_WRAPPER_FAILED, w.job_id == 42, "the wrapper must carry the job id")!;
}
