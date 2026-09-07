# 3tk — the rethinking, compacted

**Written 2026-09-07. Supersedes
[3tk-rethinking-003.md](backup/3tk-rethinking-003.md), which superseded `002`
and `001`; all three are in `backup/`.**

**This is a rewrite, not an edit.** `003` was a record of arguing toward a
shape: rulings, a proposal in five sections, seven variants and fifteen
questions. The owner has since ruled most of it, and the design that survived
is **much smaller than the argument that produced it**. This document states
what is settled, ledgers what happened to every id `003` created, and lists
what is still open. **The argument is gone; the evidence is kept whole.**

**Scaffolding, not a book.** It goes to `design/backup/` with a plain `mv`,
together with [3tk-terms-001.md](3tk-terms-001.md), **once its content has
dissolved into the code and the permanent books** — 3TK-66's closing act, not
an earlier stage's.

**How to read it.** Part 1 is the design. Part 2 is the ledger — every `RT-n`,
`HR-n`, `HS-n`, `V-n`, `PL-n` and `Q-n` from `003` with one line saying what
became of it, because plan 025 and `3tk-decisions-007.md` cite those ids by
name. Part 3 is what the owner still owes. Part 4 is the measurements, carried
over whole and extended.

---

# Part 1 — The design

## 1.1 The governing rule, and the two terms

**An Outer is a long-lived heap object, and a user who does otherwise pays.**
`create` is the blessed path. No part of this design is defensive about stack
or uninitialized Outers — **but catching is not supporting**: an illegal use
still aborts loudly in a safe build.

**There are exactly two terms.** The embedded node is the **Inner**, a real C3
type and the field you lend. The embedding struct is the **Outer**, a role and
the struct you own. *Handle*, *item*, *node* and *parent* are retired.

## 1.2 The files, and what happened to them

| file | what it becomes |
|---|---|
| `inner.c3` | `Inner`, `Slot`, the link and Slot operations, **and the crossing macros** — the old `helper.c3` content moves in |
| `helper.c3` | emptied, then **refilled** with `OuterHelper` |
| `queue.c3` | unchanged in content; its **module line** is in question (`Q-12`) |
| `stack.c3` | **deleted as a file** — the content moves to the very end of `pool.c3`, private. `test/t_stack.c3` is deleted. This reverses 3TK-45 |
| `managed.c3` | **deleted.** Its content dissolves into `OuterHelper.create` / `.release` |
| `3tk/extensions/` | **has no tenant.** `xtn` was designed and then ruled away |

**The word *managed* survives in no name**, and neither does `xtn`.

## 1.3 `Inner` and `Slot`

Unchanged, with one addition: **`Inner.outer_tid()`**, an `@inline` accessor
returning `self.link.type`. It is public, and it exists so that **no user ever
writes `inner.link.type`** — the raw read `Part 7.5` confines and the one
`pool.c3:354` is flagged for. The blessed dispatch needs it (1.8).

`Inner.link` is an `any` — a `{ptr, type}` pair. The identity lives in `.type`,
the chain in `.ptr`. **`.type` is not assignable** (`MS-10`), so any write to
the identity goes through `any_make`.

## 1.4 `OuterHelper` — how a user names one

A **generic struct in a generic module**, with a **module-level instance** the
user aliases. This is the only shape that survives `M1`–`M4` and `RT-18`: a
generic module is not a value and not a type, so every legal binding costs
**one alias per Outer type** — and no more (`HR-1`).

```c3
module mtk::helper <Outer>;            // the module name is Q-10
struct OuterHelper { typeid outer_tid; }
const OuterHelper OF = { Outer::typeid };
```

and, once per Outer type, in the user's own file:

```c3
alias MSG = mtk::helper::OF{Msg};
```

**The field is carried, never trusted.** Every member compares against
`Outer::typeid`, the compile-time constant from the instantiation. **No member
reads `self.outer_tid` to decide anything** — that rule is written into the
file with its reason, because the natural line for a later maintainer is
`if (inner.link.type == self.outer_tid)`. `MS-4` demonstrated at runtime that
clobbering the field breaks nothing, which is what makes a mutable instance
safe; that immunity lasts exactly as long as this rule does.

**`Outer` is the module's type parameter and its name is the term** — not
`Type`, not `T`. It is what the user reads in the alias line and in every
diagnostic the compiler prints from inside the module.

## 1.5 The nine members

