# 3tk — the rethinking

**Written 2026-09-06, in 3TK-61.**

**This document is scaffolding, not a book.** It holds the rulings and the open
work of the rethinking while they are live. The stages cite it by id, its
content dissolves into the code, the doc comments and the permanent books, and
when it is spent it moves to `design/backup/` with a plain `mv` — together with
[3tk-terms-001.md](3tk-terms-001.md), whose section 5 this document supersedes.

**It is written to survive a context clear.** 3TK-62 and every stage after it
start cold and read this file. Nothing about the rethinking lives anywhere else.

**Identifier scheme.** `RT-n` a ruling, binding. `HR-n` a requirement on the
helper. `PL-n` the parking lot — true, worth keeping, and *not* this task.
`MS-n` a measurement 3TK-61 owes. Later stages cite the id instead of
re-arguing the point.

---

## 1. Where this came from

3TK-60 closed on 2026-09-04 with two terms, `Inner` and `Outer`. Plan 024
declared a 3TK-61 about one subject — `managed.c3` pushing an `Allocator` field
onto every Outer — and said: *discussion first, producing a decisions entry,
before any `src/` change; a **62** if it turns out structural.*

It turned out structural. In session on 2026-09-06 the owner expanded 3TK-61
into a general rethinking of the core's shape and ruled most of it. **3TK-61
decides and records. It changes no `src/`.** The building is 3TK-62 and after.

---

## 2. The governing rule

> **RT-1 — An Outer is a long-lived heap object. A user who does otherwise
> pays.**

Not new: Stage A ruled on 2026-08-31 that a stack outer is illegal, because 3tk
computes an outer's address from its embedded `Inner` at every crossing, and a
stack address is valid for exactly one lexical instance of one frame. What is
new is its **force over the design**, not only over the examples.

**What it decides:**

- `create` is the blessed path — heap, defaults, identity stamped — and the
  books teach it first.
- **Do not design defensively for stack or uninitialized outers.** That case is
  illegal, not a shape to support. Proposals to accommodate garbage chain links
  are dropped.
- **Catching is not supporting.** A cheap safe-build abort that names the cause
  is still right: paying should be a loud abort, not silent corruption three
  calls later. It costs nothing in a fast build, and it is how every other rule
  in 3tk is enforced.

---

## 3. The rulings

### The files

> **RT-2 — `inner.c3` absorbs the old `helper.c3` content.** `Inner`, `Slot`,
> the link operations, the Slot operations and the low-level crossing macros
> become one file, module `mtk::inner`. The split between "the type" and "the
> crossings" is a seam the user should not have to see, and the two module
> blocks state the same paragraph twice today
> (`inner.c3:10-14` ≡ `helper.c3:7-12`).

> **RT-3 — `helper.c3` survives as a file, with new content: `OuterHelper`.**
> Module `mtk::helper`, in the core. RT-2 moves the *old* content out; this is
> not a contradiction.

> **RT-4 — `stack.c3` becomes private.** Its contents move to **the very end of
> `pool.c3`**; `src/stack.c3` and module `mtk::stack` go away.
> **`test/t_stack.c3` is deleted.** The stack is inner machinery, the pool is
> what cares, and the pool already tests the stack's one observable promise
> black-box (`t_pool.c3:545-593`, R11, last-in first-out).
> **This reverses 3TK-45** ("stack is public", 2026-08-26).

> **RT-5 — `managed.c3` leaves the core** into module **`xtn`** under
> `3tk/extensions/`. The folder is the owner's, created 2026-09-06; the module
> is named `xtn` so it sorts **after** `mtk` in the generated documentation, so
> it is top level and not `mtk::xtn`. **The word *managed* survives in no
> name — the concept dies.**

### The helper

> **RT-6 — `OuterHelper` is a first-class citizen**, not an optional
> convenience. The books lead with it; the macros are the layer beneath it.

