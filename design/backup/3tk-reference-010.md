# 3tk — the book

Matryoshka in C3.

Read it to learn 3tk. Read it to use 3tk.

Seven parts. Parts 3, 4 and 5 have the same shape, in the same order.

- **What this is** — high level, short.
- **Participants** — the types, and the role each one plays.
- **Usual flow** — the regular usage.
- **The API, in named groups** — one named group per act.
- **Where to go deeper** — `3tk/src`, a test, a document.

A part learned once is a part learned everywhere.

Deep dive is not this book's job. For that the reader goes to `3tk/src` or to a
test under `3tk/test`.

**This is 010.** It carries all of `009` and records 3TK-74, 2026-09-09: **the
outer's two hooks are required**, `destroy` is renamed `finish` and narrowed to
plain `void`, and the difference between the outer's hooks and the pool's is
written out as a table rather than left to be inferred. Every outer that
`OuterHelper.create` makes declares `fn void? Outer.init(&self, Allocator a)`
and `fn void Outer.finish(&self, Allocator a)`, and **an empty body is how a
type says it needs neither** — a per-type fact with no default is stated, not
inferred from absence, and absence was the ambiguity that let a misspelled hook
vanish in silence. Two compile-time `$assert`s enforce it, so it is alive in
every build mode. **The containers are outside the rule**: `Mailbox` and `Pool`
bind the helper for crossing and allocate themselves. **`009` is in this repo's
`backup/`.**

**`009`** carried all of `008` and recorded the module split of
3TK-70, 2026-09-09: **eleven module names over six files**, four `::internal`
submodules and `mtk::pool::hooks`. The reason is the docs site and not the code
— `c3c docgen` groups by module and by nothing else and ignores visibility
entirely, so a module page published its internals beside its user surface.
Part 7's *The module layout* and *The modules, one by one* carry it, and
`mtk::helper` is a labelled block here for the first time. **`008` is in this
repo's `backup/`.**

`008` carried all of `007` and applies the two-term ruling. 3tk
has exactly two terms: **`Inner`**, a real C3 type and the field you lend, and
**`Outer`**, a role and the struct you own. The words *handle* and *item* are
retired — neither named anything the pair does not. `Slot` is untouched: a
real type naming a container state, not a participant. This supersedes 3TK-59,
which kept *handle* as an English word. Ruled by 3TK-60, 2026-09-04.
Part 3's *Participants* says the model outright rather than leaving it to be
inferred from offset arithmetic: you send and receive your own struct, you lend
the infrastructure one `Inner`, and you cross back once. `007` is in this
repo's `backup/`.

`007`, by 3TK-59, removed the `alias Handle = Inner*` — a concept gets a C3
type when the type system can express useful semantics for it; otherwise it
stays vocabulary, and an `alias` expresses none. It kept the word.

`006`, by 3TK-58, made `Mailbox` and `Pool` opaque inners — `typedef ... =
void`, with the fields in `@private` `_Mbox`/`_Pool` structs — and added
`is_quiet()` to both. `005` and `006` are in that repo's `backup/`.

`005` carried all of `004` and fixed one example: Part 1's *Usual
flow* walkthrough created its demo outer on the stack. The owner ruled a stack
outer illegal, in every case, not only across a mailbox or thread boundary —
see [3tk-patterns-004.md](3tk-patterns-004.md) entry 14. The walkthrough now
creates the outer on the heap. Nothing else changed. **`004` is in
`matryoshka-tk`'s `backup/`, and this version lives in `matryoshka-3tk/design/`,
not in that repo's `ref/`.**

`004` carried all of `003` and corrects one claim about the close
hook: the pool's close section said the hook is called once, while the hooks
section of the same file already said it can be called again by a put that finds
the pool closed. The specification's `Part 12.2` says the second thing. The close
section now says it too. `003` is in `matryoshka-tk`'s `backup/`.

`003` carried all of `002` and re-anchored the citations. `002`, written by
3TK-46, added Part 7's *The modules, one by one* — the eight labelled module
blocks — and corrected Part 7's module layout for the eight-module split 3TK-44
made.

---

## Part 1 — Introduction

### What 3tk is

An outer-transfer and outer-reuse toolkit for concurrent C3 programs.

Three small tools. Each one usable on its own.

- **the core** — type identity for an outer, and two containers that never
  allocate.
- **mailbox** — transfer of an outer between threads.
- **pool** — reuse of an outer, decided by your hooks.

Mailbox and pool are both optional. The core alone is a valid use.

### What it is for

One idea runs through all three.

- Share by communicating.
- Do not share access to an outer. Move the outer.
- One place has the outer at a time.

That gives a concurrent program with no lock around application data.

- The mailbox is shared. The outers passing through it are not.
- The pool is shared. The outers it gives out are not.

### Who it is for

- A C3 programmer building a concurrent subsystem.
- Someone who wants transfer and reuse without a framework around them.
- Someone who wants to read the whole toolkit in an afternoon.

### What it is not

Plain scope limits.

- Not a container library, though `InnerQueue` is public and yours to use. The
  queue and the stack exist because the mailbox and the pool need them, and a
  caller may use the queue directly. The stack is private to the pool.
- Not an allocator. Every outer is allocated and freed by your code, or by your
  hooks.
- Not a garbage collector. The toolkit never frees an outer you gave it, except
  through a hook you wrote.
- Not a storage container. The pool answers whether a reusable outer is free
  right now.
- Not a coordinator. There is no `Master` type. Part 7 says why.

### What the reader needs before starting

- C3, and the `c3c` compiler.
- `any` — the built-in pair of a pointer and a `typeid`. Part 2 gives it.
- Compile-time members reflection, `$Type::members`. Part 2 gives it.
- A fault, and the `!` and `?` in a signature. Part 2 gives it.
- `std::thread`, for mailbox and pool. Only the basics.

---

## Part 2 — C3, interesting parts

### Why this part exists

The toolkit stands on four C3 features.

A reader who knows them reads Parts 3 to 5 without stopping.

- `any` — a pointer and a `typeid`, as one built-in value.
- Compile-time reflection over a struct's members.
- The fault, and the optional return.
- The contract, `@require`, and what the compiler does with it.

### Intrusion — your struct carries the inner

A container that allocates an inner per outer pays twice: once for your struct,
once for the inner.

3tk does not allocate an inner. Your struct carries it.

```c3
struct Msg
{
    int   id;
    Inner inner;
    char  body;
}
```

- `Inner` is one field. Sixteen bytes.
- That field is the chain link and the identity, together.
- The container writes the link. It never allocates.

### `any` — the pointer and the type, in one value

C3's `any` is a built-in fat pointer.

- `.ptr` — where the value is.
- `.type` — the `typeid` of the value.

3tk uses both halves for two different jobs.

- `.ptr` carries the chain link — the next outer, or the outer itself at the end
  of a chain.
- `.type` carries the identity — which outer type this outer really is.

One field does the work of two, and the `typeid` is written once.

```c3
struct Inner
{
    any link;
}
```

### Compile-time reflection — finding the embedded field

The toolkit never asks you to name the field's offset.

It reads the offset out of your type at compile time.

```c3
macro usz inner_offset($Type) @private
macro usz required_alloc_offset($Type) @local
```

- It walks `$Type::members` and looks for the one of type `Inner`.
- A type with no `Inner` field does not compile.
- A type with two `Inner` fields does not compile.
- The message names your type.
- `@private`, and it can be: it is a macro and not a method, and every caller
  shares this module.

**There is no second discovery, and there used to be.**
`required_alloc_offset` found an `Allocator` field the same way, for the
`mtk::managed` that 3TK-64 deleted. **Both are gone.** The toolkit reads and
writes no field of your outer except the `Inner`; an outer that wants to keep
its allocator stores the argument its `init(a)` hook was handed, in a field of
its own, under any name it likes.

That is why there is no helper type to declare and no registration step.

### Faults — the outcomes that are not defects

A 3tk call that can fail returns `void?`.

The faults are outcomes a correct program reaches.

```c3
faultdef CLOSED, TIMEOUT, NOT_AVAILABLE, NOT_CREATED, EMPTY, WOKEN, UNKNOWN_IDENTITY;
```

- `!` propagates the fault to the caller.
- `catch f = ...` names the fault and handles it.
- A defect is not a fault. A defect aborts.

### Contracts, and the two kinds of check

C3 contracts sit in the doc comment, above the declaration.

```c3
<*
 @require is_mine(inner, $Type) : "the inner is not of this type"
*>
```

- A contract is checked in a safe build.
- Under `--safe=no` it is gone, and the condition is not evaluated.

The toolkit adds one macro of its own for the same reason.

```c3
macro @check(#cond, $msg)
const bool CHECKED
```

- `@check` aborts in a safe build and names the message.
- Under `--safe=no` it expands to nothing.
- `CHECKED` is true where those checks are live. Guard an expensive check with
  it.

Two checks never go away. Releasing an open mailbox and releasing an open pool
abort in every build mode.

### Where to go deeper

- `3tk/src/inner.c3` — `any`, the offset macros, `@check`.
- `3tk/negative/nocompile_no_inner.c3` — the type that does not compile.
- `3tk/negative/nocompile_two_inners.c3` — the other one.

---

## Part 3 — the core

---

### What this is

Type identity for an outer, and two containers that never allocate.

Part 2 ended on a struct that carries its own inner. The core is what reads and
writes that inner.

- The identity sits in the same field as the chain link.
- The identity says what the outer type is.
- The check happens on the inner, not in your head.

### Participants

```c3
struct Inner { any link; }

typedef Slot = Inner*;

struct InnerQueue { ... }
struct InnerStack { ... }
struct InnerQueueIterator { ... }
```

**You send and receive your own struct.** To get that, you give the
infrastructure one thing: an `Inner` embedded in it. From then on the
infrastructure never sees your type — it moves `Inner*`, intrusively and
type-erased. You get your struct back by crossing once, from `Inner*` to
`Outer*`, and the identity in the `Inner` is what makes that crossing safe.

**There are exactly two terms: the one you own, and the one you lend.**

- **`Outer`** — your struct, the one that embeds an `Inner`. It is a **role,
  not a type.** There is no `Outer` in the source, because C3 cannot express
  *a struct with exactly one `Inner` field*; `inner_offset($Type)` enforces it
  at compile time instead.
- **`Inner`** — a **real type**, and the field you lend. The chain link and the
  identity, in one.

There is no third term. *Handle* and *item* were the old words for `Inner*` and
for an outer; neither named anything this pair does not.

- `Inner` — the field you embed. The chain link and the identity, in one.
- `Inner*` — a pointer to an embedded `Inner`. One outer, with the type
  forgotten. It is spelled `Inner*` because that is all it is, and 3tk
  transports nothing else.
- `Slot` — a box that holds one `Inner*`, or nothing. Not a third term: it
  names a container state, not a participant.
  - Zero or one outer.
  - A Slot starts empty.
- `InnerQueue` — many outers, first-in first-out. The transfer container.
- `InnerStack` — many outers, last-in first-out. The storage container.
- `InnerQueueIterator` — a walker over a queue.

A Slot holds an `Inner*`, or it is empty.

```text
Slot (holds an Inner*)            Empty Slot

+-------------------+            +-------------------+
|                   |            |                   |
|      Inner*       |            |       null        |
|                   |            |                   |
+-------------------+            +-------------------+

  the outer is here                 the outer is elsewhere
```

Everything transported is an `Inner*`.

- your outers
- mailboxes
- pools

A mailbox and a pool are outers too. Part 4 and Part 5 say how.

### Usual flow

Four steps. Define a type, bind the helper, transport it, recover it.

