# 3tk — writing the README

**`002`, written by the closing stage of plan `043`, 2026-09-17.** It replaces
`001` (`3TK-84`, 2026-09-16), now in `backup/`. **What changed:** the README is
finished; *What is decided* gained the owner's rulings from four revisions;
*What is open* was rewritten as the debt the README leaves; the mapping table
names the final sections. **Ruled by the owner, 2026-09-17:** the README stage
is closed, and the `any` border comes next.

**The subject document of [staging plan 043](https://github.com/g41797/matryoshka-ztk/blob/main/design/secondary/lang/c3/3tk-staging-plan-043.md).**

**What this is for.** The README is written over several stages, and the owner
clears the session between them. This file is what survives. A stage reads
*What is decided* and *What is open* first, and nothing else is needed to
continue.

**Its second reader is a later plan.** The wording that survives the README
becomes the module-level `<* *>` doc comments in `src/*.c3`. The mapping table
at the end is written for that plan.

---

## What is decided

**Everything in this section is the owner's ruling. A stage applies it and does
not reopen it.**

1. **The README describes systems, not features.** Which problem, and how it is
   solved. **Not a list of what the toolkit provides.**
2. **The problem comes before the solution**, and the required order below is
   followed as written.
3. **No Matryoshka term appears before the reader has seen the problem it
   answers.** *No one needs `Inner` and `Outer`. Everyone needs solutions to
   well-known problems of boring systems.*
4. **ASCII diagrams of real systems come before any Matryoshka term.**
   Simple, human-readable, not compact. **No mermaid** — the same wording later
   goes into `docgen` module blocks, where mermaid is nothing.
5. **Voice: no AI-sh words, no smart words, no advertising, no pathos.**
   Staccato, `rules-049.md` Part 6. Part 5's banned list applies.
6. **Two tiers.** The README is the base, 10,000 m. The deep dive is per module.
7. **The deep dive is the module's `<* *>` block, not a separate document.**
8. **Size: no limit.** The first budget was 200 lines of prose, ~300 the
   ceiling. **The owner lifted it on 2026-09-17**, for readability.
9. **Nothing is said in both tiers.** A section that cannot earn its lines in
   the README is deep-dive material and goes in the mapping table.
10. **Every factual claim about 3tk is checked against `src/*.c3`.** That is the
    only source of truth. Both rejected drafts failed this.
11. **The opening system is the HTTP starter shape** — handlers, a shared
    mailbox, workers. Ruled 2026-09-16. See *The opening system*.
12. **The video transcoder is out.** It makes reuse the opening pressure, and
    reuse is the last step of the required order. The README would argue
    backwards.
13. **No git. No `.c3` change** in any stage of plan 043.
14. **The print server is out**, with the transcoder. Ruled 2026-09-16.
15. **The mailbox is not the price of entry.** Inner + Outer + Pool with no
    mailbox is a supported shape and the README says so. See *The pieces are
    separable*.
16. **`Inner` is two fields**, `link` and `otrtypeid`, since INTR 12 on
    2026-09-16. **`any` is a border type** the toolkit builds only at the
    crossing into C3's own containers. The README's one code block shows the
    outer struct with an `Inner` in it — never an `any`.
17. **`O-1` is closed, 2026-09-16: one block, and one note.** The block is the
    outer struct. The note says the outer's address is found from the inner's.
    See *The code question*.
18. **`O-3` is closed, 2026-09-16: one arc, plus a closing section for Reader
    B**, carrying a note on what the mailbox adds. **The README does not open on
    the channel.** See *Two readers, and the README currently serves one*.

19. **`O-1` is changed by the owner, 2026-09-17: two C3 blocks.** The second
    shows the per-type helper — the alias, both methods, `create`, `look`,
    `release` — because *nothing to be afraid of* needs to be seen. A third,
    the `defer REQ.release` cleanup sketch, came with the slot description.
20. **More humanity.** Plain English, a developer talking to developers.
    **No smart words.** When a sentence is added, a few more plain words beat
    one clever one.
21. **Staccato formatting.** Short sentences; bullets; nested bullets,
    indented 4 spaces; a blank line before every list; no bold across lines.
22. **The last section is *The Matryoshka family*** — Odin, Zig, C3. It is
    not removed.
23. **The README names no source of its wording** — no other AI, no phrase
    attributed to a language or a person.
24. ***How to start* stays.** The owner's own section, four steps, stop at any
    of them.
25. **Tagged unions are not C3.** The workaround is named *an enum tag plus a
    union*. `MANUAL.md` §6_4_2 has only C unions.

## What is open

**The README is finished. Nothing about its text is open.**

**What it leaves as debt, owned by later plans.**

| | what | where the README depends on it | owner of the work |
|---|---|---|---|
| **D-1** | **`Slot`/`Outer` ↔ `any` does not exist.** `OuterHelper.look` takes a `Slot*` or an `Inner*` (`helper.c3:87`), never an `any` | *How to start*, step 2: *on arrival, `look` checks what arrived*. *If you already have a channel*: *Never cast. Use `look`…*. **Today both need a cast of `a.ptr`, which the README forbids** | plan `044`, the `any` border |
| **D-2** | **The `l_` examples group does not exist** | step 2 has no example behind it; the channel section names none | plan `044` |
| **D-3** | **The module `<* *>` blocks are not written from the README** | the mapping table below | a later doc-comment plan, with the `3tk-reference-013.md` re-sync |

**When `044` closes, two README passages are revised** — step 2 and the
channel section's rules — to name the real calls and the `l_` examples. **No
other README change is owed.**

---

## The reader

**The one
[why-boring.md](https://github.com/g41797/matryoshka-ztk/blob/main/kitchen/docs/addendums/why-boring.md)
describes.** Not a systems programmer. Not an async enthusiast.

- His nouns are `Customer`, `Order`, `Invoice`, `Payment`.
- Networking, databases, timers and files are infrastructure. He does not want
  them leaking into every function.
- Transport is irrelevant to him. He cares that `CreateOrder` arrived.
- He wants **one owner, one place, one decision** — not fifty things touching
  the same state.
- He measures before optimizing. Most of his time goes into understanding code.
- His horizon is years: a new teammate productive in a week, a feature added in
  five years without rewriting how the system runs.
- **Boring means predictable.** Not slow, not old.

**What follows for the README.** He is not shopping for a framework. A feature
list tells him nothing. He keeps reading only if he recognizes his own process
on the page.

## The required order

**The owner's, given 2026-09-16. Followed as written.**

```text
   ordinary background process
              |
              v
   threads with responsibilities that must exchange work
              |
              v
   communication is the center  --------->  mailbox
              |
              v
   transfer must not allocate  ----------->  intrusive
              |
              v
   infrastructure must not know
   application types  -------------------->  type erasure
              |
              v
   some structs cannot be copied,
   so the object stays at its address
              |
              v
   where do objects come from  ----------->  pool
              |
              v
   reuse needs policy  ------------------->  hooks
              |
              v
   only then: the Matryoshka model, by name
```

**Each right-hand term is introduced only once its left-hand problem has been
stated.** That is the whole discipline of this document.

### The pieces are separable, and the README must say so

**Added 2026-09-16, the owner's.** The order above reads as one staircase, and a
reader could take it to mean the mailbox is the price of entry. **It is not.**

- **Inner + Outer + Pool, with no mailbox, is a supported shape** — reuse and
  identity without message passing.
- **It is already the tree's own practice.** All six `h_pool` examples use no
  mailbox: `037`, `038`, `039`, `040`, `042`, `045`. **Measured 2026-09-16.**
  The shape is demonstrated and stated nowhere.
- **It is what the opening system's own I/O side does.** The HTTP server holds
  outers and a pool and someone else's queue — an
  `UnboundedChannel(<any>)` — and no mailbox at all. **The opening picture
  already contains the mailbox-less case; the README only has to notice it.**
- **`Slot` is useful without a mailbox too.** The transfer discipline — full to
  empty, and the empty slot is the proof — holds when the far side is a C3
  container.

**Where it goes: after the hooks, before the model is named.** One short
passage, not a section per combination. The reader takes what he needs:

```text
   Inner + Outer            identity, and a place in a chain
        +  Pool             reuse, and a policy for it
        +  Mailbox          transfer between threads
```

**What it must not become.** A matrix of supported combinations, or a
*modular / composable* claim. Say the plain thing: **the mailbox is not the
price of entry.**

### The floor: what Matryoshka brings with no Mailbox and no Pool

**Raised by the owner, 2026-09-16, and it goes further than the passage above.**
Take away the Mailbox **and** the Pool. A user keeps `Inner`/`Outer`,
`create`/`release`, `InnerQueue`, and the crossings — **and can carry his
objects over an `UnboundedChannel(<any>)` he already owns.** The question that
follows is the honest one: **what does Matryoshka bring to that user?**

**The answer, and it is checkable in `src/`.**

> **C3's `any` carries the type beside the pointer. `Inner` carries it inside
> the object.**

An `any` keeps its type only as long as the `any` does. Store it in a `void*`,
hand it to a C callback, put it in a container that carries no type — the type
is gone. **An outer with an `Inner` answers *what am I* however it travelled**,
because the answer is in the object.

**Three things, none of which needs a Mailbox or a Pool.**

- **The object knows its own type.** `otrtypeid`, written once by `stamp` or by
  `create`.
- **The object can be chained without allocating.** `InnerQueue` takes anything
  that embeds an `Inner`. Its surface is complete on its own: `push_back`,
  `push_back_slot`, `pop_front`, `take`, `append_queue`, `iter`, `len`
  (`queue.c3:30-116`).
- **The crossing back is checked, not cast.** `look` returns null on mismatch,
  `must_look` aborts, an unstamped outer is refused rather than guessed at.

**The word is not *convenient*.** It is **self-describing**, and the consequence
a reader can act on is that **the crossing back is checked instead of cast**.

**The tree already demonstrates the floor.** Ten examples use neither mailbox
nor pool — `001`, `004`, `010`, `011`, `012`, `013`, `017`, `019`, `020`, `057`
— measured 2026-09-16. Nothing states it.

### Rules for type-erased data

**To be written into the README's floor section, and later into
`mtk::inner`'s and `mtk::helper`'s deep dive.** These are what a user of `any`,
`void*` or any type-erased carrier follows.

- **The identity in the object is the truth. The identity beside the pointer is
  a hint.** Where both exist, compare them; a mismatch is a forged carrier.
- **Check at the boundary, once.** On arrival, not at every use.
- **Never cast. Cross.** `look`, `must_look`, `take`, `must_take`.
- **An unstamped outer is refused, not guessed at.**
- **3tk answers for the Matryoshka side of the boundary and says so.** What
  happens to a type-erased value on the C3 side is its user's, and no check is
  written that implies otherwise.

### Two readers, and the README currently serves one

**This is the open question the floor raises. `O-3` below.**

- **Reader A** builds a threaded background process from scratch. Communication
  is his centre. **The required order is written for him and works.**
- **Reader B** already has his I/O and his channel — **the http-template user,
  and the likeliest arrival.** His centre is not communication. It is that his
  objects lose their type at the boundary. **The mailbox is not what he came
  for.**

**Ruled by the owner, 2026-09-16: one arc, plus a closing section for B.** Keep
the required order — A's problem motivates every piece in turn, and B can follow
it. The closing section is about twenty lines: the floor, the three things, the
rules for type-erased data, the pointer to the `l_` examples, **and a note on
what the mailbox adds.**

**The closing section is where the drift belongs, not the opening.** Starting
the README from *you already have a channel* was considered and refused,
2026-09-16.

- **It assumes the reader has one.** Reader A has a hand-rolled queue or
  nothing, and the first line would lose him.
- **It makes the README a comparison document** — 3tk against a std container is
  a feature list wearing a narrative, which is what both rejected drafts were.
- **It centres C3's stdlib instead of the reader's system.** He thinks in orders
  and invoices.

**In the closing section the drift is earned**, because the problem has already
been stated: *you already have a channel; here is what it cannot do.*

### What the mailbox adds, measured

**Not *more features*.** Each one is named against a problem, and the section
says plainly that a channel is fine when the reader needs none of them.
Measured 2026-09-16 from `src/mailbox.c3` and
`/home/g41797/dev/langs/c3/lib/std/threads/unbounded_channel.c3`.

| `UnboundedChannel(<any>)` | `Mailbox` |
|---|---|
| `push` copies the `any` into a `Deque` it grows | links the outer itself. **No allocation on transfer** |
| `close` marks it closed and leaves the queue | `close(out)` **hands back everything still queued** — otherwise those outers leak |
| `pop` waits with no timeout | `receive(slot, timeout)` — `CLOSED`, `TIMEOUT`, `WOKEN`, a fixed outcome set |
| no wake | `wake_all()` — waiters return `WOKEN` with no message |
| no priority | `send_oob` goes to the front |
| unbounded | `send(slot, limit)` fails with `LIMIT` at that many of the caller's own type |
| one item per call | `receive_all(out)` takes the batch |
| one type per instantiation | **every outer type in one queue** |

**The two that carry the section are the first two.** No allocation on transfer,
and close gives the outers back. The rest is one line.

**The sentence that keeps it from reading as a pitch: a channel is fine when he
needs none of these.** It is true, and it is why the floor exists at all.

### The examples order

**Measured, and it needs less than feared.** The groups already teach
floor-first: `a_slot_and_transfer`, `b_cleanup`, `c_crossing`, `d_dispatch`,
`e_infrastructure` all come before `f_mailbox`, and `h_pool` after it.
**The reading order is already the right one.**

- **No group is renamed.** The letters are in filenames and in the catalog, and
  renaming is expensive for nothing.
- **`shc.c3` should say which groups need no mailbox and no pool.** One
  sentence, and it is the cheapest place the floor can be stated.
- **The `l_` group sits last by letter but is foundational by subject.** Worth
  knowing when it is written; not worth reordering the alphabet for.

---

## The opening system

**Handlers, a shared mailbox, workers.** From
`matryoshka-http-template/kitchen/docs/matryoshka-http-starter-readme.md`,
read 2026-09-16.

```text
   clients            the I/O part                 the process part
                  (not what 3tk is for)          (what 3tk is for)

   client 1 ---->  handler 1 ---\
   client 2 ---->  handler 2 ----\
                                  >---- shared mailbox ----> worker A
   client 3 ---->  handler 3 ----/                      \--> worker B
   client 4 ---->  handler 4 ---/
```

**Why this one.**

- **The reader has built it.** Probably with a queue he wrote himself.
- **It puts the I/O edge and the process part on one picture** — the split
  `kitchen/docs/manifesto.md` opens with, and the reason 3tk exists. The
  handlers are infrastructure. The workers are his business. **3tk lives on the
  line between them and nowhere else.**
- **3tk can show all of it.** Every claim is backed by an example that compiles:
  `035-fan_in.c3`, `036-fan_out.c3`, `034-pipeline.c3`,
  `062-send_with_limit.c3`.
- **It has an arrival.** Work comes from somewhere the reader recognizes. The
  generic Producer→Worker→Consumer of both drafts has no edge and no domain.

**How it is used: one system that grows.** The same picture three times, gaining
a piece each time.

1. **Handlers → shared mailbox → workers.** The reader's own process.
2. **The reply path.** A second mailbox, or the request carrying where to
   answer.
3. **The pool.** Because a handler allocates a request per client and throws it
   away.

**The pool and the hooks then arrive as answers to a pressure the reader has
watched build up**, not as the next two features on a list.

**One sentence the opening makes necessary.** An HTTP diagram at the top invites
the reader to think the toolkit ships a server. **It does not** — no sockets, no
event loop, no scheduler, no I/O of any kind. Saying so early is what keeps the
README honest. In both rejected drafts the same disclaimer is a bolted-on list;
here it is earned by the picture.

**The alternatives, and why they lost.**

| candidate | shows | why not the opening |
|---|---|---|
| **HTTP handlers → shared mailbox → workers** | the I/O edge, fan-in, a real domain, and why a pool follows | **chosen** |
| photo archive pipeline | a pipeline, staged work | no I/O edge; narrower domain |
| print server | contention for one device | work arrives from nowhere in particular, and the arrival is what the reader recognizes. **Ruled out 2026-09-16, with the transcoder** |
| video transcoder | heavy per-item work, reuse pressure | **out.** Reuse before the reader has felt the allocation cost |

## Tone reference

**The HTTP starter's own opening**, quoted as a tone sample and not as content:

> I build server-side systems for a living.
> Long-running, correct, boring in the best possible way.

**That is the register the README wants.** Plain, first-hand, no claim that
cannot be checked.

**What is not carried over from that file.**

- **"ownership-first", "zero-copy".** The ownership family is banned by
  `rules-049.md` Part 5, and "zero-copy" is a spec-sheet word. Say what happens:
  the object stays where it is, a pointer moves.
- **"No framework. No magic."** Honest, but it answers a question the 3tk README
  has not raised at that point.
- **The Odin-ecosystem half of its *Why this exists*.** About language adoption,
  not about the reader's process.

---

## The code question — closed

**Ruled by the owner, 2026-09-16: one code block, plus one note.**

**The block is the outer struct**, and it is the only fenced C3 in the README.

```c3
struct Request
{
    Inner inner;
    int   client_id;
    char[256] path;
}
```

**Why this one earns its lines.**

- **It is the only thing the reader writes himself.** Everything else is a call.
- **It cannot rot.** No API surface, no hooks, no allocator.
- **It shows `Inner` honestly.** Since INTR 12 the struct is two named fields,
  so there is no packing trick to explain away.

**The note: the outer's address is found from the inner's.**

- `from_inner` is `($Type*)((char*)inner - inner_offset($Type))`
  (`inner.c3`, `mtk::inner::internal`), and `inner_offset` reads the field's
  offset out of the reader's own struct **at compile time**.
- **What the reader takes from it: nothing is stored to get back.** No
  back-pointer in his struct, no registry, no map from a handle to an object.
  **That is what intrusive means in practice**, and it is why the `Inner` is
  embedded by value rather than pointed at.
- **It earns a step of the required order.** *Some structs cannot be copied, so
  the object stays at its address* — the subtraction is why the address matters.
- **Exactly one `Inner` per outer.** None is a compile error and two is a
  compile error, both by `$assert` in `inner_offset`. Worth one line: it tells
  the reader the rule is enforced, not a convention.

**What the note must not do: show the arithmetic.** The reader needs to know
nothing is stored, not how the offset is computed. **The macro belongs in
`mtk::inner`'s deep dive**, and the mapping table records that.

**Nothing else is fenced.** No `Slot` example, no `send`, no `create` — each
needs the helper alias and both required hooks before it is honest, and that is
the examples tree's job: 64 files, each one pattern, each compiled by
`t_examples.c3`. The README links there.

## Why both drafts were rejected

### Structurally

**Draft 1** — a tour of the toolkit from the inside out.

- Its headings are Matryoshka nouns: *Inner*, *Handle*, *Slot*, *Mailbox*,
  *Pool*, *Project structure*.
- The reader meets `Inner` in paragraph two and is never told what problem it
  answers.
- **It states no problem at all.** The closest is a scope note about OS threads.
- Six of its sections are bullet lists of capabilities. **A feature list cannot
  be argued with or learned from** — only compared against another list.
- Its diagrams illustrate the toolkit. Producer→Worker→Consumer appears twice,
  generic both times. **The reader never sees his own process.**
- It ends on *Project structure*, *Language*, *Status*. The last thing the
  reader is told is that the module layout may change.
- **Reordering would not save it.** There is no problem material in it to move
  to the front.

**Draft 2** — the order is right: problem first, terms last. **It is input, not
a base to polish.** It carries draft 1's factual errors and is still assembled
around the toolkit's parts rather than around a system.

### Factually

**Measured against `src/` on 2026-09-16. Six errors.**

| # | the drafts say | `src/` says |
|---|---|---|
| **F-1** | `Inner` holds a link **and** a `typeid`, drawn as two members | **The drafts were right by accident and wrong when written.** At the time, `inner.c3:17` was `struct Inner { any link; }` — one `any`. **INTR 12 changed it on 2026-09-16** to `{ Inner* link; typeid otrtypeid; }`, so two members is now correct. **A draft that happens to match is still not measured**, and the README states the shape from `src/` |
| **F-2** | `Slot slot = work;` where `work` is an `Outer*` | `inner.c3:49` — `typedef Slot = Inner*`. It holds an `Inner*`. **The assignment does not typecheck** |
| **F-3** | "Handle" is a main concept, with its own section | **Not 3tk vocabulary.** `3TK-59` ended that alias. Nothing in `src/` is called that |
| **F-4** | modules `inner / mbox / pool / extensions` | `mtk`, `mtk::inner`, `mtk::mailbox`, `mtk::pool`, `mtk::queue`, `mtk::helper`. **No `mbox`, no `extensions`** |
| **F-5** | `on_get` "initializes an object when it is obtained" | `pool.c3:368` — it is the **allocation** hook, invoked when none are free, and `GetMode` decides whether it runs at all |
| **F-6** | Mailbox has "timeout support", as a feature bullet | `mailbox.c3:126` — `receive` takes a `Duration` and its outcome set is fixed: `CLOSED`, `TIMEOUT`, `WOKEN` |

**`F-1` is closed by INTR 12 and the row is kept as a lesson.** The drafts drew
two members when the code had one; the code now has two. **The point stands: a
claim that was never measured is not made true by the code moving under it.**
The consequence that used to follow — `stamp` as a read-modify-write of the
whole field — is gone with the packing.

---

## The measured inventory

**Read 2026-09-16 from
`matryoshka-ztk/design/secondary/lang/c3/3tk/src/`. Every line number is from
that reading. Re-print before trusting one.**

`helper.c3` 187 lines, `inner.c3` 202, `mailbox.c3` 374, `mtk.c3` 78,
`pool.c3` 503, `queue.c3` 152. **1,496 total, comments included.**

### The six modules

| module | file | what it is |
|---|---|---|
| `mtk` | `mtk.c3:7` | the landing page: `VERSION`, `LOC`, eight `faultdef`s, `@check`, `CHECKED`. **No types** |
| `mtk::inner` | `inner.c3:11` | `Inner`, `Slot`, and the crossings that need no helper |
| `mtk::helper` | `helper.c3:20` | `OuterHelper`, parameterized `<Outer>` |
| `mtk::mailbox` | `mailbox.c3:9` | `Mailbox`, an opaque handle |
| `mtk::pool` | `pool.c3:8` | `Pool`, `GetMode`; `mtk::pool::hooks` holds `PoolHooks` |
| `mtk::queue` | `queue.c3:7` | `InnerQueue`, `InnerQueueIterator` |

**Each has an `::internal` submodule.** `mtk::pool` also has `mtk::pool::hooks`.
Rule 3: the partition is checked both ways by `run-builds.sh`.

### The eight faults — the whole outcome set

`mtk.c3:26-61`. **Every operation in the toolkit fails with one of these and
nothing else.**

| fault | when |
|---|---|
| `CLOSED` | the target container is closed; the operation is rejected |
| `TIMEOUT` | timed out waiting for an item |
| `NOT_AVAILABLE` | no items in the pool |
| `NOT_CREATED` | the creation hook failed to return an outer |
| `EMPTY` | the queue or mailbox is empty |
| `WOKEN` | the wait was interrupted by `wake_all()` |
| `UNKNOWN_IDENTITY` | the `typeid` is not registered in this pool |
| `LIMIT` | the send exceeded the caller's per-type limit |

**The fault-return operator is `~`**, not `?`: `return mtk::CLOSED~;`

### `Inner` and `Slot` — `inner.c3`

- **`struct Inner { Inner* link; typeid otrtypeid; }`** — `:20`. Two fields, 16
  bytes, INTR 12. `link` is the chain link; `otrtypeid` is the outer's type,
  read through `outer_tid()`.
- `Inner.outer_tid()` — `:29` — the enclosing outer's `typeid`.
- `Inner.to($Type)` — `:36` — returns `null` on mismatch.
- `Inner.as($Type)` — `:44` — **aborts** on mismatch.
- **`typedef Slot = Inner*`** — `:49`.
- `Slot.is_empty` `:54`, `Slot.is_full` `:59`, `Slot.peek` `:64`,
  `Slot.take` `:69`, `Slot.fill` `:81`.
- `Slot.to` `:93` (null on mismatch), `Slot.must` `:100` (aborts),
  `Slot.move` `:107` (takes on success).

**The transfer rule.** `take` empties the slot. `fill` requires it empty. **The
empty slot is the proof the object went somewhere else.**

### `OuterHelper` — `helper.c3`

`alias MSG = helper::OF{Msg};` — one alias per outer type. `:20-31`.

- `create(a, slot)` `:45` — allocates, runs `init`, stamps, fills the slot.
  **Frees and propagates the fault if `init` fails.**
- `release(a, slot)` `:67` — runs `finish`, empties the slot, frees.
  **No-op on an empty slot.**
- `look(from)` `:87` / `must_look(from)` `:107` — read without emptying the
  slot. Takes a `Slot*` **or** an `Inner*`.
- `take(slot)` `:127` / `must_take(slot)` `:139` — read and empty.
- `inner(outer)` `:155` — the outer's `Inner*`. **Verifies, never writes.**
  Tolerates `null`.
- `stamp(outer)` `:168` — writes the identity. **For outers allocated by hand.**
- `linked(from)` `:175` — is it in a container right now.

**Two hooks are required of every outer the helper creates** — `helper.c3:48,49`
and `:71,72`, two `$assert`s in each of `create` and `release`:

```c3
fn void? Outer.init(&self, Allocator a)
fn void  Outer.finish(&self, Allocator a)
```

**An empty body is the answer when there is nothing to do.** It is how a type
says so. Rule 7, and no stage tidies one away.

### `Mailbox` — `mailbox.c3`

`typedef Mailbox` is opaque. `create(a)` `:38`, `release(&mbox)` `:60`.

| call | line | fails with |
|---|---|---|
| `send(slot, limit = 0)` | `:82` | `CLOSED`, `LIMIT` |
| `send_oob(slot)` | `:90` | `CLOSED` |
| `poll(slot)` | `:98` | `CLOSED`, `EMPTY` |
| `receive(slot, timeout)` | `:126` | `CLOSED`, `TIMEOUT`, `WOKEN` |
| `receive_all(out)` | `:173` | `CLOSED` |
| `wake_all()` | `:198` | `CLOSED` |
| `close(out)` | `:221` | — gives back what was queued |
| `is_closed` `:239`, `is_idle` `:244`, `len` `:255` | | — |

**`limit > 0`** counts outers of the caller's own `typeid` already queued and
fails with `LIMIT` at that many. `limit == 0` is the unbounded call.
**`send_oob` has no limit** and goes to the front.

**A mailbox can itself travel through a mailbox** — `to_inner` `:26`,
`of` `:31`.

### `Pool` — `pool.c3`

`typedef Pool` is opaque. `create(a, tags, hooks)` `:60` — **the identities are
fixed at creation**, not empty and no duplicates, both checked.

| call | line | fails with |
|---|---|---|
| `get(want, mode, slot)` | `:126` | `UNKNOWN_IDENTITY`, `NOT_AVAILABLE`, `NOT_CREATED`, `CLOSED` |
| `get_wait(want, slot, timeout)` | `:185` | `CLOSED`, `TIMEOUT`, `WOKEN`, `UNKNOWN_IDENTITY` |
| `put(slot)` | `:230` | — |
| `close()` `:287`, `release()` `:102` | | — |
| `is_closed` `:312`, `is_idle` `:317`, `count_of` `:328` | | — |

**`GetMode`** — `:12-28`.

- `AVAILABLE_OR_NEW` — a pooled instance if there is one, otherwise `on_get`.
- `NEW_ONLY` — skip the pooled ones, always `on_get`.
- `AVAILABLE_ONLY` — a pooled one or `NOT_AVAILABLE`. **Never calls `on_get`.**

**`get_wait` does not invoke `on_get`** — `:178`.

**`PoolHooks`** — `pool.c3:365-386`, in `mtk::pool::hooks`:

```c3
fn void on_get(typeid want, usz in_pool, Slot* slot);
fn void on_put(usz in_pool, Slot* slot, InnerQueue* extra);
fn void on_close(InnerQueue remaining);
```

- **`on_get` is the allocation hook** — invoked when none are free. **`F-5`.**
  `slot` is empty on entry: fill it or leave it.
- **`on_put` is the reset hook.** `slot` is full on entry. `extra` starts empty;
  outers added there are taken the same way, with the same checks.
- **`on_close` gets everything the pool still held**, flattened across every
  identity, **by value. No order is promised.**
- `in_pool` is **a hint, and stale**. After the removal in `on_get`, before the
  addition in `on_put`.

**A pool can itself travel through a mailbox** — `to_inner` `:46`, `of` `:51`.

### `InnerQueue` — `queue.c3`

**Non-allocating intrusive FIFO of `Inner*`.** `:7`.

`is_empty` `:28`, `len` `:33`, `iter` `:38`, `InnerQueueIterator.next` `:43`,
`push_back` `:56`.

**The reader meets it whether or not the README names it**: `Mailbox.close`,
`Mailbox.receive_all` and `on_close` all hand one back.

### What the toolkit does not do

**Measured by absence across all six files.** No sockets. No files. No timers
beyond a `Duration` on a wait. No event loop. No polling loop. No scheduler. No
fibers. No cooperative tasks. No thread creation — **the application makes its
own threads**. No application logic.

**What it depends on**: `std::thread` (mutex, condition variable),
`std::time`, `std::core::mem::alloc`, `std::atomic::types`.

---

## Sources, and their standing

**None of these is a source of truth. `src/*.c3` is.**

| source | what it is for |
|---|---|
| `matryoshka-ztk/kitchen/docs/addendums/why-boring.md` | **the reader.** The one text that defines who this is written for |
| `matryoshka-ztk/kitchen/docs/manifesto.md` | the I/O part / process part split |
| `matryoshka-ztk/kitchen/docs/the-shape.md` | the three pains: who frees it, allocation, coupling |
| `matryoshka-ztk/design/matryoshka-concepts-003.md` | the four concepts and the order they answer each other in. **ztk vocabulary — do not carry the names across** |
| `matryoshka-http-template/kitchen/docs/matryoshka-http-starter-readme.md` | **the opening system**, and the tone reference |
| `matryoshka-ztk/design/stories/photo-archive-pipeline.md` | alternative shape. Idea fuel |
| `matryoshka-ztk/design/stories/print-server-003.md` | alternative shape, ruled out 2026-09-16. Idea fuel only |
| `~/Downloads/3tk-readme.md` | draft 2. **Input, not a base** |
| draft 1 | pasted in session 2026-09-16. **Rejected; kept here as the six errors** |

**The ztk stories and `matryoshka-concepts-003.md` are ztk.** Their vocabulary
is `PolyNode`, `ItemHandle`, `Tag`, `Master`. **3tk says `Inner`, `Outer`,
`Slot`, `Mailbox`, `Pool`.** Nothing is ported verbatim.

---

## The module mapping table

**Written for the later doc-comment plan.** Filled as the README is written.

**Two columns, and the second is the point.** *Source* is the README passage the
module block is written from. *The deep dive owes* is what had to be cut from
the README to stay inside the budget — the detail that only the module page can
carry.

| module | source passage | the deep dive owes |
|---|---|---|
| `mtk` | *Matryoshka* — six modules, eight faults | the eight faults as one outcome set; `@check` and what safe mode means |
| `mtk::inner` | *The request carries its own link*; *The request carries its own type*; *The one struct you write*; *Only the address moves* | `Inner`'s two fields and why `any` stays outside; the full `Slot` surface; `to` vs `as` vs `must`; the one-`Inner` check runs at first use as an outer, and a nested `Inner` counts as none |
| `mtk::helper` | *One helper per type does the boring part*; the `defer` sketch in *Only the address moves*; the rules in *If you already have a channel* | the two required methods and the empty body; `look`/`take`/`must_*`; `stamp` for hand-made outers; `inner`, `linked`; **the `any` crossings, once D-1 closes** |
| `mtk::mailbox` | *A queue that answers the hard questions*; *What the mailbox adds to a channel* | the fixed outcome set per call; `limit` and `send_oob`; what `close` gives back; a refused `send` leaves the slot full |
| `mtk::pool` | *Requests come from a pool*; *The rules of reuse are yours* | `GetMode`'s three policies; the three hooks and their real signatures; `in_pool` is a stale hint; `get_wait` never calls `on_get` |
| `mtk::queue` | *If you already have a channel*; *How to start*, step 1 | `iter`, `push_back`, `pop_front`, `take`, `append_queue`; where a reader meets it: `close`, `receive_all`, `on_close` |

**A row's *source* stays empty until a README passage exists for it.** An empty
source with a non-empty debt means **the whole subject is deep-dive only** —
which is the right answer for `mtk::queue`, and possibly for `mtk::inner`'s
crossings.

---

## Changelog

| version | stage | date | what changed |
|---|---|---|---|
| `002` | closing stage | 2026-09-17 | New version. README finished after four owner revisions (owner edits and a Gemini merge; English; two ChatGPT merges; staccato formatting) and the one-`Inner` claim corrected. Rulings 19–25 added; size limit lifted; *What is open* rewritten as debts D-1..D-3; mapping table re-sourced to the final sections. |
| `001` | `3TK-86` | 2026-09-16 | Revised in place. The README's solution half written; `O-4` closed; the mapping table's *source* column filled; `mtk::inner`'s debt corrected to the two-field `Inner`. |
| `001` | `3TK-85` | 2026-09-16 | Revised in place. The README's problem half written; `O-4`, the voice, opened for the owner. |
| `001` | INTR 12 | 2026-09-16 | Revised in place, same day. `O-1` and `O-3` closed; *What the mailbox adds* measured against `std::thread::channel`; the channel-first opening refused and why. `Inner` facts re-measured after INTR 12; `F-1` reframed; the print server and the transcoder ruled out; *The pieces are separable*, *The floor*, *Rules for type-erased data*, *Two readers* and *The examples order* added; `O-1` closed — one block and one note; `O-3` opened. |
| `001` | `3TK-84` | 2026-09-16 | Created. The reader, the required order, the two tiers, the size budget, both rejections with `src/` citations, the measured inventory, the opening system, the sources, the mapping table. |