**Four crossings, and the scheme is derivable rather than memorised.** Two
independent axes: `must_` means it **aborts** on an identity mismatch, plain
means it returns null; `take` means the **Slot is emptied** on success, `look`
means it is unchanged.

| member | on mismatch | the Slot after | accepts |
|---|---|---|---|
| `look` | null | unchanged | `Slot*` **or** `Inner*` |
| `must_look` | **aborts** | unchanged | `Slot*` **or** `Inner*` |
| `take` | null | **emptied** | `Slot*` only |
| `must_take` | **aborts** | **emptied** | `Slot*` only |

**One name serves both argument types**, dispatched at compile time on
`$Typeof` (`MS-12`). `take` on an `Inner*` has nothing to empty and is a
`$assert` that names the mistake.

**This is six spellings reduced to four, and `RT-16`'s grievance answered
rather than restated.** It also fills a gap: `must_take` did not exist —
today's `move_from_slot` has no abort form.

**The other five:**

| member | does |
|---|---|
| `inner(Outer*)` | returns the `Inner*`, **stamping the identity idempotently** (1.7) |
| `init(Outer*)`\* | stamps only — for the Outer allocated by hand |
| `linked(Outer*)` | forwards to `is_linked`; 3tk's is **exact**, which is a genuine improvement over ztk |
| `create(Allocator, Slot*)` | 1.6 |
| `release(Allocator, Slot*)` | 1.6 |

\* **The name `init` collides with the user's hook** (1.6). One of the two must
be renamed — `Q-16`.

**Nine is a ceiling, not a target.** `owns`, `from`, `must_from`, `to`, `move`,
`as` and the four free `*_from_slot` spellings are all gone.

## 1.6 `create`, `release`, and the two hooks

**`create(a, slot)` — four steps, in this order:**

1. **allocate** with `a` — `alloc::new_try`, which already zeroes (`MS-2`)
2. **call the Outer's `init(a)` hook**, if it declares one
3. **stamp the `Inner`** with `Outer::typeid`
4. **fill the Slot**

On a hook failure: free the allocation and propagate. On an allocation
failure: the Slot is untouched and the fault is returned.

**`release(a, slot)`:** a no-op on an empty Slot, so a `defer` registered
before the acquisition is safe. Otherwise: cross to the `Outer*`, **call its
`destroy(a)` hook** if it declares one, empty the Slot, free with `a`.

**The hooks are optional and per-Outer**, detected at compile time with
`$defined` (`MS-13`). A type that declares neither compiles and behaves exactly
as before.

**Both hooks receive the allocator from the caller of `create`/`release`.** They
do not read it from the Outer.

**Stamping *after* the hook is deliberate.** If `init` fails, the Outer was
**never stamped**, so a pointer that escaped a failed creation can never be
mistaken for a live Outer. The hook does not need the identity, and if it
crosses anyway the stamp in `inner()` is idempotent.

**The toolkit never reads or writes any field of an Outer except the `Inner`.**
There is no `Allocator alloc` field, no name rule for one, no compile-time
discovery of one, and no error when one is absent. An Outer that wants to keep
its allocator stores the argument in its own field, under any name, in its own
`init`. **`required_alloc_offset` is deleted.**

**The `#init` literal is dropped.** The hook subsumes it — anything a struct
literal can set, a method can set, and a method can also fail.

**One constraint on the hooks, and it is not optional: the `init` hook must not
touch the Slot or any container.** It runs inside a core operation, which is
the first place the toolkit calls into user code outside the pool's declared
hooks, and `Part 12.3`'s reentrancy rules are the neighbourhood it lives in.

## 1.7 The stamp

`inner()` stamps idempotently. The identity lives in `.type` and the chain in
`.ptr`, so a stamp that preserves `.ptr` is **safe on a linked inner as well as
an unlinked one** — which is what makes the idempotence real rather than a
promise about call order.

**`.type` is not assignable** (`MS-10`), so the line is:

```c3
inner.link = any_make(inner.link.ptr, Outer::typeid);
```

**This must be written into the file with its reason.** The natural maintenance
edit is `any_make(null, …)` — which is today's `init` body verbatim — and it
silently unlinks a linked Outer. The correct line differs from the dangerous
one by a single sub-expression.

## 1.8 Dispatch

**No dispatch construct.** Users write a `switch` on the identity, with
compile-time constant cases:

