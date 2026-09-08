# 3tk — the boundaries

**Written 2026-09-07. Follows
[3tk-rethinking-004.md](backup/3tk-rethinking-004.md), which superseded `003`,
`002` and `001`; all four are in `backup/`.**

**The same blocks and the same flows, repartitioned.** `Inner`, `Slot`,
`InnerQueue`, `InnerStack`, the mailbox and the pool are what they were. Insert,
remove and cross are what they were. What 3TK-61 changed is **where the lines
fall**: which module a file belongs to, what is hidden and what cannot be, how
many names a user writes, where the toolkit calls into user code, and who owns
an allocation. This document is about those lines and why each one is where it
is.

**Every question the rethinking left open is ruled.** Nothing here waits on a
decision.

**Scaffolding, not a book.** It goes to `design/backup/` with a plain `mv`,
together with [3tk-terms-001.md](3tk-terms-001.md), **once its content has
dissolved into the code and the permanent books** — 3TK-66's closing act.

**How to read it.** Part 1 is the shape, in half a page. Part 2 is the whole
toolkit used once, end to end — **read only this and you can use 3tk.** Parts 3
to 6 are the surface, the structure, the invariants, and what is deliberately
absent. Appendix A is the seven C3 facts that forced these choices, each with
the compiler's own words. Appendix B is transitional bookkeeping and says when
to delete it.

---

# Part 1 — The shape

**An Outer is a long-lived heap object, and a user who does otherwise pays.**
`create` is the blessed path. No part of this design is defensive about stack or
uninitialized Outers — **but catching is not supporting**: an illegal use aborts
loudly in a safe build.

**There are exactly two terms.** The embedded node is the **Inner**, a real C3
type and the field you lend. The embedding struct is the **Outer**, a role and
the struct you own. *Handle*, *item*, *node* and *parent* are retired.

**What 3tk asks of you, complete:**

1. Embed one field, spelled exactly `Inner inner;`.
2. Write one alias, once per Outer type: `alias MSG = mtk::OF{Msg};`.
3. Cross through it: `MSG.must_look(inner)`.

Everything else — the hooks, `create`, the four crossing names, the dispatch —
is elaboration of those three lines.

**What the toolkit does with your struct: nothing.** It reads and writes the
`Inner` and no other field. It never learns your type, never stores your
allocator, never calls a method you did not declare as a hook.

---

# Part 2 — Using it, end to end

One `Msg`, from declaration to release. Every ruling in this document appears
below as code.

## 2.1 Declare the Outer

```c3
import mtk;
import std::core::mem::alloc;

struct Msg
{
    Inner inner;              // required, and required to be called `inner`
    int   code;
    char* body;
    Allocator keep;           // yours, if you want one — the toolkit never reads it
}
```

**The field must be named `inner`.** A type without it does not compile, and the
message says what to write. Any *other* `Inner`-typed field is yours and is
ignored.

**No allocator field is required, and none is special.** `Allocator keep` above
is an ordinary field with a name of your choosing. The toolkit has no opinion
about it.

## 2.2 Declare the hooks — both optional

```c3
fn void? Msg.init(&self, Allocator a)
{
    self.body = alloc::malloc_try(a, 256)!;   // a fault here aborts the create
    self.keep = a;                            // keep it if you want it
    self.code = -1;
    return;
}

fn void? Msg.destroy(&self, Allocator a)
{
    alloc::free(a, self.body);
    return;
}
```

**Both receive the allocator from the caller.** They do not read it from the
Outer — that is why no allocator field is needed.

**A type that declares neither compiles and behaves exactly as before**: the
allocation is zeroed and that is the whole initialization.

## 2.3 Bind the helper — one line per Outer type

```c3
alias MSG = mtk::OF{Msg};
```

Uppercase, because `OF` is a `const` and C3 enforces the pairing in both
directions (Appendix A.5).

## 2.4 Create, send, receive, dispatch, release

```c3
fn void? one_round_trip(Allocator a, Mailbox* mb)
{
    Slot s;
    defer MSG.release(a, &s);      // safe now: a no-op while the Slot is empty
    MSG.create(a, &s)!;            // allocate, init(a), stamp, fill the Slot

    MSG.must_look(&s).code = 7;    // reach in without disturbing the Slot
    mb.send(&s)!;                  // the Slot is empty afterwards — the mailbox has it
}

fn void? receive_one(Mailbox* mb, Allocator a)
{
    Slot s;
    mb.poll(&s)!;
    if (s.is_empty()) return;

    Inner* inner = s.take();
    switch (inner.outer_tid())
    {
        case Msg::typeid: handle(MSG.must_look(inner));
        case Ack::typeid: handle(ACK.must_look(inner));
        default:          drop(inner);
    }
}
```

**Read the Slot after every call that gives or takes an Outer.** That is the
one habit 3tk asks for, and it is unchanged from before this repartitioning.

**`defer MSG.release(a, &s);` registered *before* the create is correct and
intended.** `release` is a no-op on an empty Slot, and it returns `void`, so it
needs no `!`, no `!!` and no `(void)` cast — see 3.4 for why that mattered
enough to shape the signature.