> **RT-7 — its state is the type identity.**
> ```c3
> struct OuterHelper { typeid otrid; }
> ```
> It mirrors ztk's per-instantiation `_tag` static (`polynode.zig:118`) — which
> is Zig compensating for having no runtime type identity. C3 has `typeid` as a
> language feature, so 3tk uses the real one.
>
> **`typeid`, not `void*`**, even though a typeid is pointer-sized underneath.
> Same size, but it type-checks, it compares directly against `Inner.link.type`
> (an `any`'s `.type` *is* a `typeid`) with no cast at either end, and it says
> what it is. Spelling it `void*` would import the Zig workaround into a
> language that does not need it.

> **RT-8 — the field is carried, never trusted.** `otrid` is writable by any
> module (c3c 0.8.3 has no field-level privacy, and `inline` does not create
> any). The owner accepts that exposure, because removing the `init` trap is
> worth more. **The mitigation is free and is taken:** every member compares
> against `Outer.typeid`, the compile-time constant available inside the
> instantiation, and **never reads `self.otrid` to decide anything.** Corrupting
> the field then changes nothing, and `otrid` stays readable as a user-facing
> type token.
>
> **This must be written as a rule with its reason**, because the natural line
> for a later maintainer is `if (inner.link.type == self.otrid)`, and that one
> line reintroduces the whole problem.

> **RT-9 — the helper is implemented on the existing macros**, which are already
> tested. Its members forward. **Pure forwarding, no logic of its own** — the
> same rule the owner imposed on `t_examples.c3` wrappers in 3TK-50 step 6,
> and for the same reason: two spellings must not drift into two behaviours.

> **RT-10 — the surface is designed, not mirrored.** Helper member names need
> not match the macro names, and **not every macro need be exposed** through the
> helper.

> **RT-11 — all examples use the helper.** It is the taught path. Whether the
> mailbox and the pool use it internally is **deliberately undecided** and is
> not this task's question.

### create and release

> **RT-12 — the allocator is a parameter of `create`, and of `release`.**
> `create` allocates, so it must have one; nothing mandatory is stored anywhere.
> This is ztk's shape (`polynode.zig:201,223`).

> **RT-13 — the `Allocator` field in an Outer becomes optional**, and its
> purpose is **the Outer's own later allocations** — not a no-argument
> `release`. `create` writes it if the type has one and **simply does not if the
> type has none.** No type is refused for lacking it.
> `required_alloc_offset` (`inner.c3:195`) becomes an **optional** discovery —
> same `$Type::members` walk, "not found" is an answer, "found twice" is still
> an error — and moves to `xtn`, since nothing in the core needs it.

> **RT-14 — `create` establishes defaults only.** If C3 supports default-value
> initialization (struct default field values, `*outer = {}`) **`create` uses
> it** — to be verified against c3c 0.8.3, measured not assumed. The doc
> comment, the reference and the books state plainly: **`create` gives a
> well-formed, identity-stamped outer, not a ready one; the user still fills in
> every non-default value.**

> **RT-15 — the pool's create hook owes the same sentence.** In pool use the
> hook is where Outers are actually made, so it carries the identical rule and
> the identical wording: defaults only, the caller fills the rest. The two must
> not drift apart.

### Ergonomics

> **RT-16 — two targets, and only two.** (1) **Forgetting `init`.** (2) **Too
> many names** — about sixteen spellings for what the books call three
> operations, with the free Slot forms duplicating `Slot.to`/`.must`/`.move`
> one-for-one. Bless one set.

> **RT-17 — no dispatch construct.** The owner ruled it out: users expect to
> write a `switch` and are content doing so.

> **RT-18 — the namespace spelling is not available.** `OuterHelper(Foo).init(foo)`
> does not exist in C3. **A generic module is not a value and not a type**;
> `mtk::helper{Msg}` names nothing and `import mtk::helper{Msg}` does not parse.
> Every legal shape costs **one alias per Outer type, declared once**. Measured
> on real c3c and recorded in `matryoshka-tk`'s
> `design/secondary/lang/c3/backup/3tk-helper-proposal-001.md`, M1–M4 and M10;
> `c3-capabilities-001.md:54-91` has the working generic-module probe.

---

## 4. Helper requirements

**`HR-*` is what `OuterHelper` must do. The member list itself is not settled —
`MS-1` settles it, and the owner rules on it.**

- **HR-1 — one alias per Outer type, and no more.** The user declares the bind
  once; nothing else is required of them before first use.
- **HR-2 — the crossings are available through the helper**, so a user who
  declared one need not switch registers mid-file.
- **HR-3 — every member forwards to an `inner.c3` macro.** No logic. (RT-9)
- **HR-4 — no member reads `self.otrid` to decide anything.** (RT-8)
- **HR-5 — `init` must not be a thing the user can forget.** The helper is one
  half of the answer: one obvious per-type home for preparing an outer, and
  `create` initializes. **The mechanism for outers the helper did not create is
  still to decide** — the candidate is `to_inner` stamping the identity
  idempotently, which is never a guess because its argument is a typed `Outer*`
  and the compiler has already established the type. A safe-build check at the
  first crossing is the complement, not the alternative (RT-1: catching is not
  supporting).
- **HR-6 — `create`/`release` take the allocator.** (RT-12)
- **HR-7 — the optional allocator field is written when present, skipped when
  absent.** (RT-13)
- **HR-8 — `create` sets defaults only, and says so.** (RT-14)
- **HR-9 — the helper does not become a type-system fiction.** It exists because
  it holds a real thing and removes a real trap. If a member earns nothing, it
  is not written. The discipline that ended `Handle` in 3TK-59 applies here.
- **HR-10 — one open point, and it shapes 3TK-62's ordering.** If `create` and
  `release` are members of the **`mtk`** helper, **the core allocates** — and
  "nothing here allocates" is load-bearing in three module blocks.
  **Recommendation: mirror ztk's own split.** `mtk::helper` is the base helper
  (crossings, init, no allocation); **`xtn` is the allocating variant**
  (`create`, `release`, the optional allocator-field discovery). ztk expresses
  exactly this as `PolyHelper`'s two variants; C3 expresses it as two modules
  and needs no `no_create_destroy` opt-out, because an uncalled C3 macro
  generates nothing. **Owner's call.**

---

## 5. The measurement — what it owes, and what it found

**MS-1 — the helper's member list, from evidence.** The `examples/` tree is
about forty files of real usage written against the current API, plus `test/`,
`negative/` and the pattern catalog's code shapes. Count, do not impress:

1. every call to `init`, `to_inner`, `from_inner`, `must_from_inner`,
   `is_mine`, the three free Slot forms and the five method forms — **free
   spelling versus method spelling, per site**. This table decides most of the
   member list and names the spellings nobody uses (RT-16).
2. **what the user writes around each crossing** — the boilerplate that would
   collapse into a member.
3. **how outers are created today** — `managed::create`, hand allocation, or a
   pool hook (RT-1 makes this the interesting one).
4. **where `init` sits relative to first use** (HR-5).
5. **a per-file count of the sites each build stage would touch**, so 3TK-62 and
   after are sized rather than guessed.

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

**MS-3 — does anything outside `pool.c3` still reach the stack.** Measured once
already on 2026-09-06 — nothing in `examples/`, `negative/` or any other `src/`
file — **re-measure before RT-4 is built.**

---

## 6. The parking lot

**True, worth keeping, and not this task.** Recorded so nothing is lost and
nothing is smuggled into the wrong stage.

- **PL-1 — a real dropped safety check.** ztk asserts the item has no neighbours
  before it leaves a Slot — `moveFromSlot` (`polynode.zig:183`) and `destroy`
  (`:229`), both documented. C3's `move_from_slot` (`helper.c3:131`) and
  `managed::release` have **neither**. 3tk is the port where the check would be
  strictly better, because its `is_linked` is exact.
- **PL-2 — the second insert guard.** ztk guards every insert twice under
  safety: an O(n) `_holds` address walk **and** `is_linked` (`:415`). 3tk has
  only the second (`queue.c3:63`, `stack.c3:55`). **Owner: add the walk,
  debug/safe builds only.** Record *why it differs*: ztk needs the walk because
  its `is_linked` is blind to a list's sole member (`:79`); 3tk's self-pointing
  chain end makes `is_linked` exact, so **in 3tk the walk guards chain
  corruption, not double-insert.**
- **PL-3 — CLOSED by MS-2, 2026-09-06, with nothing to do.** The claim was that
  3tk's `create` leaves the outer undefined where ztk does `item.* = .{}`
  (`polynode.zig:208`). It is false: `alloc::new_try` without an `#init`
  allocates with `calloc`, so the outer is already zeroed. Recorded rather than
  deleted, so nobody re-raises it.
- **PL-4 — look-only Slot functions take a mutable `Slot*`.** ztk uses
  `*const Slot`, so its signature says "this does not empty the Slot" without
  the reader having to trust prose.
- **PL-5 — `must_` aborts do not say what they expected and what they found.**
  Both are in hand at the abort site.
- **PL-6 — the stutter RT-2 creates.** After the merge the calls read
  `inner::to_inner(&foo)`, `inner::from_inner(n, Foo)` — the module says
  *inner*, the function says it again. `inner::to` / `inner::from` reads better,
  **but 3TK-60 just ruled the `to_inner`/`from_inner` spelling**, so this is the
  owner's to rule, not a stage's to assume.
- **PL-7 — whether the mailbox and the pool use the helper internally.** (RT-11)
- **PL-8 — the two standing port defects, `P3` and `P4`**, neither ruled.
  `matryoshka-tk`'s `design/secondary/lang/c3/3tk-deviations-001.md`.
- **PL-9 — the dropped Part 2.5/D7 coverage** (deadline anchored once, not
  restarted by a spurious wakeup), which 3TK-58 removed for having no black-box
  form. Owner's call whether it needs some other verification.
- **PL-10 — the doc-loop remainder.** The standing `DIFFERS` block is
  `managed.c3:5` — "Optional convenience API, not Matryoshka core." — absent
  from the reference's `mtk::managed` block, and the one missing sentence is the
  `inner.c3` struct-descriptor summary. **RT-2 and RT-5 move both files, so both
  gaps are closed by the stage that moves them**, not by a separate errand.

---

## 7. Reading ztk: intent versus workaround

**A rule for every stage that consults `matryoshka-tk/src/polynode.zig`.** Some
of ztk's shape exists only because Zig lacks something C3 has. **Those are not
requirements to port, and not gaps when C3 omits them.**

- **`PolyTag` / `TAG` / `isIt(tag)`** — Zig has no runtime type identity, so the
  owner built one by hand: a per-type static whose address is the id. C3 has
  `typeid`. 3tk having no `isIt`/`TAG` surface is **not** a gap. (RT-7)
- **Per-type instantiation** — `PolyHelper(T)` must be generated per type, which
  is why ztk's helper body is **written out twice** (`:115` and `:241`) to
  express one opt-out. C3 macros take `$Type` directly, and an uncalled macro
  generates nothing, so C3 needs neither the duplication nor
  `no_create_destroy`.
- **Genuine 3tk improvements, not to be "restored" to ztk's shape:** the exact
  `is_linked` (ztk documents its blind spot at `:79`); identity as `typeid`
  rather than a tag object; no alias, no instantiation, no registration for the
  macro layer.

**And the one place the port drifted from ztk's intent for no language reason:**
storing the allocator in the Outer. ztk never does. That is what RT-12 and
RT-13 undo.

---

## 8. How the building is ordered

**3TK-61 changes no `src/`.** The build stages, each verifiable on its own, in
this order — the reasoning is that a stage which cannot be proved to have moved
nothing should not run beside one that must:

1. **RT-4** — `stack.c3` private into `pool.c3`, `t_stack.c3` deleted.
   Self-contained. The test count drops, expected and explained. Carries with
   it: the reversal of 3TK-45 as a decisions entry; `stack.c3:11` and
   `mtk.c3:20`, which today promise direct caller use; `run-builds.sh:230`'s
   InnerQueue/InnerStack surface check; `project.json`; the doc-loop module list
   and the reference's `mtk::stack` block.
2. **RT-2** — the macros into `inner.c3`. Pure relocation, no semantics, so it
   must return **identical** build numbers — the proof-of-no-motion 3TK-60 used.
3. **RT-5, RT-12, RT-13, RT-14, RT-15** — `xtn`: `create`/`release` reshaped,
   allocator per call, optional field, the default-init contract and the
   pool-hook wording. Semantics change here, deliberately and alone.
4. **RT-6 … RT-11, HR-\*** — `OuterHelper` written, to the ruled shape.
5. **The books and the examples.** The bulk, last, as in 3TK-60.

---

## 9. When this document is spent

It goes to `design/backup/` with a plain `mv`, together with
[3tk-terms-001.md](3tk-terms-001.md), **once its content has dissolved into the
code and the permanent books** — not before. Its section 5 supersedes
`3tk-terms-001.md`'s section 5, which recorded the managed items as open;
RT-12 and RT-13 rule them.