```c3
switch (inner.outer_tid())
{
    case Msg::typeid: handle(MSG.must_look(inner));
    case Ack::typeid: handle(ACK.must_look(inner));
    default:          drop(inner);
}
```

**An unstamped Inner faults on this switch** — a null `typeid` gives
`ERROR: 'Out of bounds memory access.'`, not a clean `default` (`MS-11`). An
unknown *stamped* type lands in `default` correctly.

**That is why the safe-build identity check matters** and why it is not a
nicety: without stamping, the blessed dispatch crashes rather than falling
through. Where the check goes is `Q-8`.

## 1.9 What the helper does not offer

`inner_offset`, the Slot's own operations (`fill`, `peek`, `take`, `is_empty`,
`is_full`), `reset`, and the free crossing spellings. The free Slot forms are
dead in user code (`MS-1`: one site between the four of them); the Slot's own
operations are the Slot's and gain nothing from a per-type helper.

**Retiring them from the helper is not retiring them from `inner.c3`.** How
much of `inner.c3` becomes `@private` is `Q-12`, and the answer turns on
`MS-6`: **`@private` reaches the module and nothing else** — not a submodule,
not the parent — so the only lever is which symbols share a module.

**The mailbox and the pool are ordinary clients of the helper.** `_Mbox` and
`_Pool` are Outers; they take one `@private` alias each and use it for
crossings. They do **not** use `create`/`release`: their construction has four
failable steps with staged rollback, and `Mailbox.release` is a lifetime
contract check, not a free.

**Whoever knows the type allocates it.** `Mailbox` and `Pool` are opaque, so
the user cannot size them and mtk must provide `mtk::mailbox::create` and
`mtk::pool::create`. A user's Outer is known to the user, so the user allocates
it — with `OuterHelper.create`, or by hand. **This is why the core allocates
what it allocates**, and it replaces `HR-10`'s claim that the core allocates
nothing, which was false: both container constructors call `alloc::new_try`.

**A note for 3TK-66:** `create` now names three things — the two container
constructors, the helper member, and the pool's `create` hook. Same word, two
and a half meanings. The books say which is which in one place.

---

# Part 2 — The ledger

**Why this part exists.** Plan 025 and `3tk-decisions-007.md` cite these ids by
name. A compaction that silently dropped one would turn those citations into
dangling references. **Every id `003` created is here, with one line.**

## The rulings

| id | what it said | fate |
|---|---|---|
| RT-1 | an Outer is a long-lived heap object | **stands** — 1.1 |
| RT-2 | `inner.c3` absorbs the old `helper.c3` | **stands** — 1.2 |
| RT-3 | `helper.c3` refilled with `OuterHelper`, in the core | **stands**; its module *name* is `Q-10` |
| RT-4 | `stack.c3` private at the end of `pool.c3` | **stands** — reverses 3TK-45 |
| RT-5 | `managed.c3` leaves into module `xtn` under `extensions/` | **superseded** — `managed.c3` **dissolves into the helper**; `xtn` never exists. Only *the word managed survives in no name* survives |
| RT-6 | `OuterHelper` is a first-class citizen; the books lead with it | **stands** |
| RT-7 | its state is `typeid otrid` | **stands**, field renamed **`outer_tid`** |
| RT-8 | the field is carried, never trusted | **stands** — and demonstrated at runtime by `MS-4` |
| RT-9 | members forward to the macros; no logic | **amended** — true of the crossings, **not** of `create`/`release`, which are four ordered steps |
| RT-10 | the surface is designed, not mirrored | **stands**, and is fully spent |
| RT-11 | all examples use the helper; internal use undecided | **ruled** — the mailbox and the pool use it (`Q-11`) |
| RT-12 | the allocator is a parameter of `create`/`release` | **stands**, extended: **the hooks receive it too** |
| RT-13 | the `Allocator` field becomes optional; discovery moves to `xtn` | **superseded entirely** — there is no allocator-field concept; `required_alloc_offset` is deleted |
| RT-14 | `create` zero-initializes and accepts an optional `#init` | **half stands** — the zeroing; **`#init` is dropped**, the hook replaces it |
| RT-15 | the pool's create hook owes the same wording | **narrowed** — the *defaults* wording is moot; the *user fills the rest* sentence still owed |
| RT-16 | two targets: forgetting `init`, and too many names | **both discharged** — the stamp, and six spellings reduced to four |
| RT-17 | no dispatch construct; users write a `switch` | **stands**, sharpened to a switch on `outer_tid()` with constant cases |
| RT-18 | the namespace spelling is unavailable; one alias per Outer type | **stands** — 1.4 |