```c3
import mtk;
import std::core::mem::alloc;

// 1. Define. One embedded field. An `init` hook if the outer wants one.
struct Msg
{
    int       id;
    Inner     inner;
    char      body;
    Allocator alloc;
}

fn void? Msg.init(&self, Allocator a) { self.alloc = a; return; }

// 2. Bind. One line per outer type, and that is the whole ceremony.
alias MSG = helper::OF{Msg};

// 3. Transport. `create` allocates, calls `init`, stamps the identity, and
//    fills the Slot.
Slot s;
defer MSG.release(allocator, &s);
MSG.create(allocator, &s)!;
MSG.must_look(&s).id = 7;

InnerQueue q;
q.push_back_slot(&s);

// 4. Recover. The crossing checks the identity first, and returns null on a
//    mismatch.
Slot got;
got.fill(q.pop_front());
Msg* back = MSG.take(&got);
```

1. **Define.**

   - Embed one `Inner` field. Name it what you like.
   - Declare both hooks — `fn void? Outer.init(&self, Allocator a)` and
     `fn void Outer.finish(&self, Allocator a)`. Neither is optional and **an
     empty body is fine**: that is how a type says it has nothing to set up or
     nothing to wind up. The toolkit calls them for you.
   - An outer that wants to keep its allocator stores it in its own field, in
     its own `init`. That is a choice the outer makes, not a rule; the toolkit
     stores no allocator for you.
   - No registration, and no instantiation beyond the one alias in step 2.

2. **Bind.**

   - `alias MSG = helper::OF{Msg};` — one line, per module that uses `Msg`.
   - Uppercase, because `OF` is a `const`, and C3 enforces the pairing in both
     directions.
   - Everything a user does to an outer is a member of that name. The free
     macros in `mtk::inner` are the layer beneath it, and *The API — crossing*
     below says when you reach for one.

3. **Transport.**

   - `MSG.create` allocates on the heap, calls your `init`, writes the
     identity, and fills the Slot. **Never on the stack** — 3tk computes the
     outer's address from the embedded `Inner` at every crossing, and a stack
     address is only valid for one lexical instance of one frame. See
     [3tk-patterns-004.md](3tk-patterns-004.md) entry 14.
   - `push_back_slot` reaches the field and empties the Slot in the same call.
   - The inner travels. The identity travels with it.

4. **Recover.**

   - `MSG.look` and `MSG.take` check the identity, then cast.
   - They return null when the identity names another type.
   - `MSG.must_look` and `MSG.must_take` abort instead, for where a mismatch
     would be your own defect.
   - You decide what a mismatch means.

**The stamp is what makes this safe, and you rarely write it.** An outer made
by `MSG.create` is stamped already, and `MSG.inner(&msg)` stamps on the way
out. `MSG.stamp(&msg)` exists for an outer you allocated by hand. Forgetting it
is caught in a safe build, at the next crossing or at the next insertion,
whichever comes first.

Recovery from a mixed queue is the same call, once per candidate type.

```c3
alias MSG    = helper::OF{Msg};
alias SENSOR = helper::OF{Sensor};

while (Inner* inner = q.pop_front())
{
    if (Msg* m = MSG.look(inner))
    {
        // a Msg
    }
    else if (Sensor* s = SENSOR.look(inner))
    {
        // a Sensor
    }
    else
    {
        // an identity this loop does not know
    }
}
```

### The API — the helper

**This is the first API section of the book, and that is deliberate.** `OuterHelper` is the
whole user surface for an outer: nine members, one alias to bind them, and no
registration. The sections after it — the identity, the crossings, the Slot,
the link, the queue and the stack — are the layer beneath, and they are here so
that you can read what the helper does rather than trust it. **Reach for the
member.**

`OuterHelper` is the one thing a user binds, one line per outer type.

```c3
alias MSG = helper::OF{Msg};
```

`alias MSG = helper::OF{Msg};` — and that is the whole ceremony. Uppercase, because
it is a `const`, and C3 enforces the pairing in both directions. An uppercase
alias must alias a constant, so `alias MSG = helper::OF{Msg};` is the only
spelling. The helper for `Outer`, ready to alias.

The carrier holds nothing. Its only job is to give C3's method syntax a
receiver, so that `MSG.create(mem, &s)` is a line you can write. Every member
takes `self` and no member reads it: `Outer` arrives from the module
instantiation, and every member compares against `Outer::typeid`, the
compile-time constant that instantiation supplies. C3 has no static-method
facility, and no way to alias a module instantiation as a namespace, so a
zero-state type is how a generic module offers its members under one bound name.
It is a `typedef` over `uptr` because c3c refuses a struct with no members, and
because the standard library spells its own zero-state carriers that way —
`LibcAllocator` and `NullAllocator` are both this shape. The value is never
read, as a number or as anything else.

#### The four crossings

```c3
macro Outer* OuterHelper.look(self, from)
macro Outer* OuterHelper.must_look(self, from)
macro Outer* OuterHelper.take(self, Slot* slot)
macro Outer* OuterHelper.must_take(self, Slot* slot)
```

Two independent axes, so the names are derivable rather than memorised. `must_`
aborts on a mismatch and plain returns null; `take` empties the Slot and `look`
leaves it alone.

- `look` — from a Slot or an inner back to `Outer*`, without disturbing the Slot.
  - Null on an identity mismatch.
  - A mismatch is an answer, not a failure.
- `must_look` — same as `look`, and it aborts on a mismatch.
  - Use it where a mismatch would be your own defect.
  - The abort names your line.
  - Under `--safe=no` the check is gone.
- `take` — from a Slot back to `Outer*`, emptying the Slot on success.
  - Null on an identity mismatch, and then the Slot is unchanged.
  - There is no `Inner*` form: an inner has no Slot to empty.
- `must_take` — same as `take`, and it aborts on a mismatch.
  - The Slot is empty afterwards.
  - This form did not exist before 3TK-64: the old `move_from_slot` had no abort form.

#### The other three

```c3
macro Inner* OuterHelper.inner(self, Outer* outer)
macro void   OuterHelper.stamp(self, Outer* outer)
macro bool   OuterHelper.linked(self, Outer* outer)
```

- `inner` — from your pointer to the `Inner*`, stamping the identity on the way.
  - The stamp may be written any number of times and is safe on a linked outer, so this costs nothing to call twice.
  - It is what makes the identity impossible to forget.
- `stamp` — writes the identity into the embedded `Inner`, and nothing else.
  - For an outer you allocated by hand.
  - An outer made by `create` is stamped already.
  - Forgetting it is caught in a safe build, at the next crossing or at the next insertion, whichever comes first.
  - It is called `stamp` and not `init` because `init` is the name of your own hook.

**Where the omission is caught, and why there are two places.** The identity is
asserted at **both** boundaries, and the two are not redundant. The **crossing**
— `look`, `must_look`, `take`, `must_take` — is where the missing identity would
otherwise become a crash with no message, at a `switch` that looks correct. The
**insertion** — `InnerQueue.push_back` and the pool's stack — is *earlier*, and
earlier is where the message has a home: at an insertion the call that omitted
the stamp is still on the stack, and by the next crossing it is long gone. An
outer whose Slot is filled by hand reaches no insertion at all, which is why the
crossing keeps its own check.

**Null is not the violation.** An empty Slot and a null `Inner*` are answers a
checking crossing is allowed to give, and `look` on an empty Slot is the ordinary
way to ask whether anything arrived. Only an inner that exists and carries no
identity is a defect.

**Both are `$if env::COMPILER_SAFE_MODE`-gated, so a fast build carries
nothing** — the condition is not evaluated and the identity is never read. The
two negative programs are `negative/unstamped_insert` and
`negative/unstamped_crossing`, one per boundary, and neither can reach the
other's site.
- `linked` — true when the outer is on some chain.
  - Exact, and O(1).

#### Allocating and freeing

```c3
macro void? OuterHelper.create(self, Allocator a, Slot* slot)
macro void  OuterHelper.release(self, Allocator a, Slot* slot)
```

`create` allocates the outer, initializes it, stamps it, and fills the Slot.

- Four steps in this order: allocate zeroed, call your `init(a)` hook, stamp the inner, fill the Slot.
- `Outer` must declare `fn void? Outer.init(&self, Allocator a)` and `fn void Outer.finish(&self, Allocator a)`, and an empty body is fine — a type with neither to write declares both and leaves them empty.
- That is checked at compile time, here and in `release`, so a misspelled hook names your line instead of vanishing.
- Stamping after the hook is deliberate: if `init` fails the outer was never stamped, so a pointer that escaped a failed creation can never be mistaken for a live outer.
- On a hook failure the allocation is freed and the fault is propagated unchanged.
- On an allocation failure the Slot is untouched and the fault is returned.
- It returns `void?` because its caller has a real decision to make.
- The toolkit reads and writes no field of your outer except the `Inner`.
- An outer that wants to keep its allocator stores this argument in its own field, under any name, in its own `init`.

`release` calls your `finish(a)` hook, empties the Slot, and frees the outer.

- A no-op on an empty Slot, so a `defer` registered before the acquisition is safe.
- It returns `void`, so it needs no `!` in a `defer`, and `finish` returns `void` for the same reason: a fault raised there would reach no caller who could act on it.
- It returns `void`, and that is not symmetry-breaking for its own sake: `release` is what you write in a `defer`, and C3 refuses a bare failable call there.
- The narrower reason is that a teardown fault has no recipient — `release` runs on a path that is usually already unwinding, nobody can act on "freeing failed", and the resource is gone either way.
- So `finish` returns plain `void` and cannot fail. 3TK-74 narrowed it: the old `destroy` returned `void?` and `release` turned a failure into an abort in a safe build and dropped it in a fast one, which is a fault nobody could act on.
- The same compile-time check as `create`: both hooks must be declared, and an empty body is fine.
- A failing teardown is a defect, not an outcome.

`finish` is not `destroy`, and the name is the warning — do not tear the outer down here.
`destroy` is C3's own word for tearing a thing down — `_cv.destroy()`, `_mu.destroy()` in this very port — and that is the one thing you must not do to your outer.
`release` frees it the moment your hook returns.
`finish` says *wind up your business*.
Give up what the outer acquired and leave the memory alone.

**Both hooks are required, and both receive the allocator from the caller.**
Every outer that `create` makes declares both, and **an empty body is fine**.
Two `$assert`s in `create` and `release` check it at compile time, so a
misspelled `initialize` or `deinit` is now a compile error naming your call
site, where before the branch vanished and the outer came back allocated,
stamped and uninitialized with nothing reported. (`Init` is not a near miss to
watch for: C3 refuses a method name that begins with a capital.)

**The containers are outside this rule.** `Mailbox` and `Pool` bind the helper
for crossing and never call `create` — they allocate themselves, because they
hold a mutex and a condition variable whose teardown order is the whole of their
release. The rule binds every outer *the helper creates*; an outer bound only
for crossing is not making `create`'s contract.

#### Your hooks and the pool's hooks

The two look alike and a reader is right to ask. **Both are inversions: in both
cases the toolkit calls your code.** They differ in how many answers there are,
and in when the answer is fixed.

> **A pool's hooks are policy: one answer per pool, chosen when you create it,
> so you pass them in. An outer's hooks are the type's own: one answer per type,
> fixed forever, so you declare them on the type.**