---

# Part 3 — The surface

## 3.1 How a user names a helper

A **generic struct in a generic module**, with a **module-level constant** the
user aliases. This is the only shape C3 permits: a generic module is not a value
and not a type, so every legal binding costs **one alias per Outer type** — and
no more.

```c3
module mtk <Outer>;                       // helper.c3 — the generic section
struct OuterHelper { typeid outer_tid; }
const OuterHelper OF = { Outer::typeid };
```

**`Outer` is the module's type parameter and its name is the term** — not
`Type`, not `T`. It is what the user reads in the alias line and in every
diagnostic the compiler prints from inside the module.

**The field is carried, never trusted.** Every member compares against
`Outer::typeid`, the compile-time constant from the instantiation. **No member
reads `self.outer_tid` to decide anything** — that rule is written into the file
with its reason, because the natural line for a later maintainer is
`if (inner.link.type == self.outer_tid)`. With `OF` a `const`, no one can
clobber the field even by accident, so the rule is belt to the `const`'s braces.

## 3.2 The four crossings

**Two independent axes, so the names are derivable rather than memorised.**
`must_` **aborts** on an identity mismatch, plain returns null; `take` **empties
the Slot** on success, `look` leaves it alone.

| member | on mismatch | the Slot after | accepts |
|---|---|---|---|
| `look` | null | unchanged | `Slot*` **or** `Inner*` |
| `must_look` | **aborts** | unchanged | `Slot*` **or** `Inner*` |
| `take` | null | **emptied** | `Slot*` only |
| `must_take` | **aborts** | **emptied** | `Slot*` only |

**One name serves both argument types**, dispatched at compile time on
`$Typeof`. `take` on an `Inner*` has nothing to empty and is a `$assert` naming
the mistake.

This is **six spellings reduced to four**, and it fills a real gap: `must_take`
did not exist — the old `move_from_slot` had no abort form.

## 3.3 The other five

| member | does |
|---|---|
| `inner(Outer*)` | returns the `Inner*`, **stamping the identity idempotently** (5.1) |
| `stamp(Outer*)` | stamps only — for an Outer allocated by hand |
| `linked(Outer*)` | forwards to `is_linked`; 3tk's is **exact**, a genuine improvement over ztk |
| `create(Allocator, Slot*)` | 3.4 |
| `release(Allocator, Slot*)` | 3.4 |

**`stamp` is the member's name because `init` now belongs to the user.** The
helper's stamp-only member had zero user call sites and two internal ones; the
user's hook is written by everyone who needs it. The better name went to the
larger audience.

**Nine members is a ceiling, not a target.**

## 3.4 `create`, `release`, and the two hooks

**`create(a, slot)` — four steps, in this order:**

1. **allocate** with `a` — `alloc::new_try`, which already zeroes
2. **call the Outer's `init(a)` hook**, if it declares one
3. **stamp the `Inner`** with `Outer::typeid`
4. **fill the Slot**

On a hook failure: free the allocation and propagate the fault unchanged. On an
allocation failure: the Slot is untouched and the fault is returned.

**`create` returns `void?`.** So does the `init` hook — not `bool`. A `bool`
says something failed and nothing about what; a C3 optional lets the Outer's own
fault reach the caller, which is what every other failable path in 3tk does.

**Stamping *after* the hook is deliberate.** If `init` fails, the Outer was
**never stamped**, so a pointer that escaped a failed creation can never be
mistaken for a live Outer.

**`release(a, slot)` returns `void`, and this is not symmetry-breaking for its
own sake.** `release` is what a user writes in a `defer`, and **C3 refuses a
bare failable call in a `defer`**:

> `Error: The function returns 'void?', which is an optional and must be
> handled.`

Every workaround — `defer (void)release(…)`, `defer release(…)!!`, an
`@catch` into a local — puts noise *and a policy choice* at each of the 78
`release` sites, and the shortest of them is the one that discards the fault.
The honest reason to make it infallible is narrower than the ergonomics,
though: **a teardown fault has no recipient.** `release` runs on a path that is
usually already unwinding; nobody can act on *"freeing failed"*, and the
resource is gone either way. `init` is the opposite — it fails before anything
is committed, and its caller has a real decision to make.

**`release` in full:** a no-op on an empty Slot; otherwise cross to the
`Outer*`, call its `destroy(a)` hook if it declares one, empty the Slot, free
with `a`.

**The `destroy` hook returns `void?`, and a fault aborts in a safe build:**

```c3
$if $defined(o.destroy):
    fault f = @catch(o.destroy(a));
    $if env::COMPILER_SAFE_MODE:
        if (f) unreachable("destroy failed during release");
    $endif
$endif
```

Measured in both modes: the safe build aborts with the fault named in the
backtrace, the fast build discards it and frees. **A failing destructor is a
defect, not an outcome** — the same contract as every other `mtk::@check`.

**Both hooks receive the allocator from the caller.** They never read it from
the Outer.