## The helper requirements

| id | fate |
|---|---|
| HR-1 | **held** — one alias, nine members, no second module |
| HR-2 | **held** |
| HR-3 | **amended** with RT-9 |
| HR-4 | **held** — 1.4 |
| HR-5 | **discharged** by the idempotent stamp (1.7) plus the safe-build check (`Q-8`) |
| HR-6 | **held** |
| HR-7 | **deleted** with RT-13 |
| HR-8 | **held**, restated: zeroed, plus whatever the hook sets, and the books say the rest is the user's |
| HR-9 | **held** — nothing that earns nothing was written |
| HR-10 | **moot** — `xtn` is gone, and its justification (*the core allocates nothing*) was **false**; 1.9 states the true rule |

## The proposed shape

| id | fate |
|---|---|
| HS-1 | **stands** — 1.4 |
| HS-2 | **stands** |
| HS-3 | **superseded** — `must`/`look`/`take` became the four-name scheme |
| HS-4 | **superseded** — the same names take an `Inner*`; **`owns` is dropped** |
| HS-5 | **stands**; the stamp member's name is `Q-16` |
| HS-6 | **superseded** — `create`/`release` are in the core helper |
| HS-7 | **stands** — 1.9, minus `is_linked`, kept as `linked` |
| HS-8 | **superseded** — the scheme is derivable, so the naming rule is the scheme |
| HS-9 | **stands** — the count is nine, and it is a ceiling |
| HS-10 | **amended by `MS-10`** — `.type` is not assignable; the stamp rebuilds the `any` |
| HS-11 | **stands**, and `MS-11` makes it load-bearing; placement is `Q-8` |

## The variants

| id | fate |
|---|---|
| V-1 | **open** — `Q-7`; `MS-4` has run, and the casing is forced either way |
| V-2 | **moot** — there is no second helper to embed |
| V-3 | **ruled: option C** — `look` / `must_look` / `take` / `must_take` |
| V-4 | **ruled: both** — the stamp and the safe-build check |
| V-5 | **ruled: V-5a** — `init` stays |
| V-6 | **open** — `Q-12` |
| V-7 | **open** — `Q-15` |

## The parking lot

| id | fate |
|---|---|
| PL-1 | still parked — ztk asserts no neighbours before an item leaves a Slot; 3tk asserts nothing |
| PL-2 | still parked — the owner asked for the walk in debug/safe builds only |
| PL-3 | **closed** by `MS-2` |
| PL-4 | still parked — look-only Slot functions take a mutable `Slot*` |
| PL-5 | still parked — `must_` aborts do not say what was expected and what was found |
| PL-6 | **is `Q-1`** |
| PL-7 | **ruled** — the mailbox and the pool go through `OuterHelper` |
| PL-8 | still parked — the port defects `P3` and `P4` |
| PL-9 | still parked — the dropped Part 2.5 / D7 coverage |
| PL-10 | closes in 3TK-63 — the last missing doc-loop sentence |

## The questions `003` asked

| id | fate |
|---|---|
| Q-1 | **open** — the stutter |
| Q-2 | **answered, then superseded** — `create`/`release` in the core helper; `xtn` gone |
| Q-3 | **ruled** — option C |
| Q-4 | **ruled** — nine members, `linked` kept |
| Q-5 | **moot** — `MS-5` passed |
| Q-6 | **answered** — `init` stays |
| Q-7 | **open** |
| Q-8 | **open**, and now load-bearing |
| Q-9 | **moot** — both probes are run |
| Q-10 | **open** |
| Q-11 | **answered** — road 1 |
| Q-12 | **open** |
| Q-13 | **open** |
| Q-14 | **dissolved** — with no allocator field there is nothing to name and nothing to refuse |
| Q-15 | **open** |

---

# Part 3 — What is still open

**Ten questions. None is a stage's to assume.**

1. **`Q-1` — the stutter.** After the merge the calls read
   `mtk::inner::to_inner`, and the helper has a member `inner` that would be
   reached as `mtk::inner::OF{Msg}.inner(…)`. **Decide both spellings
   together.** Blocks 3TK-63, because the sweep writes the names once either
   way.