| | pool hooks | outer hooks |
|---|---|---|
| what it decides | the pool's **policy** | the type's **own** construction and teardown |
| how many answers | **one per pool** — two pools of the same outer type can differ | **one per type, forever** |
| when it is fixed | at `pool::create`, at runtime | at compile time, by the type |
| how it is spelled | `interface PoolHooks`, implemented and **passed** | two methods **declared on your outer** |
| may it be absent | a pool cannot exist without hooks | no — **but the body may be empty** |
| where it lives | its own page, `mtk::pool::hooks` | on your type, and in `create`/`release`'s contract |

Everything else follows from that. There is no `interface OuterHooks` because
there is nothing to pass: an interface carries a choice across a boundary at
runtime, and these hooks are never handed over.

```c3
alias MSG = helper::OF{Msg};

Slot s;
defer MSG.release(a, &s);
MSG.create(a, &s)!;

MSG.must_look(&s).id = 1;
```

### The API — identity

**Beneath the helper.** `MSG.create` and `MSG.inner` stamp for you, and
`MSG.stamp` is the member for an outer you allocated by hand. These are the
macros those three reach.

The identity is written once and never computed.

```c3
macro void stamp(outer)
macro bool is_mine(Inner* inner, $Type)
fn typeid Inner.outer_tid(&self)
```

**RENAMED by 3TK-64, 2026-09-07.** `init` is now the name of the user's own
hook, so the macro that writes the identity is `stamp`. `OuterHelper.stamp` and
`OuterHelper.inner` are the forms a user calls, and this is the macro they reach.

- `stamp` — writes the identity into the embedded `Inner`.
  - Call it any number of times.
  - A second call writes what the first one wrote, and it is safe on a linked outer as well as an unlinked one.
  - An outer that was never stamped carries no identity.
  - The line below rebuilds the whole `any`, because `.type` is not assignable on its own.
  - It preserves `link.ptr`, and that is what makes the stamp safe on a linked inner.
  - The natural maintenance edit is `any_make(null, ...)`, which silently unlinks a linked outer.
  - The correct line differs from the destructive one by a single sub-expression.
  - It was called `init` until 3TK-64, when `init` became the name of the user's own hook.
- `is_mine` — true when the inner names `$Type`.
  - False for a null inner.
  - False for an outer that was never stamped.
- `outer_tid` — the identity of the outer this inner is embedded in.
  - Null for an inner that was never stamped.
  - It exists so that no user ever writes `inner.link.type`.
  - Public because C3 cannot hide a method — `@private` is ignored on method declarations.
  - It is part of the user surface: a dispatch switch reads it.

The identity answers one question: **is this a `$Type`?**

- It does not answer "which instance?".
- It does not answer "what role does this outer play?".
- Part 6 says what to do when the role matters.

An identity comparison reads the `typeid` already in the outer. Nothing is
computed and nothing is allocated.

#### What of `module mtk` is yours

**Ruled by the owner, 2026-09-07, and it is what `inner.c3` is now ordered by.**

- A small part of this module is yours to call directly: the Slot's five operations, the identity, and the five crossings written as methods.
- Everything else goes through the helper, and says so with `For internal usage.` at the head of its doc block.

The test is whether the helper can do it for you. It cannot embed the field, it
cannot read the Slot, and it cannot read an identity before the type is known —
so `Inner`, `Slot`, `Slot.is_empty`, `.is_full`, `.peek`, `.take`, `.fill`,
`Inner.outer_tid` and the five crossing methods are the first part of
`inner.c3`. It can do every other crossing, so `to_inner`, `from_inner`,
`must_from_inner`, `from_slot`, `must_from_slot`, `move_from_slot`, `is_mine`
and `stamp` are the second part, together with the chain primitives
`repoint_to`, `points_to`, `is_linked` and `reset`, which are nobody's but the
queue's and the stack's.

**The helper cannot do this one for you: a dispatch switch reads the identity
before it knows the type.** That is why `outer_tid` is in the first part.

### The API — crossing

**Beneath the helper.** `look`, `must_look`, `take` and `must_take` are the
four spellings a user reaches for, and they forward to what is below without
adding logic of their own. Two reasons to read past them: a dispatch loop that
has an `Inner*` and no bound helper for the type it is testing, and the wish to
see that the forwarding is real. `examples/012-type_crossing.c3` and
`examples/013-recovering_the_type.c3` show both layers side by side, and they
are the only two examples that do.

Every crossing between a typed pointer and an `Inner*` lives in one file.

```c3
macro Inner* to_inner(outer)
macro from_inner(Inner* inner, $Type)
macro must_from_inner(Inner* inner, $Type)
```

- `to_inner` — from your pointer to the inner, an `Inner*`. Null in, null out.
- `from_inner` — from an `Inner*` back to `$Type*`.
  - Null on an identity mismatch.
  - A mismatch is an answer, not a failure.
- `must_from_inner` — the same, and it aborts on a mismatch.
  - Use it where a mismatch would be your own defect.
  - The abort names your line.

The same three, taking the outer from a Slot.

```c3
macro from_slot(Slot* s, $Type)
macro must_from_slot(Slot* s, $Type)
macro move_from_slot(Slot* s, $Type)
```

- `from_slot` — looks. The Slot is unchanged.
- `must_from_slot` — looks, and aborts on failure.
- `move_from_slot` — takes.
  - On success the Slot is left empty.
  - On failure it is unchanged.

Five of them again, as methods, for the call site that reads better that way.

```c3
macro Inner.to(&self, $Type)
macro Inner.as(&self, $Type)
macro Slot.to(&self, $Type)
macro Slot.must(&self, $Type)
macro Slot.move(&self, $Type)
```

- `inner.to(Msg)` is `from_inner(inner, Msg)`.
- `inner.as(Msg)` is `must_from_inner(inner, Msg)`.
- `s.to(Msg)`, `s.must(Msg)`, `s.move(Msg)` are the three Slot forms.

Each is the same crossing, as a method on the inner or as a method on the
Slot.

**Of the two spellings below the helper, the five methods are the readable
one**, ruled by the owner 2026-09-07 on the measurement of the day: across
`examples/` the five methods were called 51 times and the free `inner::`
crossings twice. **3TK-66 moved the 51 up to the helper**, so the count today is
five method call sites and one free one, all of them inside the two examples
that teach the layering. The ruling stands for what is left: prefer the method
to the free form. The five carry descriptions of their own, which repeat the
free forms' sentences rather than pointing at them:

- `Inner.to` — from an `Inner*` back to `$Type*`.
- `Inner.as` — from an `Inner*` back to `$Type*`, and it aborts on a mismatch.
- `Slot.to` — from the Slot back to `$Type*`. It looks, and the Slot is unchanged.
- `Slot.must` — from the Slot back to `$Type*`, and it aborts on a mismatch. The Slot is unchanged.
- `Slot.move` — from the Slot back to `$Type*`, and it takes.

None of these moves an outer. Reading an identity and casting a pointer leave
every container alone.

### The API — the Slot

The Slot is how the toolkit tells you where an outer went.

```c3
fn bool   Slot.is_empty(&self)
fn bool   Slot.is_full(&self)
fn Inner* Slot.peek(&self)
fn Inner* Slot.take(&self)
fn void   Slot.fill(&self, Inner* inner)
```

- `is_empty` / `is_full` — which of the two states it is in.
- `peek` — look without taking. Null on an empty Slot.
- `take` — take the `Inner*` out and clear the Slot. Null on an empty Slot.
- `fill` — put an `Inner*` in.
  - A null inner is a defect.
  - Overwriting a full Slot is a defect.

Read the Slot after every call that gives or takes an outer. Part 6 makes that a
rule.

### The API — the link

The chain link is the other half of `Inner`.

```c3
fn void   Inner.repoint_to(&self, Inner* to)
fn Inner* Inner.points_to(&self)
fn bool   is_linked(Inner* inner)
fn void   reset(Inner* inner)
```

- `repoint_to` — keeps the identity, swaps the chain link. The containers call
  it.
- `points_to` — the inner this one links to. Null if it is on no chain.
- `is_linked` — true when the inner is on some chain. Exact, and O(1).
  - False for a null inner.
- `reset` — clears the chain link so the outer can be inserted again.
  - It clears the link and not the identity.
  - Every removal in the queue and the stack calls it for you.

Every chain ends at an inner pointing at itself, never at null. That is what
makes `is_linked` exact.

#### Public, and why — the four on this page and the two guards

**Written by 3TK-63. REWRITTEN by 3TK-pre-65, 2026-09-07.** These are public
because the language leaves them no other state, not because a user is invited
to call them. **The per-declaration paragraph that used to say so is withdrawn
at all seven places it was written**, and what replaces it is one line in the
source and this subsection here.

**SUPERSEDED BY 3TK-67, 2026-09-08.** 3TK-pre-65 ruled that such a declaration
loses its `<* *>` block, on the argument that absence is the only visibility
signal C3 offers. It is superseded because obeying it deletes checks: a
`@require` lives INSIDE the block, so stripping the block from
`must_from_inner` stripped its type check and `negative/wrong_type_must`
stopped aborting in a checking build. What replaces it:

> **A declaration that is not the user surface keeps its `<* *>` block. The
> block opens with the exact line `For internal usage.`, and after it carries
> only directives that do work — no prose, no argument, no *why*. Every such
> declaration gets the block, including those with no directives at all.**

> **They are grouped, and the grouping is the truth.** All of them sit below one
> banner per file, with the reason for their being public stated once beneath
> it. A per-declaration marker fails by omission and nothing looks wrong; a
> declaration cannot fail to be somewhere. So `run-builds.sh` checks the
> partition both ways: every declaration below the banner opens with the marker,
> and none above it does.

A marker sentence is a **stronger** signal than absence, because `c3c docgen`
publishes the description and publishes nothing about a missing one. Docgen
ignores visibility entirely — it publishes a `@private` macro and a `@local`
struct as public — and it publishes no file structure and no `//` comment
either, so the banner organises the source and the marker is the only thing
that crosses to the site. `check-doc-loop.sh` excludes the marker by exact
match on the whole line, so it is not a sentence this reference owes.

**It sorts by audience, not by hideability.** `Inner.outer_tid` and every
`Slot.*` are unhideable and are the user surface, so their blocks describe.
`Inner.repoint_to` is unhideable and is not, so its block carries the marker.

Why each one is public, stated here once and never again per declaration:

- `repoint_to`, `points_to`, `InnerQueue.@guard_insert` and
  `InnerStack.@guard_insert` are **methods**, and C3 ignores `@private` on a
  method declaration: a method is found through its receiver type, not through
  a module path, so there is no module boundary at the call site to check
  against. Measured 2026-09-07: `@local` is ignored on a method too, and the
  compiler warns and then accepts the call from another module.
- `reset` and `is_linked` are free functions and could be hidden, but are not:
  `InnerStack` calls them from `mtk::pool::internal`, which is not inside
  `mtk::inner` at all and so can see nothing `@private` of it.
- `inner_offset` **used to be the one that was hidden**, in a third section of
  `inner.c3` declaring `module mtk::inner @private;`. **REVISED by 3TK-70,
  2026-09-09:** that section folded into `mtk::inner::internal` and the
  attribute went with it. `@private` reaches the module and nothing else, so a
  submodule could not both keep it and stay reachable from the crossings in
  `mtk::inner`, and the owner's ruling is that the intent is visibility on the
  docs site and not preventing use. `@local` never worked here either, and was
  measured: with it, the file's own macros fail to resolve the name.

Converting the methods to free functions would buy an enforcement the language
only partly grants anyway, since `Inner.link` is itself public and writable.
The door cannot be closed; it is left plainly open, with a sign saying who is
allowed through.