**The toolkit reads and writes no field of an Outer except the `Inner`.** There
is no `Allocator alloc` field, no name rule for one, no compile-time discovery
of one, and no error when one is absent. An Outer that wants to keep its
allocator stores the argument in its own field, under any name, in its own
`init`. **`required_alloc_offset` is deleted.**

**The `#init` struct literal is dropped.** The hook subsumes it — anything a
literal can set, a method can set, and a method can also fail.

## 3.5 Dispatch

**No dispatch construct.** Users write a `switch` on the identity, with
compile-time constant cases — the shape shown in 2.4. `Inner.outer_tid()` is an
`@inline` accessor returning `self.link.type`; it exists so that **no user ever
writes `inner.link.type`**.

An **unstamped** Inner *faults* on this switch rather than reaching `default`
(Appendix A.4). An unknown but stamped type lands in `default` correctly. That
asymmetry is why the checks in 5.2 are load-bearing rather than decorative.

---

# Part 4 — The structure

## 4.1 The files, and what happened to them

| file | what it becomes |
|---|---|
| `inner.c3` | `Inner`, `Slot`, the link and Slot operations, **and the crossing macros** — the old `helper.c3` content moves in |
| `helper.c3` | emptied, then **refilled** with `OuterHelper` as the generic section |
| `queue.c3` | unchanged in content; its **module line** changes |
| `stack.c3` | **deleted as a file** — the content moves to the very end of `pool.c3`, *inside `module mtk::pool;`*. `test/t_stack.c3` is deleted. This reverses 3TK-45 |
| `managed.c3` | **deleted.** Its content dissolves into `OuterHelper.create` / `.release` |
| `3tk/extensions/` | **has no tenant.** A module `xtn` was designed and then ruled away |

**The word *managed* survives in no name**, and neither does `xtn`.

## 4.2 The modules — six names, one per file

> **REOPENED AND RE-RULED by the owner, 2026-09-07**, after `3TK-63` built the
> merge and the generated docs site was read for the first time. **`helper.c3`
> and `queue.c3` go back to modules of their own.** The paragraphs below the
> table are the original ruling, kept because the reasoning is what was
> overturned and a later reader needs to see what it was. **What replaces it is
> `4.2a`.**

| file | declares |
|---|---|
| `mtk.c3` | `module mtk;` |
| `inner.c3` | `module mtk;` |
| `queue.c3` | **`module mtk::queue;`** |
| `helper.c3` | **`module mtk::helper <Outer>;`** |
| `pool.c3` | `module mtk::pool;` — **all of it, the stack section included** |
| `mailbox.c3` | `module mtk::mailbox;` |

**Six names**, and only `mtk.c3` and `inner.c3` share one. `mtk::stack` and
`mtk::managed` remain gone; `mtk::inner` remains gone as a name, its content
being the whole of `mtk`.

### 4.2a Why the merge was reversed

**Three probes, 2026-09-07, all in the scratchpad and all recorded here because
each overturns a sentence of the original ruling.**

**One: `c3c docgen` groups by module and by nothing else.** Its entire option
list is `--json`, `--append`, `--target`, `--emit-stdlib`. So the merge did not
merely tidy the source — **it merged the documentation**, and `mtk` became one
flat page of **59 declarations**: 2 functions, 17 methods, 10 macros, 15 macro
methods, 12 types, 3 variables. The listing shows `is_empty` twice, `take`
twice in the methods and a third time in the macro methods, `to` twice and
`stamp` as both a macro and a macro method, **with nothing to tell them apart**.
Before the merge they were three pages.

**Two: one generic section makes the whole module generic in the docs.** The
emitted data reads `"mtk": { "is_generic": true, "generic_parameters":
["Outer"] }`. Eleven of the 59 declarations are parameterized by `Outer`.
**`Inner`, `Slot` and `InnerQueue` were being presented to every reader as
parameterized by a type they have nothing to do with.** This is the worst of
it, and it arrived with 3TK-64 rather than 3TK-63.

**Three: the merge was never needed to hide what it was built to hide.** A
probe of the exact shape — `module core;` with `macro usz inner_offset($Type)
@private`, and a *separate* `module core::helper <Outer>;` calling
`core::to_inner` and `core::from_slot` — **compiles and runs correctly**, while
a third module reaching for the private macro directly is still refused:

```
Error: The macro 'core::inner_offset' is '@private' and not visible from other modules.
```

That is the same mechanism `mtk::pool` and `mtk::mailbox` already rely on, and
`3TK-63` had probed it: **a macro body resolves against its defining module.**
Neither `helper.c3` nor `queue.c3` calls `inner_offset` directly; both reach it
only through `inner.c3`'s own macro bodies.

**And splitting restores the docs.** The same probe under docgen:

```
core          is_generic=False  params=None
core::helper  is_generic=True   params=['Outer']
```

**What the merge actually hid, measured against 4.3's own list:**