2. **`Q-7` — `MSG` or `msg`?** `MS-4` measured that the casing is **forced in
   both directions**: an uppercase alias must alias a constant, a lowercase
   alias must alias a non-constant. So this is not *may we have lowercase* — it
   is which casing your users write, forever, in the one line they write per
   Outer type.

3. **`Q-8` — where does the safe-build identity check go?** `MS-11` makes this
   sharper than it was: an unstamped Inner **faults** on the blessed dispatch.
   Into 3TK-65 with the helper, or its own stage with `PL-2`, which is waiting
   in the same neighbourhood?

4. **`Q-10` — is `RT-3`'s module name spent?** `Q-12`'s merge needs
   `helper.c3` to declare `module mtk::inner;`. One word, once per Outer type.

5. **`Q-12` — how far does the merge go?** `V-6a`: `inner.c3` + `helper.c3` +
   `queue.c3` are one module, and the chain mutations go `@private` too.
   `V-6b`: `inner.c3` + `helper.c3` only. `V-6c`: nothing merges, and nothing
   is enforced. **`V-6c` is the status quo and should be chosen on purpose.**

6. **`Q-13` — does `run-builds.sh` assert the module surface?** With `xtn`
   gone the list is short: `mtk`, `mtk::mailbox`, `mtk::pool`. Checkable.

7. **`Q-15` — the inner field, found by name?** Zero example files change; 15
   of 15 already write `Inner inner;`, and the failure message improves from
   *"has no Inner field"* to *"must declare exactly one `Inner inner;`"*. Then
   `V-7a` (any other `Inner` is yours and ignored) or `V-7b` (an Outer on
   several chains at once). **`V-7a` forecloses nothing** — the default
   parameter serves both.

8. **`Q-16` — new. What is the helper's stamp member called?** `init` is now
   the **user's** hook, called by `create`. The helper's stamp-only member has
   zero user sites and is called by mtk twice. One of the two must be renamed,
   and the user's hook has the better claim to `init`.

9. **`Q-17` — new. Do the hooks return `bool` or `void?`** A `bool` says
   something failed and nothing about what. A C3 optional lets the Outer's own
   fault propagate out of `create` to the caller, which is what every other
   failable path in 3tk does.

10. **`Q-18` — new. Is *the `init` hook must not touch a container* a rule or a
    check?** It is the first place the toolkit calls into user code during a
    core operation. Documented, or asserted in a safe build?

**Answered in this sitting and needing no further word:** `Q-2`, `Q-3`, `Q-4`,
`Q-5`, `Q-6`, `Q-9`, `Q-11`, `Q-14`.

---

# Part 4 — The measurements

**Carried over whole, and extended.** These are evidence, not argument. `MS-1`
cost a measurement pass over 52 files; `MS-4` … `MS-13` cost compiler probes.
Nothing in them is superseded by a ruling — a ruling can make a measurement
*unused*, but not wrong.

**All probes were written in a scratch directory. Nothing under `3tk/` was
touched by any of them.**

### MS-1 — measured 2026-09-06, in this stage

**52 example files, and the user's whole vocabulary is six spellings.** Every
crossing site in `examples/`:

| spelling | sites |
|---|---|
| `managed::release` | 78 |
| `managed::create` | 61 |
| `.must(` | 26 |
| `.to(` | 25 |
| `.move(` | 4 |
| `.as(` | 4 |
| `helper::is_mine` | 1 |
| `helper::from_inner` | 1 |

**200 sites, and what is absent matters more than what is present:**

- **`init` is called zero times in `examples/`.** `managed::create` does it, 61
  times. **HR-5 is already solved for every outer a user creates** — which,
  under RT-1, is every legal outer. What remains is only the outer a user builds
  by hand.
- **The free Slot forms are dead in user code.** `from_slot` 1,
  `must_from_slot` 0, `move_from_slot` 0, `must_from_inner` 0, `to_inner` 3.
  Users reach for the **method** forms, 59 sites to 8. **RT-16's "bless one set"
  has an evidence-backed answer: bless the methods.**
- **The receiver is almost always a `Slot`.** Of the 59 method calls, about 50
  are on a Slot (`s.must` 21, `s.to` 15, `slot.must`, `got.to`, `reply.must`,
  `first.to` …) and about 9 on an `Inner*` (`inner.as` 4, `inner.to` 3,
  `Inner.to` 2). **Users work in Slots; they meet a bare `Inner*` only when
  dispatching.**