**The accepted gap, and 3TK-70 narrowed it.** Docgen still has no visibility
filter and no exclude flag, so `_Mbox`, `_Pool`, `InnerStack` and every internal
method are still published as public. What changed is where: they are on
`mtk::inner::internal`, `mtk::mailbox::internal` and `mtk::pool::internal`, each
of which is a page with a description saying it is not the user surface, rather
than sitting undescribed beside the surface on the page a user lands on. **No
stage goes looking for a way around docgen's lack of a visibility filter.**

### The API — the queue

The intrusive queue. First-in first-out. Nothing here allocates, and every
operation is O(1).

```c3
fn bool   InnerQueue.is_empty(&self)
fn usz    InnerQueue.len(&self)
fn void   InnerQueue.push_back(&self, Inner* inner)
fn void   InnerQueue.push_back_slot(&self, Slot* s)
fn Inner* InnerQueue.pop_front(&self)
fn InnerQueue InnerQueue.take(&self)
fn void   InnerQueue.append_queue(&self, InnerQueue* other)
fn InnerQueueIterator InnerQueue.iter(&self)
fn Inner* InnerQueueIterator.next(&self)
```

- `is_empty` — true if the queue holds nothing.
- `len` — how many outers the queue holds. O(1).
  - The count is kept, so `len` is O(1).
- `push_back` — adds at the back. There is no front insert.
- `push_back_slot` — the same, taking the outer from a Slot.
  - The Slot is empty afterwards.
  - An empty Slot is a defect, not a no-op.
- `pop_front` — takes the outer at the front.
  - Null on an empty queue, which is an answer and not a fault.
  - The returned outer's chain link is cleared.
- `take` — takes everything the queue holds, as one flat queue.
  - The queue is empty afterwards.
- `append_queue` — moves every outer of another queue onto the back of this one,
  in O(1).
  - That queue is empty afterwards.
  - A queue moved onto itself is a defect.
- `iter` / `next` — a walker, taken from the queue.
  - `next` — the next inner, or null when the walk is exhausted.
  - Exhausted when `next` returns null.
  - Removing the current outer during a walk is not supported.

```c3
InnerQueueIterator it = q.iter();
while (Inner* inner = it.next())
{
    Msg* m = MSG.look(inner);
    if (m) { }
}
```

Nothing in the queue can fail.

### The API — the stack

The intrusive stack. Last-in first-out. Four operations: no walker, and no
splice.

Where the queue carries outers across, the stack holds them still.

```c3
fn bool   InnerStack.is_empty(&self)
fn usz    InnerStack.len(&self)
fn void   InnerStack.push(&self, Inner* inner)
fn Inner* InnerStack.pop(&self)
```

- `is_empty` — true if the stack holds nothing.
- `len` — how many outers the stack holds. O(1).
  - The count is kept, so `len` is O(1).
  - There is no tail, so flattening the stack is O(n).
- `push` — adds on top. There is no Slot-shaped insert.
- `pop` — takes the outer on top.
  - Null on an empty stack.
  - The returned outer's chain link is cleared.

The order is not promised. No caller is entitled to which outer comes back.

Nothing in the stack can fail.

The stack is the storage container. Outers rest in it until they are wanted
again, and the newest is the one that comes back first.

The pool keeps one per identity, and it is the only stack 3tk owns. No 3tk
signature passes one: the four that take a container take an `InnerQueue*`.
It lives inside `mtk::pool::internal` and is not a name a user can reach.

**REVISED by 3TK-62, 2026-09-07, and again by 3TK-70, 2026-09-09.** `004` said
*"a caller who wants a stack declares one."* That is withdrawn. `stack.c3` is
deleted as a file and `InnerStack` is at the foot of `pool.c3`, inside
`module mtk::pool::internal`, `@local` there, so a caller cannot name it at
all. This reverses 3TK-45. The API above is documented
because the pool is built on it and the book explains the pool — not because it
is yours to call.

### The API — the insert guards

Both containers refuse a bad insert, where checks are live.

```c3
macro InnerQueue.@guard_insert(&self, Inner* inner)
macro InnerStack.@guard_insert(&self, Inner* inner)
```

- A null inner is a defect.
- An outer already on any chain is a defect.
- Both are gone from a fast build.
- Public, and why: see *Public, and why* under *The API — the link*.

### The API — the version

```c3
const String VERSION
```

- The toolkit's version string.

### Where to go deeper

- `3tk/src/inner.c3` — `Inner`, `Slot`, the link, `@check`.
- `3tk/src/helper.c3` — `OuterHelper`: the crossings, `create` and `release`.
- `3tk/src/queue.c3` — the queue; `InnerStack` is the last section of `pool.c3`.
- `3tk/test/t_identity.c3` — identity across types.
- `3tk/test/t_slot.c3` — the Slot's states.
- `3tk/test/t_queue.c3` — the queue.
- `3tk/test/t_helper.c3` — the helper, the hooks, `create` and `release`.

---

## Part 4 — mailbox

---

### What this is

Transfer of an outer between threads.

A queue of outers, with waiting.

- Many producers, many consumers, on one mailbox.
- The mailbox keeps outers. It never touches them.
- A mailbox is itself an outer: it can travel through another mailbox.

### Participants

```c3
typedef Mailbox = void;

const typeid TYPE;
```

- `Mailbox` — the tool itself, as an opaque inner following the idiom C3's
  own stdlib uses for `std::thread::channel::UnboundedChannel`. The real
  fields live in an `@private` struct in the same module (`mailbox.c3`'s
  `_Mbox`); nothing about them is visible outside it — not the names, not the
  layout, not whether a field exists at all. Every method casts the inner
  back to `_Mbox*` as its first line. Created on the heap, with an allocator
  it keeps for life.
- `TYPE` — the identity of a `Mailbox` as an outer.
- `Slot` — how you give an outer and how you take one.
- `InnerQueue` — how you take many at once.

Inside it are two queues.

- One for out-of-band outers.
- One for ordinary outers.

3TK-58 made this opaque. Before it, `Mailbox` was a public struct with every
field readable and writable from outside the module — the leading underscore
was convention only, not an enforced boundary. It is now.

### Usual flow

Create, send, receive, close, release.

```c3
Mailbox* mb = mailbox::create(a)!;

Slot s;
MSG.create(a, &s)!;
mb.send(&s)!;                       // s is empty now — the mailbox has it

Slot got;
if (catch f = mb.receive(&got, time::sec(1)))
{
    if (f == mtk::TIMEOUT) { }
}
else
{
    MSG.release(a, &got);
}

InnerQueue left;
mb.close(&left);
while (Inner* inner = left.pop_front())
{
    Slot one;
    one.fill(inner);
    MSG.release(a, &one);
}
mb.release();
```

1. **Create.**

   - The allocator is kept for life.
   - Nothing partially constructed is ever returned.

2. **Send.**

   - The Slot is the answer. Cleared means the mailbox has the outer.
   - Untouched means the mailbox is closed and you still have the outer.

3. **Receive.**

   - An empty Slot goes in. A full Slot comes back on success.
   - Every other outcome is a fault, and the Slot stays empty.

4. **Close.**

   - What was left comes back to you, as one queue.
   - Releasing those outers is your work. The mailbox never knew what they were.

5. **Release.**

   - Close it first. Releasing an open mailbox aborts in every build mode.
   - Then let every thread that touches it finish. Closed is not quiet.

### The API — create and destroy

```c3
fn Mailbox*? create(Allocator a)
fn void Mailbox.release(&mbox)
```

- `create` — allocates a mailbox and returns it.
  - Every step undoes what succeeded before it.
- `release` — frees the mailbox, with the allocator it kept.
  - It takes no allocator.
  - The mailbox must be closed and quiet.
  - Quiet means no call on the mailbox is still running.
  - Closing does not make a mailbox quiet: a receiver parked in `receive` is
    woken by the close and has not yet returned.
  - The usual way to get quiet is to join the threads that touch the mailbox.
  - Releasing a mailbox that is not quiet aborts in every build mode.

### The API — send

```c3
fn void? Mailbox.send(&mbox, Slot* slot)
fn void? Mailbox.send_oob(&mbox, Slot* slot)
```

- `send` — puts the outer on the ordinary queue.
- `send_oob` — puts it ahead of every ordinary outer.
  - First-in first-out among out-of-band outers themselves.
  - One priority level. This is not a priority queue.

Both take a full Slot.

- Cleared on success.
- Untouched on `CLOSED`, and the sender still has the outer.
- An empty Slot is a defect.

### The API — receive

```c3
fn void? Mailbox.poll(&mbox, Slot* slot)
fn void? Mailbox.receive(&mbox, Slot* slot, Duration timeout)
fn void? Mailbox.receive_all(&mbox, InnerQueue* out)
```

- `poll` — takes an outer if one is queued. Never waits.
  - Reports `EMPTY` where `receive` with a zero timeout would report `TIMEOUT`.
- `receive` — takes an outer, waiting up to the timeout.
  - The deadline is anchored once. A spurious wakeup does not restart it.
  - There is no interruption. C3 has no interruptible condition wait.
- `receive_all` — moves every queued outer onto your queue.
  - The queue is in the order `receive` would have taken them out.
  - Releasing the outers is your work.

Out-of-band first, then ordinary, first-in first-out within each.

`poll` and `receive` take an empty Slot and fill it on success.

### The API — control

```c3
fn void? Mailbox.wake_all(&mbox)
fn void  Mailbox.close(&mbox, InnerQueue* out)
fn bool  Mailbox.is_closed(&mbox)
fn bool  Mailbox.is_quiet(&mbox)
fn usz   Mailbox.len(&mbox)
```

- `wake_all` — wakes every current waiter. Each one reports `WOKEN`.
  - The mailbox stays open.
  - A thread that starts waiting afterwards is unaffected.
- `close` — closes the mailbox and gives back what was left. Cannot fail.
  - Callable more than once. The second call takes nothing.
  - Discarding that queue drops the outers, and a later send refuses them.
  - Closing does not make a mailbox quiet.
- `is_closed` — true when it is closed.
- `is_quiet` — true when it is closed and no call on it is still running.
  - The same predicate `release()` asserts, read under the mutex. The usual way
    to reach this state is to join the threads that touch the mailbox.
  - Added by 3TK-58, the public way to ask what three test files used to read
    off the internal `_active` count directly, before `Mailbox` was opaque.
- `len` — how many outers are queued.
  - A hint. It is stale by the time you read it.

### The API — the mailbox as an outer

```c3
macro Inner* to_inner(Mailbox* p)
macro Mailbox* of(Inner* inner)
```

- `to_inner` — from a `Mailbox*` to its `Inner*`. Cannot fail.
- `of` — the checking crossing back. Null when the inner names another type.

That is what lets a mailbox travel through another mailbox.

### The API — outcomes

| fault | when |
|---|---|
| `CLOSED` | the mailbox is closed |
| `EMPTY` | `poll` found nothing queued |
| `TIMEOUT` | `receive` waited the whole timeout |
| `WOKEN` | `wake_all` reached this waiter |

None of them is a defect. A correct program reaches all four.

### Where to go deeper

- `3tk/src/mailbox.c3` — the whole tool, in one file.
- `3tk/test/t_mailbox.c3` — send, receive, close.
- `3tk/test/t_concurrency.c3` — many producers and many consumers.
- `3tk/negative/release_open_mailbox.c3` — the abort that never goes away.
- `3tk/negative/release_while_receiving.c3` — the same abort, for a mailbox
  that is closed but not yet quiet.

---

## Part 5 — pool

---

### What this is

Reuse of an outer, decided by your hooks.

A keeper of free outers, grouped by type identity.

- Policy is not in the pool. Policy is in the hooks.
- The pool answers whether a reusable outer is free right now.
- A pool is itself an outer: it can travel through a mailbox.