| symbol | hidden by the merge? |
|---|---|
| `inner_offset` | yes — **and a separate module hides it just as well** |
| `reset`, `is_linked` | **no** — 4.3 concedes it: `InnerStack` in `mtk::pool` forces them public |
| `Inner.repoint_to`, `Inner.points_to` | **no** — methods, see 4.4 |
| every `Slot.*` | **no** — same |

**One symbol, obtainable without the merge.** Three of the four rows were
already given away by 4.3 and 4.4 in their own text.

**The short prefix keeps the cost small.** C3 accepts the last module segment,
which is the rule that made c3c suggest `outers::HOLDER` in 3TK-64. Probed:
`alias MSG = helper::OF{Msg};` compiles and runs. So the binding line is the
same length it is today, and `queue::InnerQueue` costs one segment at 47 sites.

**What does not change.** `OuterHelper` keeps its name — owner's ruling,
2026-09-07. It appears 13 times in `helper.c3` and **in no other `.c3` file**,
never once qualified, so `mtk::helper::OuterHelper` is a string that would occur
in zero lines of code; and `Outer` in the name is load-bearing, where `Helper`
alone would say less and stutter worse. **`InnerStack` stays exactly as it is** —
private inside `mtk::pool`, per the owner: *"it's private, that's all."*

**`mtk` ends at 36 declarations** — `Inner`, `Slot`, the crossings,
`is_mine`/`is_linked`/`reset`/`stamp`, `@check`, `VERSION` and the faults. That
is the page a newcomer lands on.

### 4.2b The original ruling, overturned

*Kept verbatim. Read it for what was believed, not for what is true.*

Eight module names become **four**: `mtk`, `mtk <Outer>`, `mtk::mailbox`,
`mtk::pool`. `mtk::inner`, `mtk::helper`, `mtk::queue`, `mtk::stack` and
`mtk::managed` are gone.

**One C3 fact makes this arrangement possible, and it was measured**
(Appendix A.6): a module name may be **both plain and generic**, so
`mtk::to_inner(…)` and `mtk::OF{Msg}` resolve against one namespace.

**The stack goes all the way into `mtk::pool`, not into `mtk`.** An earlier
draft gave it its own `module mtk;` section at the end of `pool.c3`, on the
reasoning that core code should keep the core's private access. Two
measurements dissolved that: **`InnerStack` has no user outside `pool.c3`** —
the only references are `pool.c3:116` and `pool.c3:126`, everything else being
`test/t_stack.c3`, which is deleted — and **`mtk` declares nothing `@private`
at all**, so there is no private access to keep. The stack needs only `Inner`,
`Slot`, `repoint_to`, `reset` and `mtk::@check`, every one of them public and
reachable from a submodule.

So one file declares one module, and `InnerStack` becomes **invisible outside
`pool.c3`** rather than merely undocumented in `mtk`. That is what `RT-4` asked
for, and it is the simpler arrangement besides.

**`InnerQueue` remains a public type of `mtk`.** Only its namespace went: users
write `mtk::InnerQueue` where they wrote `mtk::queue::InnerQueue`. **`InnerStack`
does not** — it stops being a name a user can reach.

**`mailbox.c3` and `pool.c3` stay submodules on purpose.** A submodule cannot
see its parent's `@private` declarations, so the claim *"both are built on the
intrusive layer with no privileged access to it"* is enforced by the compiler
rather than asserted. That enforcement used to cover what little lived in `mtk`;
it now covers the entire core.

## 4.3 Why one module — the reason, not the tidiness

> **SUPERSEDED by 4.2a, 2026-09-07.** The argument below is why the merge was
> built. Its own two concessions — that `is_linked` and `reset` cannot be
> private, and that methods were never hideable — leave it holding a single
> symbol, `inner_offset`, which a separate module hides just as well. **The
> sentence *"C3 can express that sentence only as a module"* is false**: it can
> also express it as a private macro that only its own module's macro bodies
> call, which is what `mtk::pool` has done all along. Kept for the record.

**`@private` reaches the module and nothing else** — not a submodule, not the
parent (Appendix A.1). C3 has no package visibility and no friend declaration.
So *"who may call this"* has exactly one available answer: **do we share a
module?**

The symbols worth hiding are the chain internals — `inner_offset`, `reset`,
`is_linked`, and the link read and write. The code that needs them is
`InnerQueue`, `InnerStack`, and the crossing macros. **Those three and no others
may touch a chain**, and C3 can express that sentence only as a module. The
merge is not housekeeping; it is the mechanism.

**With one exception, and the stack ruling is what creates it.** `InnerStack`
now lives in `mtk::pool`, a submodule, which cannot see `mtk`'s privates. It
calls `mtk::inner::is_linked` (`stack.c3:59`) and `mtk::inner::reset`
(`stack.c3:107`), so **`is_linked` and `reset` cannot be `@private`** once the
move lands. They stay public and carry the same doc line the unhideable methods
carry. `inner_offset` is unaffected: neither the stack nor either container
calls it, and it can be hidden.

That is the price of the arrangement, and it is small — two free functions join
a list of methods that were never hideable anyway, and the sentence *"those
three and no others"* remains true of the code even where the compiler stops
short of enforcing it.