- **The container calls confirm it:** `send` 31, `put` 23, `get` 22, `receive`
  21, `push_back_slot` 3 — the Slot is the currency at every boundary.
- **Tests are the mirror image** and must not be read as user evidence:
  `to_inner` 79, `init` 63, `from_slot` 31, `from_inner` 29, methods 10. Tests
  probe the primitives on purpose. `negative/` likewise: `to_inner` 13,
  `init` 13, no method form at all.

**What this proposes for `OuterHelper`'s member list** — the owner rules:

1. **`create`** and **`release`** — 139 of the 200 sites. The centre of the API.
2. **the three Slot crossings**, in the method spelling users already chose:
   look, look-or-abort, take.
3. **two `Inner*` crossings** — check-and-cast, and assert-and-cast — for the
   dispatch sites, which RT-17 leaves as a plain `switch`.
4. **`init`** and **`to_inner`**, present but not prominent: three uses between
   them, for the outer a user built by hand.

Everything else in today's seventeen-macro surface has **no user site at all**
and is a candidate for retirement under RT-16.

### MS-2 — measured 2026-09-06, and it changes RT-14 and closes PL-3

Probed on c3c 0.8.3, three findings:

1. **C3 has no struct default field initializers.**
   `struct Cfg { int a = 7; }` does not parse — *Error: Expected ';'*. So the
   "default values declared on the type" half of RT-14 **is not available** and
   must not be planned for.
2. **But the allocator already zeroes.** `alloc::new` / `alloc::new_try` take an
   optional `#init` and, **when it is not supplied, allocate with `calloc`**
   (`std/core/alloc.c3:182-187`). Verified at runtime: every field of a freshly
   `mem::new`-ed struct reads zero.
   **Consequence: `managed::create`'s existing `alloc::new_try(a, $Type)!` is
   already zero-initializing.** The ztk comparison's claim that 3tk's `create`
   leaves the outer undefined — ztk does `item.* = .{}` (`polynode.zig:208`) —
   **was wrong. PL-3 is closed, with nothing to do.**
3. **`#init` is a real opportunity.** `mem::new(Cfg, { .a = 7, .b = 1.5 })`
   compiles and works. So **`create` can take an optional initializer and
   forward it**, which gives RT-14 a mechanism rather than a caveat: the user
   sets non-default values *at creation*, in one expression, instead of
   remembering to fill them afterwards. `$Type a = #init` is already contract-
   checked by the stdlib macro, so a bad initializer fails at compile time.

**RT-14 is therefore restated as:** `create` zero-initializes (it already does),
**accepts an optional initializer**, and the books say plainly that anything not
covered by either is the user's to fill. **RT-15's pool-hook wording follows the
same shape.**

**Superseded in part, 2026-09-07.** The `#init` half is **dropped** — the
Outer's own `init` hook replaces it (1.6), because a hook can do everything a
struct literal can and can also fail. **Point 2 above still carries the whole
no-hook case:** an Outer that declares no hook gets a zeroed, stamped object,
and that is the guarantee the books state.

**MS-3 — does anything outside `pool.c3` still reach the stack.** Measured once
already on 2026-09-06 — nothing in `examples/`, `negative/` or any other `src/`
file — **re-measure before RT-4 is built.**


### MS-4 — the instance as a mutable global, measured 2026-09-07

`003` owed this and did not run it. Run:

```c3
OuterHelper of = { Outer::typeid };
alias holder = xtn::of{Holder};
alias note   = xtn::of{Note};
```

**It works, and it instantiates per Outer type** — `distinct=true holder=true
note=true`; each instantiation carries its own correct identity, and every
member is reachable through the lowercase alias.

**The casing rule is symmetric, and that is the finding.** `003` recorded only
half of `M4`. The other half is enforced too:

> `Error: An uppercase alias is expected to alias a constant. If you want to
> alias a non-constant, make sure the alias name starts with a lower case
> letter.`

So `alias NOTE = …of{Note};` is **refused**. **A `const` forces `MSG`; a global
forces `msg`. Neither offers a choice** — which is what `Q-7` is really asking.

**`RT-8` demonstrated rather than argued.** The field was clobbered at runtime
— `holder.outer_tid = Note::typeid;` — and then crossed:

```
after clobber: otrid wrong=true
but must() still right=true
```

