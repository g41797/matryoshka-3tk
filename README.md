![](resources/m3tk-logo.png)

---

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/matryoshka-3tk/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/matryoshka-3tk/actions/workflows/linux.yml)
[![Sanitizers](https://github.com/g41797/matryoshka-3tk/actions/workflows/sanitizers.yml/badge.svg)](https://github.com/g41797/matryoshka-3tk/actions/workflows/sanitizers.yml)
[![Docs](https://github.com/g41797/matryoshka-3tk/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/matryoshka-3tk/actions/workflows/docs.yml)

A small C3 toolkit for the part of a background process that is not I/O.

This page starts with a process you have probably built.

Then it names the problems that process runs into.

The toolkit comes after that.

## A process you have already built

Clients connect.

Handlers read what they send.

Workers do the business: an order is created, an invoice is paid.

```text
   clients            the I/O part                 the process part

   client 1 ---->  handler 1 ---\
   client 2 ---->  handler 2 ----\
                                  >---- shared queue ----> worker A
   client 3 ---->  handler 3 ----/                    \--> worker B
   client 4 ---->  handler 4 ---/
```

The left side is infrastructure.

- Sockets, parsing, timeouts.
- A library usually does it.

The right side is yours.

- `Customer`, `Order`, `Invoice`, `Payment`.
- It should not care whether a request came over TCP or from a file.

This toolkit lives on the line between the two sides. Nowhere else.

**It does not ship a server.**

- No sockets.
- No files.
- No event loop.
- No scheduler.
- No thread creation. Your process makes its own threads.

## Threads with work to pass on

A handler and a worker run on different threads.

Each has one job.

- The handler turns bytes into a request.
- The worker turns a request into a result.

Neither can do the other's job. So work has to go from one to the other.

The answer comes back the same way.

```text
   handler 1 ---\                              /---> worker A
   handler 2 ----+---> requests queue ---------+
   handler 3 ---/                              \---> worker B

   handler 1 <--\                              /---- worker A
   handler 2 <---+---- replies queue ----------+
   handler 3 <--/                              \---- worker B
```

## The queue is the centre

Every request crosses it. Every reply crosses back.

So every hard question in the process is a question about the queue.

- **A worker waits for work.** For how long? What stops the wait?
- **The process shuts down.** Requests are still queued. Who frees them?
- **A handler is too fast.** How many requests may it queue before it stops?
- **A cancel arrives.** It should not wait behind a hundred requests.

A queue written in an afternoon answers none of these.

Each answer, added later, is a new place to get wrong.

## Moving work should not allocate

A common queue stores a copy of what you push.

- It allocates room for the copy.
- It grows its buffer when it is full.

Every request is pushed once. Every reply is pushed once.

That is an allocation on each crossing, in the busiest path of the process.

## The queue must not know your types

The queue is infrastructure. It is written once.

It carries many kinds of work.

- `CreateOrder`
- `PayInvoice`
- `Shutdown`

It cannot import them. The next feature adds one more.

The usual ways out, and what each costs.

- **A `void*`.** The type is gone. The cast back is a guess.
- **A tagged union of every message.** The queue changes with every feature.
- **An interface with virtual calls.** Every message needs a vtable.
  The queue still stores something it cannot name.

What the worker needs is simple. **Ask what arrived, and get a checked answer.**

## Some structs cannot be copied

A request can be large. It can keep a buffer.

Some structs must never be copied at all.

- One that contains a mutex.
- One whose address was already given to someone else.

A copy is a different struct at a different address.

So the request stays where it is. **Only its address moves.**

And moving that address must still not allocate.

## Where do requests come from

Look at the handler again.

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

Thousands per second, for the same struct, of the same size.

The obvious fix is to keep freed requests and use them again.

Now there is a new question. **Kept where, and shared by which threads?**

## Reuse needs rules

A kept request is not a new request.

- **It still carries the last client's data.** Someone must clear it.
- **A spike leaves thousands kept.** How many should stay?
- **None are free.** Make a new one, wait for one, or refuse?
- **Different types want different answers.** A small request and a large
  buffer are not kept the same way.
- **The process stops.** Everything still kept must be freed.

These are decisions about your types.

The code that keeps them should not make them for you.

<!-- 3TK-86: the solution half starts here. -->