## 4.4 What is hidden, and what cannot be

**`@private` is ignored on method declarations** (Appendix A.2). A method is
found through its receiver type, not through a module path, so there is no
module boundary at the call site for `@private` to be checked against. The
compiler warns and then accepts the call from anywhere.

So the split is **by form, not by importance**:

| hideable — free functions and macros | not hideable — methods |
|---|---|
| `inner_offset` | `Inner.repoint_to` |
| | `Inner.points_to` |
| | every `Slot.*` — `fill`, `peek`, `take`, `is_empty`, `is_full` |
| | `InnerQueue.@guard_insert`, `InnerStack.@guard_insert` |
| | `reset` and `is_linked` — free functions, but **called by the stack from `mtk::pool`** (Part 4.3) |

**The claim is now measured, and it is stronger than it was written.** Probed
2026-09-07: **both `@private` and `@local` are ignored on methods**, and the
compiler says so rather than failing —

```
Warning: '@private' modifiers are ignored for method declarations.
Warning: '@local' modifiers are ignored for method declarations.
pub=7  hidden=8  filelocal=9
```

— the calls succeeding from another module. So `@local` is not an escape hatch
for a method either, and the fourteen internal methods of `_Mbox`, `_Pool` and
`InnerStack` cannot be hidden by any attribute.

**`repoint_to` and `points_to` stay methods and stay public.** They no longer
carry a paragraph saying why.

> **RE-RULED by the owner, 2026-09-07.** The doc line quoted below is
> **withdrawn**, at all seven places it was written. It said *"Public because C3
> cannot hide a method … It is not part of the user surface"*, and it cost three
> lines to deliver one bit, in the one place a reader of the docs site never
> looks. **What replaces it is 4.4a.**

The withdrawn line, for the record:

> **Public because C3 cannot hide a method** — `@private` is ignored on method
> declarations. It is not part of the user surface. The containers call it;
> nothing else should.

### 4.4a The doc block is the visibility marker

**Probed 2026-09-07: `c3c docgen` ignores visibility entirely.** `inner_offset`
is `@private` and is published; `_Mbox` and `_Pool` are `@private` and are
published **as public types**; `InnerStack` is `@local` and is published as a
public type — together with `enqueue`, `dequeue`, `has_queued`, `send_at`,
`_close`, `bucket_for`, `take_back`, `take_back_inner`, `push`, `pop`,
`@closed_fast` and both `@guard_insert`s. **3TK-58's opaque `Mailbox` and `Pool`
are undone on the docs site.**

A declaration with no doc block is still listed, with an empty description.

So **C3 has no way to tell the docs site what is not yours to call.** Docgen
carries exactly two signals: which module a thing lives in, and whether it has a
doc block. Therefore:

> **A declaration that is not the user surface gets `//` line comments and no
> `<* *>` block. Whether the compiler can hide it is irrelevant.**

**The marker is one line, identical everywhere, so it reads as a token and not
as prose:**

```c3
// For internal usage.
fn void Inner.repoint_to(&self, Inner* to) @inline
    => self.link = any_make(to, self.link.type);
```

**It does not say "inner".** `Inner` is a type and one of the only two terms;
*"for inner usage"* on `Inner.points_to` would be read as being about `Inner`.

**One lever, three artifacts.** The source loses seven paragraphs; the reference
book never receives the declaration, because only `<* *>` blocks are descriptors
and the doc loop harvests nothing else; the docs site shows a bare signature
with no description, which is the only "not for you" signal available.

**It sorts by audience, not by hideability** — which is what the withdrawn line
failed at. `Inner.outer_tid` and every `Slot.*` are unhideable **and** user
surface, so they keep their blocks. `Inner.repoint_to` is unhideable and **not**
user surface, so it loses its block and the apology with it.

**Where a maintainer still needs the reason it could not be hidden, it is stated
once per file under the section banner**, never again per declaration.

**Accepted gap, written down as one — owner's ruling, 2026-09-07.** The names
still appear. `_Mbox`, `_Pool` and `InnerStack` remain listed as types on the
docs site, undescribed. Docgen has no visibility filter and no exclude flag, and
feeding it a curated file list does not help because every file mixes surface
and internals. **Undescribed, not absent**, and no stage is to go looking for a
way around it.

Converting them to free functions would make them hideable at the cost of a
worse spelling at their five internal call sites — and would buy an enforcement
the language only partly grants anyway, since **`Inner.link` is itself public
and writable**. You cannot close the door; do not build half a door and call it
locked. State plainly that it is open and who is allowed through. `Slot`'s
methods and both `@guard_insert` macros carry the same sentence, written once in
one pass so it reads as a rule rather than three apologies.

**What `repoint_to` actually is, so the warning is understood:** the sole chain
mutation primitive. `Inner.link` is one `any` — `.ptr` is the chain, `.type` is
the identity — and `repoint_to` rebuilds it with a new `.ptr` and the identity
carried over. Three conventions ride on it: `to == self` means **end of chain**,
`to == null` means **off-chain**, anything else is the next Inner. A user
calling it directly can splice an Outer out of a queue that still believes it
holds it, build a cycle, or terminate a chain at null and hang every walker.
**None of it is detectable afterwards** — the field is left well-formed, merely
wrong. `points_to` only reads, and reads nothing a user could not get from the
public `link.ptr`.