**The mutability is provably harmless, because no member reads the field.** One
honest limit: this proves the design is immune *as written*, not immune by
construction. It holds exactly as long as `RT-8` holds.

### MS-5 — a generic struct inline-embedding a generic struct, measured 2026-09-07

`003` owed this too, for the base/allocating split. **It passed** — and the
split it was measuring has since been ruled away, so the result is **valid and
unused.** Recorded because it cost a probe and because the shape may be wanted
again:

```c3
module xtn <Outer>;
struct XtnHelper { inline mtk::inner::OuterHelper{Outer} base; }
const XtnHelper OF = { { Outer::typeid } };
```

The generic-instantiation-as-a-type spelling `mtk::inner::OuterHelper{Outer}`
is legal in a field declaration, the nested initializer works, and **from one
alias both the embedding struct's own members and the embedded struct's members
are reachable** — `id=42 look=true`, with `release` leaving the Slot empty.

**A second result that outlived the split:** the probe's `xtn` module named no
`@private` symbol of `mtk::inner`. It used the helper's members plus
`Slot.fill` / `Slot.is_empty` / `Slot.take` and compiled. **A module outside
the core can be written against the public surface alone**, which is what
`Q-12`'s boundary has to be true for.
### MS-6 — C3 visibility, measured 2026-09-06

The question the owner asked: **`inner.c3` will hold many macros used only by
the helper, and possibly by the mailbox and the pool. How are they made
unreachable from client code and still reachable inside mtk?**

C3 0.8.3 has exactly three levels, and no fourth:

| level | reach |
|---|---|
| `@local` | the file |
| `@private` | **the module, and only that module** |
| (none) | everything |

**Measured, because the natural assumption is wrong.** A `@private` macro in
`foo::inner` is invisible to a *sibling* module, invisible to a **submodule**
(`foo::inner::sub`), and invisible to the **parent** (`foo`). The error is
`The macro 'foo::inner::secret' is '@private' and not visible from other
modules.` The module hierarchy is a naming hierarchy, not a visibility
hierarchy. **There is no package-level or friend visibility in C3.**

**The consequence, and it is the whole answer:** "internal to mtk, hidden from
clients" is not something the compiler can express across a module boundary.
The only lever is **which symbols share a module** — and a C3 module may span
many files, so co-locating by visibility unit costs no file merges. This is
what `Q-12` decides.

### MS-7 — a generic instantiated on a `@private` type, measured 2026-09-06

`Q-12`'s merge turns on a shape that M1-M4 never tested, so it was probed
before being proposed: **module `mtk::inner <Outer>` declaring `OuterHelper`, aliased
in `mtk::mailbox` on `_Mbox`, a `@private` struct of that module, with the
helper's members forwarding to `@private` macros of the base module.**

**It compiles, links and runs.** The probe carried the real `$Type::members`
offset walk, so the round trip `MBOX.from(MBOX.inner(&m)) == &m` is a genuine
result and not a zero-offset coincidence. Both halves hold:

- the helper **reaches** the base module's `@private` macros, because a generic
  module of the same name is the same module for visibility;
- a client module **cannot** reach them, and fails to compile naming the macro.

**A private type is a legal generic argument**, and the instantiation carries
no visibility of its own. One residue worth writing down: the *alias* is public
unless the declaring module marks it `@private`.

### MS-8 — the spelling of a type's `typeid`, measured 2026-09-06

Falling out of MS-7, and it corrects this document: **`Outer.typeid` does not
compile** — `Error: A type can't appear here.` — anywhere, including inside an
ordinary function. The spelling is **`Outer::typeid`**, matching the
`$Type::typeid` already in `helper.c3`. It is a compile-time constant and is
accepted both in a `const` initializer and in a mutable global, **which is one
half of V-1 already answered.** Every `Outer.typeid` in this document was
corrected to `Outer::typeid` when `003` was written.

### MS-9 — discovering the outer's fields by name, measured 2026-09-06

**The allocator half of this measurement is now unused.** The toolkit no longer
reads or writes any allocator field (1.6), so nothing keys on the name `alloc`
and there is nothing to refuse. **The inner half is live and is `Q-15`.** The
whole measurement is kept because it also records how name-keyed discovery is
written and what the improved failure message looks like.

The owner's question: **must the `Inner` be found by type, or by the name
`inner`, and may an outer carry several? May an outer carry several
`Allocator`s, or none, with only `Allocator alloc` being the one that is set?**

