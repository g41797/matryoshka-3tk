![](resources/m3tk-logo.png)

---

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/matryoshka-3tk/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/matryoshka-3tk/actions/workflows/linux.yml)
[![Sanitizers](https://github.com/g41797/matryoshka-3tk/actions/workflows/sanitizers.yml/badge.svg)](https://github.com/g41797/matryoshka-3tk/actions/workflows/sanitizers.yml)
[![Docs](https://github.com/g41797/matryoshka-3tk/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/matryoshka-3tk/actions/workflows/docs.yml)

---

A small C3 toolkit.

- 800+ lines of code.
- 600+ lines on this page, explaining them.

You can read all of it in an evening. The code, and the reasons for it.

It is for one part of a background process.

- Not the I/O part.
- The part that works with your data.

---

This page:

- starts with a process you have probably built
- then looks at the everyday problems that process runs into
- brings in the toolkit only when a problem needs it

---


## A process you have probably built

---


A background process often starts with something simple.

Several threads work together.

Each thread has a responsibility:

- one part receives requests
- another does the actual work
- another sends results back

```text
   clients            the I/O part                 the process part

   client 1 ---->  handler 1 ---\
   client 2 ---->  handler 2 ----\
                                  >---- shared queue ----> worker A
   client 3 ---->  handler 3 ----/                    \--> worker B
   client 4 ---->  handler 4 ---/
```

The I/O side deals with:

- sockets
- parsing
- timeouts
- and the rest of it


The process side deals with your data:

- `Customer`
- `Order`
- `Invoice`
- `Payment`
- whatever your application needs

The process side should not care how a request arrived:

- over TCP
- or from a file

The two sides:

- need to work together
- should not need to know much about each other

Starting the threads is usually not the hard part.

The hard part is everything that happens between the threads.

That is where the boring problems start...



---

## Threads need to exchange work

---


A handler and a worker run on different threads.

- The handler turns an incoming request into an application struct.
- The worker processes it.
- The result has to get back.

Neither can do the other's job.

So we need a way to pass work between threads.

```text
   handler 1 ---\                              /---> worker A
   handler 2 ----+---> requests queue ---------+
   handler 3 ---/                              \---> worker B

   handler 1 <--\                              /---- worker A
   handler 2 <---+---- replies queue ----------+
   handler 3 <--/                              \---- worker B
```


---

## The queue is at the centre

---


- Every request crosses it.
- Every reply crosses back.

So sooner or later, every hard question in the process becomes a question
about the queue.

- **A worker waits for work.**
    - For how long?
    - What stops the wait?
- **The process shuts down.**
    - Requests are still queued. Who frees them?
    - How do you stop without losing track of work that is still on its way?
- **A handler is too fast.**
    - How many requests may it queue before it must stop?
- **A cancel arrives.**
    - It should not wait behind a hundred requests.

A queue written in an afternoon rarely answers these.

Each answer added later is one more thing to get right.


---

## Moving work should not allocate

---


This is where a normal queue can become surprisingly expensive.

The request already exists.

The handler built it.

There is usually no reason to create another copy of it just to put it into a
queue.

A typical queue stores a copy of whatever you push:

- it allocates room for the copy
- it grows its buffer when it is full

Count the pushes:

- every request is pushed once
- every reply is pushed once

That is an allocation at every crossing.

And it is on the busiest path of the process.

A request should not be copied just because it moved from one thread to
another.


---

## The queue should not know your types

---


The queue is infrastructure.

It is written once.

Today it may carry:

- `CreateOrder`
- `PayInvoice`

Tomorrow it may carry:

- `CancelOrder`
- `SendEmail`
- `Shutdown`

Changing the application should not mean changing the queue.

The usual workarounds, and what each one costs:

- **A `void*`.**
    - The type is gone.
    - The cast back is a guess.
- **An enum tag plus a union of every message.**
    - The queue changes with every feature.
- **An interface with virtual calls.**
    - Every message needs a vtable.
    - The queue still stores something it cannot name.

What the worker needs is simple:

- **ask what arrived**
- **get a checked answer**


---

## Some structs should not be copied

---


Consider a request that contains a large buffer.

Or other structs:

- a struct that contains a mutex
- a struct that keeps an OS resource, such as a file handle
- a struct with pointers that point into the struct itself
- a struct whose address has already been given to another part of the process

Some structs simply should not be copied.

A copy is a different struct at a different address.

The useful thing to move is their address.

```text
        +-------------------+
        | Request           |
        |                   |
        | application data  |
        +-------------------+
                 ^
                 |
              address
                 |
        +--------+--------+
        |      queue      |
        +-----------------+
```

So the request stays where it is.

**Only its address moves.**

And moving that address should still not allocate.


---

## Where requests come from

---


Now look at the handler again.

```text
   client connects
         |
         v
   handler allocates a request
         |
         v
   request goes to a worker, the reply comes back
         |
         v
   handler frees the request
         |
         v
   next client: allocate again
```

One allocation and one free per client.

Thousands per second:

- the same struct
- the same size
- every time

Often we can do better.

Keep freed requests and reuse them.

That raises a new question:

- **Kept where?**
- **Shared by which threads?**


---

## Reuse needs rules

---


Keeping a request is not enough.

- **It still contains the previous client's data.**
    - Someone must clear it.
- **A load spike leaves thousands of them kept.**
    - How many should stay?
- **None are free.**
    - Make a new one, wait for one, or refuse?
- **Different types want different answers.**
    - A small request and a large buffer are not kept the same way.
- **The process stops.**
    - Everything still kept must be freed.

These are decisions about your types.

The code that keeps them:

- should provide the mechanism
- should not invent the policy


---

## The same process, with this toolkit

---


- Same handlers.
- Same workers.
- Same threads, created by your process.

What changes is the line between them.

**The idea in one sentence:**

- the process passes around pointers to structs that already exist
- the code in the middle does not need to know what those structs are

The sections below answer the problems above, in the same order.


---

## A queue that answers the hard questions

---


The shared queue becomes a **mailbox**.

- **A wait has an end.**
    - `receive` takes a timeout.
    - It fails with `CLOSED`, `TIMEOUT` or `WOKEN`, and nothing else.
- **A wait can be stopped.**
    - `wake_all` returns every waiter with `WOKEN`.
- **Shutdown loses nothing.**
    - `close` gives back everything still queued.
    - You release it by your own rules.
    - Nothing leaks.
- **A fast handler hits a limit.**
    - `send` with a limit fails with `LIMIT`.
    - It fails once that many requests of its type are queued.
- **Urgent work goes first.**
    - `send_oob` puts it at the front.
- **A batch arrives in one call.**
    - `receive_all`.

A mailbox is made by its own call, not by your helper.

- `mailbox::create` takes your allocator.
- `release` gives the memory back.


---

## The request carries its own link

---


The problem is a queue that allocates a node per push.

So the link lives inside the request.

That is what *intrusive* means.

```text
   mailbox
      |
      v
   +- Request 1 -------------------+
   |  client_id   path             |
   |  [ inner | link ]---+         |
   +---------------------|---------+
                         |
                         v
   +- Request 2 -------------------+
   |  client_id   path             |
   |  [ inner | link ]---+         |
   +---------------------|---------+
                         |
                         v
   +- Request 3 -------------------+
   |  client_id   path             |
   |  [ inner | link: itself ]     |   the last one links to itself
   +-------------------------------+
```

- Sending links the request in.
    - Nothing is allocated.
- Receiving unlinks it.
    - Nothing is freed.
- The request never moves.
    - Only its address travels.


---

## The request carries its own type

---


The link lives in a small embedded part, the **inner**.

The application struct around it is the **outer**.

Your `Request` is an outer.

```text
   Outer: Request
   +---------------------------+
   | client_id                 |
   | path                      |
   |                           |
   | +-----------------------+ |
   | | Inner                 | |
   | |   link                | |
   | |   otrtypeid           | |
   | +-----------------------+ |
   +---------------------------+
```

The inner has two fields:

- `link` — the next inner in the chain
- `otrtypeid` — the type of the struct it sits in

That second field is written once, when the struct is made.

- The toolkit writes it. You do not.
- It stays there for as long as the struct exists.
- So the struct always knows what type it is, even after it has been passed
  around as a plain `Inner*`.

The mailbox only sees an `Inner*`.

It never learns what a `Request` is.

When the worker needs its type back, it asks and gets a checked answer.

```text
              Inner*
                 |
                 v
          check otrtypeid
                 |
          +------+------+
          |             |
       Request*        null
```

- `look` returns the outer.
    - Or null, if it is not the type asked for.
- `must_look` aborts on a mismatch.
- An outer whose type was never written is refused.
    - It is not guessed at.


---

## One struct, two addresses

---


Think of the crossing as a cast that the helper makes safe.

Your `Request` and the inner inside it are at two different addresses.

```text
   one Request in memory
   +-------------+---------------+---------------------------+
   |  client_id  |     path      |           Inner           |
   +-------------+---------------+---------------------------+
   ^                             ^
   |                             |
   |                             +-- Inner*
   |                                 this address travels
   |                                 the mailbox and the pool see only this
   |
   +-- Request*
       this address your code works with
```

A plain cast keeps the address and reads it as another type.

The helper does two things a cast cannot.

- It moves the address, from the inner back to the start of your struct.
- It checks the type before it gives it to you.

So the crossing back is one call.

- `look` gives you your `Request*`, or `null` if it is not one.
- `must_look` aborts instead of returning `null`.

**And you never work out the distance yourself.**

- Move `inner` to another place in the struct and the distance changes.
- Your code does not.
- A cast you wrote by hand would be wrong from that moment on.

The rest of this page says a request is in the slot.

What is in the slot is the inner inside that request.

Both are true. The helper is what turns one into the other.


---

## The one struct you write

---


```c3
struct Request
{
    int   client_id;
    char[256] path;
    Inner inner;
}
```

The `Inner` can sit anywhere in the struct.

- First, last, or in the middle.
- Here it is last, and nothing about that is special.

**The Request's address is computed from the inner's.**

- The offset of `inner` in `Request` is known at compile time.
- So nothing has to be stored to find the way back:
    - no back-pointer
    - no registry
    - no map
- Exactly one `Inner` per struct of yours, as a direct field of the struct.
    - The check runs when the toolkit first uses the struct as an outer.
    - Zero or two is a compile error at that point.
    - Declaring such a struct alone is not an error.

Two methods go with it:

```c3
fn void? Request.init(&self, Allocator a)   {}   // set up, or nothing
fn void  Request.finish(&self, Allocator a) {}   // clean up, or nothing
```

- Both are required.
- An empty body is fine.
    - It means there is nothing to do when the struct is created or released.
- The compiler checks that they are there.


---

## One helper per type does the boring part

---


There is nothing to be afraid of here.

- You never work out that distance yourself.
- You never write the type into the struct yourself.

One line makes a helper for your type.

```c3
alias REQ = helper::OF{Request};

Slot slot;
REQ.create(a, &slot)!;             // allocate, init, write the type, fill the slot
Request* req = REQ.look(&slot);    // the outer back, type checked
REQ.release(a, &slot);             // finish, empty the slot, free
```

```text
   create:   allocate --> init --> write the type --> fill the slot
                                                          |
                                                         use
                                                          |
   release:  free <-- empty the slot <-- finish <---------+
```

- `create` frees the outer if `init` fails.
- `release` on an empty slot does nothing.
    - That keeps cleanup paths simple.
- `create` calls your `init`, `release` calls your `finish`.
- Reading the outer back:
    - `look` and `must_look` read.
    - `take` and `must_take` read and empty the slot.

**`create` is not the only way in.**

You may allocate the struct yourself — from your own allocator, or as a field of
something bigger you already have.

Then write the type into it once:

```c3
Request* req = my_own_allocation();
REQ.stamp(req);                // write the type into its inner, once
```

- Do it once per struct, before it is used anywhere.
- From then on the mailbox and the pool take it like any other request.
- `create` is the same three steps done for you: allocate, call `init`, write
  the type.

**Two questions stay apart.**

- Where does this struct come from, and when does it go away?
- How does it get from this thread to the next one?

The helper and the pool answer the first. The mailbox answers the second.

- Change how your structs are made, and the sending code is untouched.
- Send them some other way, and the making code is untouched.


---

## Only the address moves

---


Once an address is passed between threads, a small but important question
appears.

**Who has it now?**

An address kept in two places is a request two threads can both touch.

A **slot** makes the answer visible.

A slot contains one `Inner*`, or nothing.

- `send` takes the address from your slot.
    - The slot is empty afterwards.
- `receive` fills an empty slot.
    - Passing a full one is a checked error.
- **The empty slot proves the request went somewhere else.**

In plain words:

- **if a pointer is in your slot, this part of the program has it right now**
- **if the slot is empty, it does not**

```text
   handler thread                          worker thread

   slot: [ Request 1 ]                     slot: [ empty ]
        |                                        ^
        |  send                         receive  |
        |  empties this slot   fills that slot   |
        v                                        |
   slot: [ empty ]  ----->  mailbox  ------------+
```

The slot also makes cleanup simple.

You can set up the cleanup first, before you create or receive anything.

```c3
Slot slot;
defer REQ.release(a, &slot);   // runs on every way out of the function

REQ.create(a, &slot)!;         // if this fails, the slot stays empty
// ... fill in the request ...
mbox.send(&slot)!;             // if this succeeds, the slot is now empty
```

- If `create` fails:
    - the slot is empty
    - `release` does nothing
- If `send` fails:
    - the request is still in the slot
    - `release` frees it
- If `send` succeeds:
    - the slot is empty
    - `release` does nothing

Every path out of the function is covered by one line.

- Nothing is freed twice.
- Nothing is forgotten.


---

## Requests come from a pool

---


A **pool** keeps used structs and gives them out again.

```text
        +------+
        | pool | <---------------------+
        +--+---+                       |
           |  get                      |  put
           v                           |
        Request ------->  work  -------> Request
```

- Threads share it.
    - It does its own locking.
- It works with `Inner*`.
    - It does not depend on your outer types.
- It keeps each type separate.
    - The set of types is fixed when the pool is created.
- `get` returns a kept outer or a new one.
- `put` gives one back.

`get` takes a mode.

*None are free* can be answered in more than one way:

- `AVAILABLE_OR_NEW` — a kept one if there is one, otherwise a new one
- `NEW_ONLY` — always a new one
- `AVAILABLE_ONLY` — a kept one, or it fails with `NOT_AVAILABLE`

`get_wait` waits, with a timeout, for a kept one.

A pool is made by its own call too.

- `pool::create` takes your allocator, the types it will keep, and your hooks.
- `release` gives the memory back.


---

## The rules of reuse are yours

---


The pool makes no decisions about your types.

It calls **hooks** you write:

- `on_get` — none are free.
    - Create a new outer.
    - Or leave the slot empty.
- `on_put` — an outer came back.
    - To keep it, clear it and leave it in the slot.
    - To drop it, free it.
- `on_close` — the pool is closing.
    - Everything still kept is passed to you.

The pool manages the collection.

Your code decides what reuse means for your structs.


---

## Putting the pieces together

---


There is not much to the model.

We started with an ordinary background process.

The problems were ordinary ones:

- Threads need to exchange work.
- Transfer should not allocate on the normal path.
- The queue should not depend on application types.
- Some structs should not be copied.
- Repeated allocation and release can be wasteful.
- Reuse needs application rules.
- Shutdown needs a clear way to deal with what is still queued or kept.

```text
                         your application

   +------------------------------------------------+
   |                                                |
   |   Request       Order       Payment            |
   |      |            |            |               |
   |      +------------+------------+               |
   |                   |                            |
   |            each has an Inner                   |
   |                   |                            |
   +-------------------+----------------------------+
                       |
                    Inner*
                       |
              +--------+--------+
              |                 |
              v                 v
           Mailbox            Pool
              |                 |
              v                 v
       between threads        reuse
```

Your application still defines the process.

The toolkit stays on the line in the middle.

That is all it needs to be.


---

## You do not have to use everything

---


The three pieces are independent.

```text
   Inner + Outer      your struct carries its own type, and a link
   Mailbox            moves structs between threads
   Pool + your hooks  keeps used structs, by your rules
```

**The mailbox and the pool know nothing about each other.**

- Neither one needs the other.
- Use both, or one, or neither.

Inner and outer alone are already worth something.

- `InnerQueue` chains your structs and allocates nothing.
    - The link is already in them.
- Any C3 container carries a pointer to your struct instead.
    - The container allocates for its own node.
    - Your struct is still never copied.
- Either way, the type comes back checked.

Use the part that solves your actual problem.


---

## Matryoshka

---


Now the model gets its name.

An **outer** contains an **inner**, the way a Russian doll contains a smaller doll.

Why the name:

- **The first reason: you can use any doll you want.**
    - Any struct of yours can be an outer.
- **But the main reason: it is funny.**

The names, and what each one is for:

- **Inner** — the small part inside your struct.
    - It keeps the link and the type.
    - So the mailbox and the pool never need to know your struct.
- **Outer** — your struct.
    - Your data, plus one `Inner`.
- **Helper** — one per outer type.
    - It creates, releases and checks the type for you.
- **Slot** — one address, or none.
    - It shows who has a struct right now.
    - It makes cleanup simple.
- **Mailbox** — moves outers between threads.
    - Without copying.
    - Without allocating.
- **Pool** — keeps used outers so they can be used again.
- **Hooks** — your code that the pool calls.
    - You decide what reuse means for your structs.

Six modules:

- `mtk`
- `mtk::inner`
- `mtk::helper`
- `mtk::mailbox`
- `mtk::pool`
- `mtk::queue`

An operation that fails, fails with one of eight faults declared in `mtk`.

Each module's page has the details this page leaves out.


---

## What this toolkit does not do

---


It is not a process framework.

- No networking.
- No file I/O.
- No event loop.
- No scheduler.
- No fibers or cooperative tasks.
- No thread creation.

Your process decides:

- how its threads are created
- what each one does

The toolkit provides the transfer and reuse pieces between them.

Use it together with whatever your process already uses for those jobs.


---

## Show cases

---


`shc` is the show cases module.

Each show case:

- is small
- shows exactly one idiom, pattern or use case
- says up front what it shows, and the steps it takes
- works, and the tests call it
- uses no testing functions

The show cases are grouped by subject.


---

## How to start

---


You are about to build a background process in C3.

It may be one of the first ever.

Be a little proud of that.

If this kind of process is new to you, do not start with the whole toolkit.

Go step by step.

1. **One thread, one struct.**
    - Put an `Inner` in your struct.
    - Create and release it through its helper.
    - Chain a few in an `InnerQueue`.
    - Iterate over them with `iter`.
    - Take them out.
2. **Add a thread.**
    - Send your outers over C3's `UnboundedChannel(<any>)`.
    - Before `push`, `to_any` moves the outer from its slot into an `any`.
    - After `pop`, `to_slot` moves it back into a slot.
        - It checks what arrived.
    - `shc::l_bridge::from_a_channel_to_a_mailbox` shows it.
3. **Add a pool.**
    - Do it when repeated allocation becomes a problem.
    - Write the three hooks.
    - Decide what to clear and what to keep.
4. **Replace the channel with a mailbox.**
    - Do it when the channel stops being enough.

### What the mailbox adds to a channel

- **No allocation on transfer.**
    - The channel copies into a buffer it grows.
- **`close` gives back what was queued.**
    - The channel's `close` leaves it in the queue.
- And more:
    - timeouts
    - `wake_all`
    - sending to the front
    - a per-type limit
    - batches
    - every outer type in one queue

If your channel already does what you need, keep it.


---

## When to stop

---



At any step you can stop and say:

**enough, I have what my system needs.**

That is completely fine.

Every step stands on its own.

You do not need to solve every problem on the first day.


---

## The Matryoshka family

---


This doll is not the first one.

It is the third.

- **Odin — [matryoshka-otk](https://github.com/g41797/matryoshka-otk)**
    - The first.
    - It started as a port of a Zig project, [mailbox](https://github.com/g41797/mailbox), to Odin.
    - It did not stay a port for long.
- **Zig — [matryoshka-ztk](https://github.com/g41797/matryoshka-ztk)**
    - The second.
    - Still in progress.
- **C3 — this one**
    - A redesign of the Zig version.

Different languages.

The same ideas:

- The link lives inside your struct.
- The type is erased on the way in, and checked on the way back.
- Infrastructure stays out of your application logic.
- Small enough to read.
- Made for boring systems.

Odin, Zig, C3.

Three languages, each trying to be a **better C**.

All three are mature enough to run a real background process today.

The dolls are on the shelf.

**The next move is yours.**