## 4.5 The module list is checked

`run-builds.sh` asserts that `src/` declares **exactly** the module names 4.2
lists: nothing unexpected present, nothing expected missing. Roughly eight lines
of shell, no build cost, run once.

> **The list is now six, not four** (4.2, re-ruled 2026-09-07). **The existing
> check at `run-builds.sh:215` fails on the correct change** — it asserts
> `^module mtk::$f;` for `mailbox` and `pool` only, and the split adds
> `mtk::queue` and `mtk::helper`. **This is the same trap this part already
> warns about for the stack**: the check must move in the same pass as the
> split, or the build goes red on a right change and a stage spends its time
> hunting a phantom.

**The module line is the design.** Visibility is decided entirely by which
module a file declares, so a file drifting out of `mtk` in a way that still
compiles would silently undo the partition with no symptom. The script already
made this argument for two files; it now makes it for all of them.

**The existing grep at `run-builds.sh:230` is kept, and its comment is
rewritten to say it is the only enforcement there is** — it asserts that
`mailbox.c3` and `pool.c3` contain no `@guard_insert`, `.repoint_to`,
`any_make` or `.link =`. With the method surface unhideable, that grep is not
redundant with the compiler; it is the substitute for what the compiler will
not do.

**One trap, and it is a stage's to avoid:** `stack.c3` currently contains
`@guard_insert` and `.repoint_to`. The grep works on `pool.c3` as a *file*, so
it fires however the module lines fall: the moment the stack lands there, it
reports *"a container reaches around the InnerQueue/InnerStack surface"* and
the build goes red on a correct change. The check must be narrowed to the
container code in the same pass — it is looking for `_Pool` and `_Mbox`
reaching around the surface, not for the surface itself.

## 4.6 The containers are ordinary clients

`_Mbox` and `_Pool` are Outers. Each takes one `@private` alias and uses it for
its crossings, exactly as an application would — **`alias MBOX @private =
helper::OF{_Mbox};` once `helper` is a module of its own** (4.2).

They do **not** use `create`/`release`: their construction has four failable
steps with staged rollback, and `Mailbox.release` is a lifetime contract check,
not a free.

**Whoever knows the type allocates it.** `Mailbox` and `Pool` are opaque, so a
user cannot size them and `mtk` must provide `mtk::mailbox::create` and
`mtk::pool::create`. A user's Outer is known to the user, so the user allocates
it — with `OuterHelper.create`, or by hand and then `stamp`.

**A note for the books:** `create` now names three things — the two container
constructors, the helper member, and the pool's `create` hook. Same word, two
and a half meanings. One place says which is which.

---

# Part 5 — The invariants, and where they are checked

## 5.1 The stamp

The identity lives in `link.type`, the chain in `link.ptr`. **`.type` is not
assignable** (Appendix A.3), so any write to the identity rebuilds the whole
field:

```c3
inner.link = any_make(inner.link.ptr, Outer::typeid);
```

Because `.ptr` is preserved, the stamp is **safe on a linked Inner as well as an
unlinked one** — which is what makes its idempotence real rather than a promise
about call order. `inner()` stamps on every crossing out of an `Outer*`;
`stamp()` does it alone.

**This line must be written into the file with its reason.** The natural
maintenance edit is `any_make(null, …)` — which is the old `init` body verbatim
— and it silently unlinks a linked Outer. **The correct line differs from the
destructive one by a single sub-expression.**

## 5.2 The safe-build identity check — at both boundaries

An Inner reaches a container unstamped only if a user hand-allocated an Outer
and never called `stamp()`. The consequence is not a wrong answer but a crash
with no message, at a `switch` that looks correct (Appendix A.4).

So in a safe build, `inner.outer_tid() != null` is asserted **twice**:

- **at every crossing** — `look`, `must_look`, `take`, `must_take` — where the
  user's own line is named in the abort;
- **at every insertion** — `InnerQueue.@guard_insert` and
  `InnerStack.@guard_insert` — which catches it *earlier*, at the moment an
  unstamped Inner enters a chain, and where a message explaining the omission
  already has a home.

Both are `$if env::COMPILER_SAFE_MODE`-gated; fast builds carry nothing.

**`@guard_insert` exists in two places** — `queue.c3` and the stack — and the
stack's copy moves into `pool.c3` first. The check goes in **after** the move,
so it is written once per site and never moved afterwards.

## 5.3 The chain conventions

Unchanged, and restated here because 5.1 and 5.2 both depend on them:

- **Every chain ends at an Inner pointing at itself, never at null.** That is
  what makes `is_linked` exact and O(1).
- **`reset` clears the chain link and not the identity.** Every removal in the
  queue and the stack calls it.
- **A Slot starts empty**, holds zero or one Outer, and is read after every call
  that gives or takes one.