**What the tree already does.** Every real outer writes `Inner inner;` —
**15 of 15**. The only exception is `negative/nocompile_two_inners.c3`, which
carries `Inner a; Inner b;` on purpose. Allocators are less uniform:
`Allocator alloc;` at 28 sites, but `Allocator a;` in
`examples/035-fan_in.c3:22`, **`Allocator inner;` in `test/t_alloc.c3:36`**,
and `Allocator _alloc;` in `_Mbox` and `_Pool`.

**What C3 supports.** `$m.name == $name` inside the `$foreach` over
`$Type::members` works, and a **default macro parameter** works with it:

> `macro usz off_named($Type, $name = "inner")`

Probed on a struct carrying three `Inner` fields — `inner=24 other=8 more=40`,
and the default argument selected `24`. **Selection by name is exact and the
extra fields are simply not seen.**

**The failure message improves.** Today: *"type X has no Inner field"*.
Measured, with the name rule: *"type WrongName must declare exactly one
`Inner inner;`"* — it names the fix rather than the symptom.

**Optional, name-keyed allocator discovery**, probed on three shapes, using a
`@const` predicate to drive a `$if`:

| type | fields | result |
|---|---|---|
| `Two` | `Allocator scratch; Allocator alloc;` | **`alloc` at 32**, no error |
| `None` | no `Allocator` | *"nothing to set"*, no error — `RT-13` |
| `Named` | `Allocator a;` | *"nothing to set"* — **silently** |

**Spelling, measured while probing:** it is `$Type::name` and `$m.name`.
`.nameof` does not exist — `Error: No method or inner struct/union
'Two.nameof' found.`


### MS-10 — `any.type` is not assignable, measured 2026-09-07

Found while probing `MS-5`. `HS-10` as written in `003` said the stamp
*"assigns `.type` alone"*. **That does not compile:**

> `inner.link.type = Outer::typeid;`
> `Error: An assignable expression, like a variable, was expected here.`

The stamp must rebuild the `any`, reading the chain back out:

```c3
inner.link = any_make(inner.link.ptr, Outer::typeid);
```

**The semantics `HS-10` argued for survive** — `.ptr` is preserved, so the
stamp is still safe on a linked inner and still genuinely idempotent. **What
changes is why it is safe.** It is no longer impossible to write a partial
stamp; it is merely correct to write this one. The dangerous edit —
`any_make(null, …)`, today's `init` body verbatim — now differs from the
correct line by **one sub-expression** rather than by shape. 1.7 carries the
rule and the reason.

### MS-11 — dispatch on the identity, measured 2026-09-07

A `switch` on a `typeid` with compile-time constant cases compiles and works:

```c3
switch (i.link.type)
{
    case Msg::typeid: return "msg";
    case Ack::typeid: return "ack";
    default:          return "unknown";
}
```

`stamped: msg ack unknown` — an **unknown but stamped** type lands in `default`
correctly.

**And the finding: an unstamped Inner faults.**

```
ERROR: 'Out of bounds memory access.'
```

A null `typeid` is **not** caught by `default`. So the blessed dispatch
`RT-17` teaches will **crash** on an Outer that was never stamped, rather than
falling through. **This is the strongest argument in the design for the
idempotent stamp (1.7), and it is what makes `Q-8` load-bearing rather than
cosmetic.**

### MS-12 — one member name, two argument types, measured 2026-09-07

C3 has no function overloading, but a macro can dispatch on its argument's type
at compile time:

```c3
macro Outer* OuterHelper.look(&self, x)
{
    $if $Typeof(x) == Slot*: Inner* i = x.peek();
    $else                    Inner* i = x;
    $endif
    ...
}
```

Probed: `via slot=7  via inner=7`. **This is what lets the four-name crossing
scheme (1.5) cover both the Slot and the bare `Inner*` without eight names.**

**Spelling:** it is `$Typeof`, not `$typeof` — the lower-case form does not
exist.

### MS-13 — an optional user hook, detected at compile time, measured 2026-09-07

`create` and `release` call hooks the Outer may or may not declare. `$defined`
finds them, and a type without one compiles unchanged:

```c3
$if $defined(o.setup): return o.setup();
$else                  return true;
$endif
```

Probed on two types, one with the hook and one without: `hook=true id=42
nohook=true`. **The hook is opt-in per Outer type and costs a type that
declares none exactly nothing.**