The mailbox gives everything back to a caller. The pool's close gives nothing
back at all.

### Participants

```c3
interface PoolHooks { ... }

enum GetMode
{
    AVAILABLE_OR_NEW,
    NEW_ONLY,
    AVAILABLE_ONLY,
}

struct PoolBucket { ... }
typedef Pool = void;

const typeid TYPE;
```

- `Pool` — the tool itself, as an opaque inner following the same idiom as
  `Mailbox` above. The real fields live in an `@private` struct in the same
  module (`pool.c3`'s `_Pool`); nothing about them is visible outside it.
  Every method casts the inner back to `_Pool*` as its first line. Created on
  the heap, with an allocator it keeps for life.
- `PoolHooks` — your policy. Three methods. Part 5's last group says what each
  one may do.
- `GetMode` — the three modes of a plain get.
- `PoolBucket` — the free outers of one identity, as an `InnerStack`.
- `TYPE` — the identity of a `Pool` as an outer.

One bucket per identity, in a flat slice allocated once at creation.

```text
Pool
 |
 +-- bucket[0]  tag = Msg::typeid      free: InnerStack
 +-- bucket[1]  tag = Sensor::typeid   free: InnerStack
 +-- bucket[2]  tag = Frame::typeid    free: InnerStack
```

- The identity set is fixed at creation.
- It is not empty, and it has no duplicate. Both are checked.

A stack and not a queue, and the reason is defect surfacing. The outer just
given back is on top, so a caller still writing through a stale pointer
collides with the next owner at once instead of much later.

### Usual flow

Write the hooks, create, get, put, close, release.

```c3
struct MsgPolicy (PoolHooks)
{
    Allocator alloc;
}

fn void MsgPolicy.on_get(&self, typeid want, usz in_pool, Slot* slot) @dynamic
{
    if (want != Msg::typeid) return;
    if (catch MSG.create(self.alloc, slot)) return;
}

fn void MsgPolicy.on_put(&self, usz in_pool, Slot* slot, InnerQueue* extra) @dynamic
{
    if (in_pool >= 8) { MSG.release(self.alloc, slot); return; }
    Msg* m = MSG.must_look(slot);
    m.id = 0;
}

fn void MsgPolicy.on_close(&self, InnerQueue remaining) @dynamic
{
    while (Inner* inner = remaining.pop_front())
    {
        Slot one;
        one.fill(inner);
        MSG.release(self.alloc, &one);
    }
}

MsgPolicy policy = { .alloc = a };
typeid[1] tags = { Msg::typeid };

Pool* p = pool::create(a, tags[..], &policy)!;

Slot s;
p.get(Msg::typeid, AVAILABLE_OR_NEW, &s)!;

Msg* m = MSG.must_look(&s);
m.id = 42;

p.put(&s);
if (s.is_full()) { MSG.release(a, &s); }

p.close();
p.release();
```

1. **Write the hooks.**

   - The implementing struct is the context. There is no `ctx` parameter.

2. **Create.**

   - The hooks are a parameter of creation. A pool cannot exist without them.
   - The identity set is a parameter too, and it never changes.

3. **Get.**

   - An empty Slot goes in. A full Slot comes back on success.
   - A free outer is taken, or `on_get` is asked to make one.

4. **Put.**

   - The Slot is the answer. Cleared means the pool took the outer.
   - Unchanged means it was refused and you still have the outer.

5. **Close.**

   - Nothing comes back to you. Everything goes to `on_close`.

6. **Release.**

   - Close it first. Releasing an open pool aborts in every build mode.
   - Then let every thread that touches it finish. Closed is not quiet.

### The API — create and destroy

```c3
fn Pool*? create(Allocator a, typeid[] tags, PoolHooks hooks)
fn void Pool.release(&pool)
```

- `create` — allocates a pool and returns it.
  - `tags` is the identity set. Not empty, and no duplicate.
  - `hooks` is the policy, and it cannot be null.
  - Every step undoes what succeeded before it.
- `release` — frees the pool, with the allocator it kept.
  - It takes no allocator.
  - The pool must be closed and quiet.
  - Quiet means no call on the pool is still running.
  - Closing does not make a pool quiet: a hook the pool called is application
    code that has not returned, and a getter parked in `get_wait` is woken by
    the close and has not yet returned either.
  - The usual way to get quiet is to join the threads that touch the pool.
  - Releasing a pool that is not quiet aborts in every build mode.

### The API — get

```c3
fn void? Pool.get(&pool, typeid want, GetMode mode, Slot* slot)
fn void? Pool.get_wait(&pool, typeid want, Slot* slot, Duration timeout)
```

- `get` — takes a free outer, or has the hook make one. Never waits.
  - `AVAILABLE_OR_NEW` — take a free one, and ask the hook if there is none.
  - `NEW_ONLY` — do not take a free one. Ask the hook.
  - `AVAILABLE_ONLY` — take a free one, or report `NOT_AVAILABLE`.
- `get_wait` — takes a free outer, waiting up to the timeout.
  - It never creates. No hook is called on this path.
  - The deadline is anchored once. A spurious wakeup does not restart it.

Both take an empty Slot and fill it on success.

Which fault comes from where:

- `NOT_AVAILABLE` comes only from `AVAILABLE_ONLY`.
- `NOT_CREATED` comes only from a hook that produced nothing.
- `TIMEOUT` comes only from `get_wait`, where `AVAILABLE_ONLY` would have said
  `NOT_AVAILABLE`.
- `UNKNOWN_IDENTITY` is your defect. A checking build aborts on it, and
  `get_wait` reports it at once rather than after the whole timeout.

`on_get` runs outside the pool's mutex. Everything read before the mutex is
released is stale when it returns.

### The API — put

```c3
fn void Pool.put(&pool, Slot* slot)
```

- `put` — gives an outer back. Returns nothing.
- The Slot is the answer.
  - Cleared: the pool took it.
    - Unchanged: the pool refused it before any hook ran, and you still have
  the outer.
- It cannot fail and cannot be interrupted.
- An empty Slot is a no-op.

A close that arrives while `on_put` runs is handled. The outer goes to
`on_close`, and your Slot stays cleared.

There is no `put_all`. A caller giving a batch back writes the loop.

```c3
while (Inner* inner = batch.pop_front())
{
    Slot s;
    s.fill(inner);
    p.put(&s);
    if (s.is_full()) { batch.push_back(inner); break; }
}
```

### The API — control

```c3
fn void Pool.close(&pool)
fn bool Pool.is_closed(&pool)
fn bool Pool.is_quiet(&pool)
fn usz  Pool.count_of(&pool, typeid t)
```

- `close` — closes the pool. Cannot fail.
  - Everything the pool held goes to `on_close`, as one flat queue.
  - Callable more than once. The second call takes nothing and does not run the
    hook again.
  - The hook is called outside the mutex, after the closed flag is set.
  - Called once by `close`, and possibly once more with stragglers from a
    concurrent `put`.
  - Closing does not make a pool quiet.
- `is_closed` — true when it is closed.
- `is_quiet` — true when it is closed and no call on it is still running.
  - The same predicate `release()` asserts, read under the mutex. The usual way
    to reach this state is to join the threads that touch the pool.
  - Added by 3TK-58, the public way to ask what test files used to read off
    the internal `_active` count directly, before `Pool` was opaque.
- `count_of` — how many of one identity are free.
  - A hint. It is stale by the time you read it.

### The API — the pool as an outer

```c3
macro Inner* to_inner(Pool* p)
macro Pool* of(Inner* inner)
```

- `to_inner` — from a `Pool*` to its `Inner*`. Cannot fail.
- `of` — the checking crossing back. Null when the inner names another type.

### The API — hooks

Three methods. Implement them to give a pool its policy.

```c3
fn void on_get(typeid want, usz in_pool, Slot* slot);
fn void on_put(usz in_pool, Slot* slot, InnerQueue* extra);
fn void on_close(InnerQueue remaining);
```

**`on_get` — make one, or refuse.**

- Asked for an outer of a named identity.
- The Slot is empty on entry. Fill it, or leave it.
- An empty Slot afterwards becomes `NOT_CREATED`.
- An outer of a different identity is a defect of your application.
- That is a checking-build check, and a fast build cannot catch it.
- `in_pool` is how many of this identity remain, after the removal. A hint, and
  stale.

**`on_put` — keep it, reset it, replace it, or free it.**

- An outer is being given back. Four outcomes, and none is mandated.
- Freed with nothing kept: empty the Slot.
- Kept as it is, or kept after a reset: leave it full.
- Freed with a different outer put back: replace the contents.
- A full Slot on return means one thing — an outer is kept, original or
  replacement.
- `extra` starts empty. Outers added there are taken the same way, with the same
  checks.
- `in_pool` is how many of this identity are held, before the addition. A hint.

**`on_close` — take everything that is left.**

- Called with everything that remained, as one flat queue, by value: *I do not
  care what you did.* The pool does not verify it and never will.
- Process or free every outer in it.
- No order is promised.
- Called once by `close`, and possibly once more with stragglers from a
  concurrent `put`.
- So a hook must not free its own context on the first call.

**What a hook may not do.**

- A hook runs outside the pool's mutex, several at once on different threads.
- A hook that touches shared state protects it itself.
- A hook does not call back into the pool.
- A hook does not block and does not wait.

### The API — outcomes

| fault | when |
|---|---|
| `CLOSED` | the pool is closed |
| `NOT_AVAILABLE` | `AVAILABLE_ONLY` found no free outer |
| `NOT_CREATED` | `on_get` produced nothing |
| `TIMEOUT` | `get_wait` waited the whole timeout |
| `UNKNOWN_IDENTITY` | the identity is not one the pool was created with |

`UNKNOWN_IDENTITY` is the one that is also a defect. It comes only from
`Pool.get` and
`Pool.get_wait`.

### Where to go deeper

- `3tk/src/pool.c3` — the whole tool, and the hooks interface.
- `3tk/test/t_pool.c3` — the three modes, put, close.
- `3tk/test/t_concurrency.c3` — the pool under many threads.
- `3tk/negative/duplicate_pool_tags.c3` — the identity set that is refused.
- `3tk/negative/pool_unknown_identity.c3` — the get that aborts.
- `3tk/negative/release_open_pool.c3` — the abort that never goes away.
- `3tk/negative/release_not_quiet_pool.c3` — the same abort, for a pool that is
  closed but has a `get_wait` still on its way out.
- `3tk/negative/release_during_on_put.c3`,
  `3tk/negative/release_during_on_close.c3` and
  `3tk/negative/release_with_straggler_put.c3` — the three hook windows, where
  the pool is closed and application code is still inside it.

---

## Part 6 — Using them together

Four things that only make sense once all three tools are in view.

- The Slot rule.
- Identity across the tools.
- Cleanup patterns.
- Concurrency, and what close leaves behind.

### The Slot rule

**The Slot is the answer. Not the return value.**

- Every call that gives you an outer takes an empty Slot and fills it.
- Every call that takes an outer from you takes a full Slot and empties it.

```text
    empty  ->  the outer is somewhere else, and not your problem
    full   ->  the outer is here, and it is yours to deal with
```

Read it after every such call.

- `send` cleared the Slot: the mailbox has the outer.
- `send` left it full: the mailbox is closed, and the outer is still yours.
- `put` cleared the Slot: the pool took the outer.
- `put` left it full: the pool refused it, and you free it.

Why an acquisition asserts the Slot is empty on entry.

- A full Slot on entry means you are about to lose the inner already in it.
- That is a leak, and it is silent.
- So it is a defect, and a checking build aborts.

Why a cleanup accepts an empty Slot.

- `release` on an empty Slot is a no-op.
- That is what makes `defer` before the acquisition safe.

```c3
Slot s;
defer MSG.release(a, &s);    // safe even if create fails
MSG.create(a, &s)!;
```

Moving an inner clears the Slot.

- `take`, `move`, `push_back_slot`, a successful `send`, a successful `put`.
- After any of them the Slot is empty, and the outer is elsewhere.

### Identity across the tools

The identity is the type, not the instance.

- Two mailboxes have the same identity. `of` cannot tell them apart.
- Two `Msg` outers have the same identity.
- The identity answers "is this a `Msg`?" and nothing else.

When the role matters, put the role in your own struct.

```c3
struct Endpoint
{
    Inner    inner;
    Mailbox* inbox;
    int      role;
}
```

- Now the role travels with the outer.
- The identity still says `Endpoint`, and that is enough to recover it.

Transporting a mailbox or a pool.

- `mailbox::to_inner` and `pool::to_inner` give the inner.
- `mailbox::of` and `pool::of` check on the way back.
- `mailbox::TYPE` and `pool::TYPE` name the two identities.
- A pool created for `Endpoint` outers holds `Endpoint` outers only.

### Cleanup patterns

**Pattern 1 — defer-release-early, for a heap outer.**

```c3
Slot s;
defer MSG.release(a, &s);
MSG.create(a, &s)!;
mb.send(&s)!;                       // s is empty; the defer is a no-op
```

The defer covers the failure path. A successful send makes it a no-op.

**Pattern 2 — defer-put-early, for a pool outer.**

```c3
Slot s;
defer p.put(&s);
p.get(Msg::typeid, AVAILABLE_OR_NEW, &s)!;
```

The outer goes back to the pool on every path out of the function.

**Pattern 3 — a received outer.**

```c3
Slot got;
if (catch mb.receive(&got, time::sec(1))) return;
defer MSG.release(a, &got);
```

Register the defer after the receive. Before it, there is nothing to free.

**Pattern 4 — a batch from close.**

```c3
InnerQueue left;
mb.close(&left);
while (Inner* inner = left.pop_front())
{
    Slot one;
    one.fill(inner);
    MSG.release(a, &one);
}
```

The mailbox never knew what the outers were. This loop does.

**What you may not do.**

- Do not free an outer that is on a chain. Take it out first.
- Do not free an outer whose inner is in a Slot the toolkit still has.
- Do not put an outer into two containers. The insert guard catches it where
  checks are live.

### Concurrency, and what close leaves behind

What is safe on many threads.

- Every `Mailbox` method.
- Every `Pool` method.

What is not.

- `InnerQueue`, `InnerStack` and `Slot` are plain values. They carry no lock.
- A queue you got from `receive_all` or from `close` is yours alone.
- An outer you are holding is yours alone. That is the whole idea.

Close, on both tools.

- Close is callable more than once. The second call takes nothing.
- A closed mailbox refuses a send and reports `CLOSED`.
- A closed pool refuses a put silently, because `put` cannot fail.
- Every waiter is woken.

Where the outers go.

| | the caller gets | the hook gets |
|---|---|---|
| `Mailbox.close` | everything left, as one queue | — |
| `Pool.close` | nothing | everything left, as one flat queue |

`wake_all` is not close.

- It wakes the current waiters and each one reports `WOKEN`.
- The mailbox stays open.

Closed is not quiet, and it is the mistake this section exists for.

A mailbox and a pool pass through four conditions, in this order:

```text
    OPEN -> CLOSED -> QUIET -> FREED
```

- `close` performs the transition to CLOSED. It refuses every call that has not
  started yet, and it wakes every thread that is waiting.
- **Quiet is a different condition.** A tool is quiet when it is closed and no
  call on it is still running. A receiver parked in `receive` has been woken by
  the close and has not yet returned to its caller: the tool is closed, and it
  is not quiet.
- **The pool has a second way to be closed and not quiet, and it is the one to
  watch.** A hook runs outside the pool's mutex, so a `put` that is inside
  `on_put` is a call still running with the mutex free, and `Pool.close` itself
  runs `on_close` after the closed flag is set. A pool can be closed, hold
  nothing, answer every new call with `CLOSED` — and still have application
  code inside it.
- `release` is legal only when the tool is quiet, and it checks that it is.
  Releasing a mailbox or a pool that is not quiet aborts in every build mode,
  the same way releasing an open one does.

The toolkit does not wait for quiet, and that is a decision rather than a gap.
A release that waited would block on application code the toolkit does not
control — a hook that never returns would be a release that never returns —
which trades one defect for a worse one. **Getting to quiet is the caller's
work, and the usual way to do it is to join the threads.**

```c3
mb.close(&left);        // CLOSED: no new call is accepted, every waiter woken
foreach (&t : workers) t.join()!!;   // QUIET: every accepted call has returned
mb.release();           // FREED
```

Close-then-release on one thread is the ordinary shape and it works without
any of this: a `close` has already returned, so it is not a call still running.
The rule is about the *other* threads.

Two things the check does not do, stated because the comfortable reading is
the wrong one.

- **It catches a violation on the schedule it happens to see.** A program that
  breaks the rule and interleaves harmlessly today passes today.
- **It says nothing about a thread that merely has the pointer.** The toolkit's
  protection begins when a call is accepted. A thread that calls `send` on a
  mailbox that was already freed is past anything a counter inside that mailbox
  could do, and always was.

One tool has exactly one owner that releases it, and that owner calls `release`
once. `release` is concurrent with nothing — not with a call, not with a close,
and not with another `release`.

One macro on each tool's internal struct exists, and it is not reachable from
outside the module at all since 3TK-58.

- `_Mbox.@closed_fast` and `_Pool.@closed_fast` are the two. Each reads the
  closed flag before taking the lock.
- They are a hint. Every caller that gets false re-reads the flag under the
  lock.
- Call `is_closed` instead.

### Outer states

An outer is in exactly one of four states.

```text
  yours          you have the pointer, and nothing else does
  in a Slot      the inner is in a Slot; the Slot says whose it is
  on a chain     a queue, a stack, or a mailbox has it
  free in a pool the pool has it, and will give it out again
```

- `is_linked` distinguishes "on a chain" from the other three.
- The Slot's two states distinguish the second.
- Nothing distinguishes "yours" from "free in a pool" by reading the outer. That
  is what the Slot rule is for.

---

## Part 7 — Beyond the toolkit

Four things outside the three tools.

- The module layout — what an import gives you.
- The modules, one by one — the eight module descriptions, labelled for the
  doc loop.
- Master — the coordination role, and why it is not a type.
- The build modes, and what changes between them.

### The module layout

One import gives the toolkit.

```c3
import mtk;
```

`mtk` is the landing page. Everything else is a submodule of it, so one import
still gives the whole toolkit.

**Eleven modules over six files.** A file is not a module: a C3 `module`
declaration opens a *section*, several sections may sit in one file, and each
carries its own imports. The standard library writes itself this way —
`atomic.c3` carries `std::atomic::types` and `std::atomic`, and `cpu_detect.c3`
carries five sections.

| module | file | what is in it |
|---|---|---|
| `mtk` | `mtk.c3` | `VERSION`, the faults, `@check`, `CHECKED` |
| `mtk::inner` | `inner.c3` | `Inner`, `Slot`, the identity and the five crossings written as methods |
| `mtk::inner::internal` | `inner.c3` | the free crossings, the chain primitives and `inner_offset` |
| `mtk::queue` | `queue.c3` | `InnerQueue` and `InnerQueueIterator` |
| `mtk::queue::internal` | `queue.c3` | `InnerQueue.@guard_insert` |
| `mtk::helper <Outer>` | `helper.c3` | `OuterHelper` and `OF` |
| `mtk::mailbox` | `mailbox.c3` | `Mailbox` |
| `mtk::mailbox::internal` | `mailbox.c3` | `_Mbox` and its methods |
| `mtk::pool::hooks` | `pool.c3` | `PoolHooks` |
| `mtk::pool` | `pool.c3` | `Pool` and `GetMode` |
| `mtk::pool::internal` | `pool.c3` | `PoolBucket`, `_Pool` and `InnerStack` |

- **REVISED by 3TK-70, 2026-09-09: eleven module names, six files, and one page
  each.** Two things drove it, and both are the docs site rather than the code.
  - **The internals had no page of their own.** `c3c docgen` groups by module
    and by nothing else and **ignores visibility entirely** — a `@private` or
    `@local` declaration is published as public — so `mtk::inner`'s page carried
    26 entries of which 13 sat below the file's internal banner. The banner is a
    comment; docgen publishes no comment and no file structure. A submodule is
    the only separation the generated page can see. `std::core::cpudetect` is the
    standard library's own precedent: it is **public**, it is called from
    `std::hash::blake3`, and it is kept off the main page purely by having a page
    of its own.
  - **`PoolHooks` is the one place where the toolkit is the caller and you are
    the implementer.** Everything else on `mtk::pool`'s page is what you call,
    and the four-clause hook charter is a contract on *your* code. It is the
    subject of `mtk::pool::hooks` now, and both pages read better for it.
  - **The criterion, so it is not overreached:** a submodule is warranted when
    **the direction of the call inverts**. `GetMode` therefore stays on
    `mtk::pool` — it is a value passed on a call *you* make. Topic is not the
    test; direction is.
  - **The intent is visibility, not preventing use**, and where an attribute and
    the split disagreed the split won. `inner_offset` lost the
    `module mtk::inner @private;` section it used to sit in, and `_Mbox` and
    `_Pool` lost `@private`: a `@private` declaration in a submodule is not
    visible to its parent, and both parents cast to them on the first line of
    every public method. `InnerStack` keeps `@local`, because nothing obstructed
    it. **No new attribute was added anywhere.**
  - **What it costs a caller.** Nothing at the user surface: a method is found
    through its receiver type, and a type identifier needs no prefix, so the
    ~16 internal method declarations and every `struct XHooks (PoolHooks)` moved
    at no cost. The twelve free macros of `mtk::inner::internal` take an
    `internal::` prefix at every call site — **two lines in all of
    `examples/`**, both already the allow-listed layering pair.

- **REVISED by 3TK-pre-65, 2026-09-07: six files, six module names, and one
  page each.** `helper.c3` and `queue.c3` went back to modules of their own,
  reversing 3TK-63's merge. The merge was built to hide `inner_offset`, and a
  probe showed a separate module hides it just as well — a macro body resolves
  against its defining module, which is the mechanism `mtk::pool` and
  `mtk::mailbox` already rely on. What the merge did do was merge the generated
  documentation: `c3c docgen` groups by module and by nothing else, so `mtk`
  became one flat page of 59 declarations, and the one generic section made the
  whole page read as parameterized by `Outer` — `Inner`, `Slot` and
  `InnerQueue` with it. `mtk` is now 36 declarations, and that is the page a
  newcomer lands on.
  - **Nothing at a call site grew.** C3 imports a module's submodules with it,
    so `import mtk;` still gives `InnerQueue` unqualified, and C3 accepts the
    last segment of a module path, so the binding line is
    `alias MSG = helper::OF{Msg};` — the same length it was.
- **REVISED by 3TK-63, 2026-09-07:** seven files, four modules — and after
  3TK-64 deletes `managed.c3`, four names for six files. `mtk::inner`,
  `mtk::helper` and `mtk::queue` are gone as names: `inner.c3` absorbed the
  crossing macros and `queue.c3` kept its content, and all three files declare
  `module mtk;`. One file is one section, and the module is the sum of them.
  **The reason is `@private`**, which in C3 reaches the module and nothing else
  — not a submodule and not the parent. The symbols worth hiding are the chain
  internals, and the only code entitled to them is the crossings and the two
  containers, so those must share a module. `inner_offset` is `@private` as a
  result; `reset` and `is_linked` are not, because `InnerStack` calls them from
  `mtk::pool`, a submodule.
- **REVISED by 3TK-62, 2026-09-07:** seven files, seven modules. `stack.c3` is
  deleted and `InnerStack` moved to the end of `pool.c3`, inside
  `module mtk::pool` — a comment banner marks the section, not a second module
  line. `mtk::stack` is gone as a name.
- Eight files, eight modules, one module per file. **REVISED by 3TK-46.** `001`
  said the core was one module spread over `mtk.c3`, `inner.c3`, `queue.c3` and
  `stack.c3`, and that `module mtk` was declared by four files. 3TK-44 split it,
  and 3TK-44's own report named this sentence as one it left standing. The table
  above is the state after that split.
- The mailbox and the pool use only the public surface of the core, and
  `run-builds.sh` tests that.

Both are optional. Valid combinations:

```text
core only                       identity and containers, no infrastructure
core + mailbox                  identity + transfer between threads
core + pool                     identity + outer reuse
core + mailbox + pool           transfer + outer reuse
```

### The modules, one by one

**Eleven module names, eleven labelled blocks. Written by 3TK-46; narrowed to
four by 3TK-63 and 3TK-62; re-split by 3TK-pre-65 and 3TK-67; brought to eleven
by 3TK-70.**

**`mtk::helper` is a labelled block now.** It used to be prose, because the
doc-loop parser matched `module X;` and a generic module line is not that shape.
3TK-70 widened the pattern in `doc_blocks.py` to accept a trailing `<...>` and a
trailing `@attr`, so the helper's description is diffed like every other rather
than checked sentence by sentence.

**A module has one description however many sections it is written in, and a
file may carry several modules.** The second is now the ordinary case:
`inner.c3`, `queue.c3` and `mailbox.c3` each carry two sections and `pool.c3`
carries three. `check-doc-loop.sh` walks sections rather than files, reports a
section with no block of its own as *section only, no block*, and separately
asserts that every labelled block here is carried by exactly one file.

Each block below is one module's description. It is delimited by an HTML
comment carrying the module's name, which is invisible in the rendered page and
exact when parsed.

```
<!-- 3tk:module mtk::NAME -->
...
<!-- /3tk:module -->
```

**A block is the whole correlation.** The source side is the `<* *>` block
directly above `module X;` in `3tk/src`. Moving one is a copy in either
direction — strip one leading space per line, or add one — and the check is a
`diff`. [3tk-doc-loop-003.md](3tk-doc-loop-003.md) says so under *Moving a
module description*.

**Every block is written in the intersection of the two renderers.** One
sentence per line, never wrapped, every identifier in backticks, no trailing
`\`, no numbered list, no table, no bold. The three restrictions are
[3tk-doc-loop-003.md](3tk-doc-loop-003.md)'s, and the no-bold is the register's.

**These eleven are the only labelled blocks in this file.** A declaration's
descriptor is not labelled and is not copied — it is judged, and checked as a
subset. That is the other kind of move.

#### `mtk`

From Part 1. No *Usual flow* exists in Part 1, so there was none to decide
about.

**REWRITTEN by 3TK-67, 2026-09-08, to orient rather than to describe.** `mtk`
holds four declarations — `VERSION`, the `faultdef` of seven, `@check` and
`CHECKED` — and the 36 that stood on its docs page were those four plus 32 from
`inner.c3`, which declared `module mtk;`. Moving `inner.c3` to `mtk::inner` made
`mtk` a landing page, and a landing page names its submodules and holds the
vocabulary they share. The inner, the Slot, the link and the crossings went to
`mtk::inner`'s block below; the queue's paragraph was already carried by
`InnerQueue` and by `mtk::queue`.

<!-- 3tk:module mtk -->
An outer-transfer and outer-reuse toolkit for concurrent C3 programs.

Three small tools, each one usable on its own.
The core is type identity for an outer, and two containers that never allocate.
`mtk::inner` is the inner, the Slot, the link and the crossings.
`mtk::queue` is the intrusive queue and its walker.
`mtk::helper` is the one thing you bind, one line per outer type.
`mtk::mailbox` is transfer of an outer between threads.
`mtk::pool` is reuse of an outer, decided by your hooks.
Mailbox and pool are both optional.
The core alone is a valid use.

Share by communicating.
Do not share access to an outer, move the outer.
One place has the outer at a time.
That gives a concurrent program with no lock around application data.

Not a container library, though `InnerQueue` is public and yours to use.
The queue and the stack exist because the mailbox and the pool need them, and a caller may use the queue directly.
The stack is private to the pool.
Not an allocator.
Every outer is allocated and freed by your code, or by your hooks.
Not a garbage collector.
The toolkit never frees an outer you gave it, except through a hook you wrote.
Not a coordinator.
There is no `Master` type.

One import gives the toolkit.
`import mtk;` gives this module and every submodule of it.
This module holds `VERSION`, the faults, `@check` and `CHECKED`.
They are the vocabulary every submodule and every user shares.
Each subject is on the page of the module that holds it.

We present you [[LOC]] lines of source.
<!-- /3tk:module -->



#### `mtk::helper <Outer>`

**Added by 3TK-pre-65, 2026-09-07. Made a labelled block by 3TK-70,
2026-09-09**, once the parser learned the generic module line.

**3TK-70 gave it the hooks paragraph, and refused it a hooks module. 3TK-74
rewrote the block and replaced the argument without disturbing the ruling.**

3TK-70 refused an inert `interface OuterHooks` on the ground that both hooks
were **optional**, so an interface on the docs site would read as mandatory when
an outer with neither was legal. **`B-1` deletes that premise: the hooks are
required now.** The ruling stands on a stronger reason, and it is about the
interface rather than about optionality — **an interface exists to carry a
choice across a boundary at runtime, and these hooks are never passed.** There
is nothing to implement and nothing to hand over, so an interface would add a
vtable dispatch to answer a question the compiler already knows, on a helper
that has no instantiation at all. A module needs declarations and these have
none: they are resolved on the type by name.

**A later stage that finds 3TK-70's sentence must not read the ruling as lapsed
with its argument.** Moving `create` and `release` into a submodule is refused
for the reason 3TK-70 gave and 3TK-74 leaves alone: it would invert the
inversion, since they are the two most-called members in the toolkit and *you*
call them.

<!-- 3tk:module mtk::helper -->
The helper, bound once per outer type.

`alias MSG = helper::OF{Msg};` — and that is the whole ceremony.
Nine members: four crossings, `inner`, `stamp`, `linked`, `create` and `release`.
It is a module of its own so that it is a page of its own, and so that nothing else in the core reads as parameterized by `Outer`.

EVERY OUTER THIS HELPER CREATES DECLARES TWO HOOKS, and the helper is where they run.
`fn void? Outer.init(&self, Allocator a)` is called by `create`, after the allocation and before the stamp.
`fn void Outer.finish(&self, Allocator a)` is called by `release`, before the Slot is emptied and the outer freed.
Neither is optional and AN EMPTY BODY IS FINE — that is how a type says it has nothing to do.

Why you must write two methods that may do nothing.
A per-type fact with no default should be stated rather than inferred from absence, and absence was the ambiguity: no `init` used to mean either this type needs none or you spelled the name wrong, and nothing could tell the two apart.
The hooks are found on the type by name, at compile time, so a wrong name used to make the branch vanish silently.
Requiring the declaration is what makes the misspelling loud, and `initialize` or `deinit` where `init` belongs is now a compile error naming your line.
(`Init` is not among the near misses: C3 refuses a method name that begins with a capital.)

Nothing is registered, and there is no interface to implement.
A hook with the wrong signature or the wrong return type is loud as well: the branch compiles and then fails.
`finish` returns plain `void`, so it cannot fail — `release` returns `void` deliberately, and a fault no caller can act on is not worth declaring.

THE CONTAINERS ARE OUTSIDE THIS.
`Mailbox` and `Pool` bind the helper for crossing and never call `create`: they allocate themselves, because they hold a mutex and a condition variable whose teardown order is the whole of their release.
The rule binds every outer the helper creates, and an outer bound only for crossing is not making `create`'s contract.

The pool's hooks are a different shape and the difference is worth one sentence, because both are inversions and the confusion is a fair one.
A pool's hooks are POLICY: one answer per pool, chosen when you create it, so you pass them in as a `PoolHooks` implementation.
An outer's hooks are the TYPE'S OWN: one answer per type, fixed forever at compile time, so you declare them on the type.
<!-- /3tk:module -->

#### `mtk::inner`

**Added by 3TK-67, 2026-09-08**, when `inner.c3` went to a module of its own so
that `mtk` could become a landing page. The text is `mtk`'s own, unchanged: the
paragraphs on the inner, the Slot, the link and the five crossings moved here
whole, because they were always this module's subject and never the root's.

<!-- 3tk:module mtk::inner -->
The inner, the Slot, the link and the crossings.

You send and receive your own struct.
The struct is the outer, and it is yours.
You give the infrastructure one thing, an `Inner` embedded in it.
From then on the infrastructure never sees your type.
It moves `Inner*`, intrusively and with the type erased.

`Inner` is the field you embed.
The chain link and the identity, in one.
The identity sits in the same field as the chain link.
The identity says what the outer type is.
A pointer to an embedded `Inner` is one outer, with the type forgotten.
It is spelled `Inner*`, because that is all it is, and 3tk transports nothing else.
`Slot` is a box that holds one `Inner*`, or nothing.
A Slot starts empty.

The Slot is how the toolkit tells you where an outer went.
Read the Slot after every call that gives or takes an outer.

The chain link is the other half of `Inner`.
`reset` clears the chain link and not the identity.
Every chain ends at an inner pointing at itself, never at null.
That is what makes `is_linked` exact.

You get your struct back by crossing once, from `Inner*` to `Outer*`.
The identity in the `Inner` is what makes that crossing safe.

`to_inner` goes from your pointer to the `Inner*`.
Null in, null out.
`from_inner` goes from an `Inner*` back to `$Type*`, and is null on an identity mismatch.
A mismatch is an answer, not a failure.
`must_from_inner` is the same, and it aborts on a mismatch.
The abort names your line.
The same three take the outer from a Slot, and five of them appear again as methods.
`from_slot` looks, and the Slot is unchanged.
`move_from_slot` takes, and on success the Slot is left empty.
None of these moves an outer.
Reading an identity and casting a pointer leave every container alone.
No alias to declare, no instantiation, no registration.

It is a module of its own so that it is a page of its own.
A user reaches it through `import mtk;` and writes `Inner` and `Slot` unqualified, as before.
<!-- /3tk:module -->


#### `mtk::inner::internal`

**Added by 3TK-70, 2026-09-09.** The second section of `inner.c3`: the free
crossings, the two chain primitives, and `inner_offset`, which folded in from
the old third section and lost its `@private` with it. Every declaration in it
has a member of `OuterHelper` that does it for you, or is a chain primitive only
the queue and the stack may touch.

<!-- 3tk:module mtk::inner::internal -->
The crossings, the chain primitives and the offset. Not the user surface.

Every declaration here has a member of `OuterHelper` that does it for you, or is a chain primitive only the queue and the stack may touch.
They are public because the compiler leaves no choice: `@private` and `@local` are both ignored on a method declaration, and `InnerStack`, in `mtk::pool`, calls two of the free functions from outside this module altogether.
`Inner.link` is public and writable besides, so this is a stated boundary and not a locked one.
It is a module of its own so that it is a page of its own.
<!-- /3tk:module -->

#### `mtk::queue`

**Added by 3TK-pre-65, 2026-09-07**, when `queue.c3` went back to a module of
its own and so earned a page of its own. Short by intent: the queue's own
description is on `InnerQueue` a few sections up, and a module block that
repeated it would say the same thing twice on the same page.

<!-- 3tk:module mtk::queue -->
The intrusive queue and its walker.

One type to carry outers from one place to another, and one to walk what it holds.
It is a module of its own so that it is a page of its own.
A user reaches it through `import mtk;` and writes `InnerQueue` unqualified, as before.
<!-- /3tk:module -->

#### `mtk::queue::internal`

**Added by 3TK-70, 2026-09-09.** One declaration — `InnerQueue.@guard_insert` —
and it is a module anyway. A rule with an exception is a rule a later stage has
to remember.

<!-- 3tk:module mtk::queue::internal -->
The queue's internals. Not the user surface.

One declaration: the insert guard, which `push_back` and `push_back_slot` call.
A caller outside `mtk::queue` is maintaining a chain by hand instead of calling the surface.
<!-- /3tk:module -->

#### `mtk::mailbox`

From Part 4's *What this is*, *Participants* and *Usual flow*. Part 4's *Usual
flow* is a numbered list with nested bullets, and neither shape survives:
**the list is left out, and its one-line summary — *Create, send, receive,
close, release.* — is carried, together with the plain sentences under each
step.** The fence is left in the reference: it is the book's worked example and
it repeats what the sentences already say.

<!-- 3tk:module mtk::mailbox -->
The mailbox. A queue of outers, with waiting.

Transfer of an outer between threads.
Create, send, receive, close, release.
Many producers, many consumers, on one mailbox.
The mailbox keeps outers. It never touches them.
A mailbox is itself an outer: it can travel through another mailbox.

The allocator is kept for life.
Nothing partially constructed is ever returned.
On send the Slot is the answer: cleared means the mailbox has the outer, untouched means the mailbox is closed and you still have the outer.
On receive an empty Slot goes in, and a full Slot comes back on success.
Every other outcome is a fault, and the Slot stays empty.
On close what was left comes back to you, as one queue.
Releasing those outers is your work.
The mailbox never knew what they were.
Close it first. Releasing an open mailbox aborts in every build mode.
Closing does not make a mailbox quiet: release it only after every call on it has returned.

The mailbox and the pool use only the public surface of the core, and `run-builds.sh` tests that.
The fields named with a leading underscore are internal. Do not read them.
<!-- /3tk:module -->

#### `mtk::mailbox::internal`

**Added by 3TK-70, 2026-09-09.** `_Mbox` and its five methods: the real mailbox
behind the opaque `Mailbox`. `_Mbox` lost its `@private` here, because
`mtk::mailbox` casts to `_Mbox*` on the first line of every public method and a
`@private` in a submodule is not visible to its parent.

<!-- 3tk:module mtk::mailbox::internal -->
The real mailbox, behind the opaque `Mailbox`. Not the user surface.

`Mailbox` is an empty typedef and this is what is behind it.
Every public method of `mtk::mailbox` casts to `_Mbox*` on its first line and works on this from there.
It is a module of its own so that it is a page of its own.
<!-- /3tk:module -->

#### `mtk::pool::hooks`

**Added by 3TK-70, 2026-09-09**, and it is the section that opens `pool.c3`, the
way `std::atomic::types` opens `atomic.c3`. It carries `PoolHooks` and the
four-clause charter that was prose on `PoolHooks`'s own declaration until this
stage. It is the one page in the toolkit whose subject is code *you* write, and
it states out loud what the toolkit had never said anywhere: your code runs
inside tk.

<!-- 3tk:module mtk::pool::hooks -->
The hooks. You implement them; the pool calls them.

This is where your code runs inside the toolkit.
The implementing struct is the context. There is no `ctx` parameter.
A hook runs outside the pool's mutex, several at once on different threads.
A hook that touches shared state protects it itself.
A hook does not call back into the pool.
A hook does not block and does not wait.
It is a module of its own so that it is a page of its own.
A user reaches it through `import mtk;` and writes `PoolHooks` unqualified, as before.
<!-- /3tk:module -->

#### `mtk::pool`

From Part 5's *What this is*, *Participants* and *Usual flow*. Part 5's *Usual
flow* is a numbered list with nested bullets: **the list is left out, and its
one-line summary — *Write the hooks, create, get, put, close, release.* — is
carried, together with the plain sentences under each step.** The block keeps
one ```c3 fence, the `put_all` loop, which was already in the source and is
there because it replaces a call the toolkit does not have. The hooks example
stays in the reference.

**One divergence found and resolved toward the reference.** The fence in
`pool.c3`'s module block once opened `while (mtk::Inner* inner = ...)`, a spelling
that named nothing: the alias was declared in `mtk::inner`, never in `mtk`
(a distinction 3TK-63 dissolved, by making the two the same module).
**3TK-47's move corrected it by copying.** 3TK-59 has since removed the alias
outright, and source and reference both write the inner as `Inner*`.

<!-- 3tk:module mtk::pool -->
Reuse of an outer, decided by your hooks. A keeper of free outers, grouped by type identity.

Write the hooks, create, get, put, close, release.
Policy is not in the pool. Policy is in the hooks.
The pool answers whether a reusable outer is free right now.
A pool is itself an outer: it can travel through a mailbox.

One bucket per identity, in a flat slice allocated once at creation.
The identity set is fixed at creation.
It is not empty, and it has no duplicate. Both are checked.
A stack and not a queue, and the reason is defect surfacing.
The hooks are a parameter of creation. A pool cannot exist without them.
`mtk::pool::hooks` is what you implement; this module is what you call.
On get an empty Slot goes in, and a full Slot comes back on success.
A free outer is taken, or `on_get` is asked to make one.
On put the Slot is the answer: cleared means the pool took the outer, unchanged means it was refused and you still have the outer.
On close nothing comes back to you. Everything goes to `on_close`.
Close it first. Releasing an open pool aborts in every build mode.
Closing does not make a pool quiet: release it only after every call on it has returned.
The mailbox gives everything back to a caller.
The pool's close gives nothing back at all.

There is no `put_all`. A caller giving a batch back writes the loop.

```c3
while (Inner* inner = batch.pop_front())
{
    Slot s;
    s.fill(inner);
    p.put(&s);
    if (s.is_full()) { batch.push_back(inner); break; }
}
```

The mailbox and the pool use only the public surface of the core, and `run-builds.sh` tests that.
<!-- /3tk:module -->

#### `mtk::pool::internal`

**Added by 3TK-70, 2026-09-09.** `PoolBucket`, `_Pool` and its methods, and
`InnerStack` — the storage container, which no 3tk signature passes. `_Pool` lost
its `@private` for the same reason `_Mbox` did; `InnerStack` keeps its `@local`,
because the stack and every caller of it are in this one section.

<!-- 3tk:module mtk::pool::internal -->
The real pool, its buckets and its stack. Not the user surface.

`Pool` is an empty typedef and this is what is behind it.
Every public method of `mtk::pool` casts to `_Pool*` on its first line and works on this from there.
The intrusive stack is here too: it is the storage container, private to the pool, and no 3tk signature passes one.
It is a module of its own so that it is a page of its own.
<!-- /3tk:module -->

#### `mtk::managed` — gone

**Deleted by 3TK-64, 2026-09-07.** The module does not exist, so it has no
description to carry. `create` and `release` are members of `OuterHelper` in
`mtk::helper`, and their sentences are in that block above.

### What is deliberately absent

A short section, and the last word on the surface: everything below was
proposed, weighed, and left out. It is here because the absences are as much a
design as the nine members are, and because a reader who does not find something
deserves to know it was refused rather than forgotten.

**Not on the helper.** `inner_offset`; the Slot's own five operations — `fill`,
`peek`, `take`, `is_empty`, `is_full`; `reset`; and the free crossing
spellings. The Slot's operations are the Slot's and gain nothing from a
per-type name, and the free `inner::` Slot forms were dead in user code — one
call site across 52 example files — before the helper existed.

**Gone from the surface entirely.** `owns`, `from`, `must_from`, `to`, `move`,
`as` as free macros, and the four free `*_from_slot` spellings. So is
`mtk::managed`, and so is `required_alloc_offset` with it.

**Two spellings of one operation survive, and both are meant to.** `inner::to_inner(outer)`,
the free macro, and `MSG.inner(&msg)`, the member that forwards to it — and the
same holds for the four crossings and the five methods beneath them. That is the
design working, because the helper adds no logic of its own. **Reach for the
member.** The free forms are documented so you can read what the member does,
and for a dispatch loop holding an `Inner*` with no helper bound for the type it
is testing.

**No dispatch construct.** A `switch` on `inner.outer_tid()` with compile-time
constant cases is the whole of it, and *Dispatch* in
[3tk-patterns-004.md](3tk-patterns-004.md) shows the four shapes that switch
takes.

**No `Allocator` field convention.** No name rule, no compile-time discovery, no
error when one is absent. The toolkit reads and writes no field of your outer
except the `Inner`.

**No struct-literal initializer.** The `init(a)` hook subsumes it: anything a
literal can set a method can set, and a method can also fail.

**No `bool`-returning hooks.** `init` returns `void?`, so the outer's own fault
reaches the caller. A `bool` says something failed and nothing about what.
`finish` returns plain `void` for the opposite reason: its fault would reach
nobody who could act on it.

**No `interface OuterHooks`, no marker type, no flag at the call site, and no
second `create`.** 3TK-74 weighed all four and refused all four. A flag at the
call site puts a fact about the *type* where it does not live, and as a runtime
`bool` it dies in a fast build. Two `create` members cannot be paired with the
right `release`, because nothing carries the choice from one to the other — the
Slot holds an `Inner*`, which has a chain link and a `typeid` and no room for a
bit. A near-miss list asserting the absence of `initialize`, `setup` and
`deinit` can only catch names someone predicted; requiring the declaration
catches **every** name that is not the right one, which makes the list
redundant.

**No `Master` type, and no coordinator.** The next section says why.

### Master — not part of the API

No `master` module.

No `Master` struct.

A Master is the coordination boundary of your subsystem. It has the mailboxes,
it has the pool, and it decides what the outers mean.

Applications build one from:

| what | where it comes from |
|---|---|
| transfer | `Mailbox*` — one or more |
| outer reuse | `Pool*` and your `PoolHooks` |
| memory | `Allocator` — who allocates and frees |
| threads | `std::thread` |
| application state | whatever the subsystem needs |

3tk gives the tools. The application assembles them.

### The build modes

The toolkit behaves differently in a checked build and a fast one.

```c3
const bool CHECKED
```

- True where the checks are live.
- Guard an expensive check of your own with it.

What is live in a safe build and gone under `--safe=no`:

- every `@check`
- every C3 contract, including `must_from_inner`'s
- the insert guards on the queue and the stack
- the duplicate scan over a pool's identity set

What never goes away:

- releasing an open mailbox aborts
- releasing an open pool aborts

That difference is the point. A defect that a fast build would carry silently
is named and stopped in a checked one, and the tests run both.

### Where to go deeper

- `3tk/run-builds.sh` — the four builds, and what each one proves.
- `3tk/negative/` — one file per defect the toolkit refuses.
- `3tk/test/t_alloc.c3` — allocation failure, on every creation path.