## 5.4 What the hooks may assume

`init` receives `&self` — a **freshly zeroed** allocation — and an allocator,
and nothing else. It holds no pointer to any Slot, mailbox or pool, so there is
no route by which it could disturb a container; no rule is needed and none is
written.

**The Outer is not stamped until `create` returns.** Anything the hook does with
`&self` is fine, including crossing back through the helper — the stamp is
idempotent, and step 3 simply writes the same value again.

**A note for whoever builds a container re-entrancy guard:** the pool's declared
hooks *are* called with the container mid-operation, and that is where such a
guard belongs. It is a container concern, not the helper's.

---

# Part 6 — What is deliberately absent

**Not on the helper:** `inner_offset`, the Slot's own operations (`fill`,
`peek`, `take`, `is_empty`, `is_full`), `reset`, and the free crossing
spellings. The free Slot forms were dead in user code — one call site across
52 example files — and the Slot's own operations are the Slot's, gaining nothing
from a per-type helper.

**Gone from the surface entirely:** `owns`, `from`, `must_from`, `to`, `move`,
`as`, and the four free `*_from_slot` spellings.

**Two spellings of one operation survive on purpose:** `mtk::to_inner(outer)`,
the free macro, and `MSG.inner(&msg)`, the member that forwards to it. That is
the design working — the helper adds no logic of its own — but the books must
say which one users reach for. **The member.**

**No dispatch construct.** No `Allocator` field convention. No struct-literal
initializer. No `bool`-returning hooks. Each was proposed, and each was dropped
because a smaller thing already did the job.

---

# Appendix A — The seven C3 facts that forced this

**Evidence, not argument.** Each was measured with `c3c` on this machine, and
each is a durable property of the language that a maintainer would otherwise
rediscover the hard way. The conclusions are already in Parts 1 to 6; what is
kept here is the fact and the compiler's own words.

**All probes were written in a scratch directory. Nothing under `3tk/` was
touched to produce them.**

## A.1 `@private` reaches the module and nothing else

Not a submodule, not the parent. C3 has **no package visibility and no friend
declaration**. A module may span many files, and **a second file declaring the
same module sees that module's privates** — measured. So module membership is
the only lever there is, and it is the whole of Part 4.3.

```
Error: The function 'mtkx::free_repoint' is '@private' and not visible from
other modules.
```

## A.2 `@private` is ignored on methods

```
Warning: '@private' modifiers are ignored for method declarations.
```

and the call from another module then **compiles and runs**. A method is
resolved through its receiver type, which names no module, so there is no
boundary at the call site to check. **Anywhere a type is visible, its methods
are visible** — and `Inner` must be visible, because every user embeds it.
This is why Part 4.4 documents rather than enforces.

## A.3 `link.type` is not assignable

```
Error: An assignable expression, like a variable, was expected here.
```

for `i.link.type = Outer::typeid;`. The identity can only be written by
rebuilding the `any` — `any_make(i.link.ptr, Outer::typeid)` — which is what
makes the stamp's correct form differ from its destructive form by one
sub-expression (5.1).

## A.4 A null typeid faults; it does not reach `default`

An uninitialized `Inner` switched on by `link.type` gives

```
ERROR: 'Out of bounds memory access.'
```

**not** a clean fall-through. A *stamped* but unknown type lands in `default`
correctly. This is the whole justification for 5.2: without the check, the
design's own recommended dispatch crashes silently on the one mistake it is
meant to catch.

## A.5 The alias casing is symmetric and forced

An uppercase alias must alias a **constant**; a lowercase alias must alias a
**non-constant**:

```
Error: An uppercase alias is expected to alias a constant. If you want to alias
a non-constant, make sure the alias name starts with a lower case letter.
```

So `const OF` forces `alias MSG`, and a mutable `of` would force `alias msg`.
**Neither offers a choice** — declaring the constant *is* choosing the casing
users write forever.

*Also measured, and now unused:* a **mutable** module-level instance works and
instantiates correctly per Outer type, and clobbering its `outer_tid` at runtime
broke nothing, because no member reads the field. That proved the design immune
*as written*; the `const` makes it immune by construction.

## A.6 A module name may be both plain and generic

```c3
module mtkx;             // Inner, Slot, the macros, the containers
module mtkx <Outer>;     // OuterHelper
```

Both sections compile, and from a user file `mtkx::to_inner(&m)` and
`alias MSG = mtkx::OF{Msg};` **both resolve against the same name.** The helper
being generic is therefore no obstacle to living in `mtk`.

## A.7 One file may hold several module sections

Measured alongside A.6. **File layout and module membership are independent.**

**This fact is recorded and not used.** It was measured to support giving the
stack its own `module mtk;` section at the end of `pool.c3`; Part 4.2 explains
why that turned out to be unnecessary, and `pool.c3` declares one module. The
fact is kept because it was paid for and because a later stage may want it.

## Spent measurements

`003` and `004` carried thirteen. The remaining six were a survey of 52 example
files (which sized the member list and killed the free Slot spellings), a
confirmation that `alloc::new_try` zeroes, the reflection spellings
(`Outer::typeid` and not `Outer.typeid`; `$Type::name`; `$Typeof` and not
`$typeof`; `$defined` for optional hooks), and a generic struct inline-embedding
another generic struct — which passed, and whose subject was then ruled away.
**Their conclusions are in Parts 1 to 6. The probes are gone.**

---

# Appendix B — Transitional id map

**Delete this appendix when `3tk-decisions-007.md` is corrected.** That is a
stage's job, not this document's, and it is the only reason the appendix exists.

`3tk-decisions-007.md` cites `RT-n`, `HR-n` and `PL-n` at roughly twenty places,
and **several of those citations are now false, not merely stale** — it still
records that `managed` leaves into `xtn`, that no type is refused for lacking an
`Allocator` field as though that field were still a concept, that `create` and
`release` live in `xtn`, and that the stutter is open. A reader of `007` today
gets the pre-ruling design. **This table is what `007` is corrected from.**

## Rulings

| id | fate |
|---|---|
| RT-1 | stands — Part 1 |
| RT-2 | stands — 4.1 |
| RT-3 | stands; the module is `mtk`, not `mtk::helper` — 4.2 |
| RT-4 | stands, and goes further — the stack lands in `mtk::pool`, invisible outside `pool.c3` — 4.1, 4.2 |
| RT-5 | **superseded** — `managed.c3` dissolves into the helper; `xtn` never exists |
| RT-6 | stands |
| RT-7 | stands, field renamed `outer_tid` |
| RT-8 | stands, and the `const` makes it structural — 3.1 |
| RT-9 | amended — true of the crossings, not of `create`/`release` |
| RT-10 | stands, fully spent |
| RT-11 | ruled — the mailbox and the pool use the helper — 4.6 |
| RT-12 | stands, extended: the hooks receive the allocator too |
| RT-13 | **superseded entirely** — no allocator-field concept; `required_alloc_offset` deleted |
| RT-14 | half stands — the zeroing; `#init` is dropped |
| RT-15 | narrowed — the *defaults* wording is moot; *the user fills the rest* still owed |
| RT-16 | discharged — the stamp, and six spellings reduced to four |
| RT-17 | stands, sharpened to a switch on `outer_tid()` — 3.5 |
| RT-18 | stands — 3.1 |

## Helper requirements

`HR-1`, `HR-2`, `HR-4`, `HR-6`, `HR-8`, `HR-9` **held**. `HR-3` amended with
`RT-9`. `HR-5` **discharged** by the idempotent stamp plus the safe-build checks
(5.1, 5.2). `HR-7` **deleted** with `RT-13`. `HR-10` **moot** — `xtn` is gone,
and its justification (*the core allocates nothing*) was **false**; 4.6 states
the true rule.

## Proposed shape

`HS-1`, `HS-2`, `HS-9`, `HS-11` **stand**. `HS-5` stands, and the stamp member
is named `stamp`. `HS-7` stands minus `is_linked`, kept as `linked`. `HS-3`,
`HS-4`, `HS-6`, `HS-8` **superseded** by the four-name scheme and by
`create`/`release` living in the core helper. `HS-10` **amended by A.3**.

## Variants

`V-1` ruled — the `const`, uppercase. `V-3` ruled — option C. `V-4` ruled —
both. `V-5` ruled — `V-5a`. `V-6` ruled — `V-6a`, extended to `mtk` itself.
`V-7` ruled — `V-7a`. `V-2` **moot**.

## Parking lot

**Still parked:** `PL-1` (ztk asserts no neighbours before an item leaves a
Slot; 3tk asserts nothing), `PL-2` (the debug-only chain walk), `PL-4`
(look-only Slot functions take a mutable `Slot*`), `PL-5` (`must_` aborts do not
say what was expected and what was found), `PL-8` (port defects `P3`, `P4`),
`PL-9` (the dropped Part 2.5 / D7 coverage).

**Newly parked:** a **container re-entrancy guard** — the pool's declared hooks
run with the container mid-operation (5.4). Same neighbourhood as `PL-2`.

**Closed:** `PL-3` (measured). `PL-6` **moot** — it was a question about the
module name `mtk::inner`, and that module no longer exists. `PL-7` ruled — 4.6.
`PL-10` closes with the merge — the last missing doc-loop sentence.

## Questions

All ten of `004`'s open questions are ruled, and their answers are in the body:
`Q-1` moot (A.6 removed the module that stuttered), `Q-7` — the `const` and
uppercase (3.1), `Q-8` — both boundaries (5.2), `Q-10` — `mtk` (4.2), `Q-12` —
`V-6a` (4.3), `Q-13` — yes (4.5), `Q-15` — by name, others ignored (2.1),
`Q-16` — `stamp` (3.3), `Q-17` — `void?`, with `release` infallible (3.4),
`Q-18` — dissolved (5.4). `Q-2` … `Q-6`, `Q-9`, `Q-11`, `Q-14` were answered in
`004` and are folded into the body here.
