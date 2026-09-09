# 3tk — API verification table, 005

Every public declaration of the C3 port, with every assert and every contract
clause copied from the source and carrying its `file:line`.

**This is not the page to learn the toolkit from.**
[3tk-reference-009.md](3tk-reference-009.md) is that page, and it is the one a
caller reads. (Until this version the pointer here was `3tk-api-002.md`, which
3TK-60 moved to `matryoshka-tk`'s `backup/`.) Read this one to check that the
reference is telling the truth, or to find where in `3tk/src` a promise is
actually made.

**It was written as the reference and it is not one.** Reviewed by the owner
2026-08-25: three of its four bullets per entry were mandatory, so every entry
filled them whether or not it had anything to say — 87 `What` bullets that
restate the declaration's own name, 30 bullets whose whole content is `O(1)`,
and 94 citation bullets against 18 lines of example code in the entire port.
The citations are the part worth keeping, and that is what this file now is.

**It is alive.** It is revised whenever `3tk/src` changes, in the same stage
that changes it. A file that contradicts `3tk/src` is a defect of the stage
that changed the source.

**This version, and every later one, lives in `matryoshka-3tk/design/`, not in
`matryoshka-tk`'s `ref/`.** `003` is in `matryoshka-tk`'s
`design/secondary/lang/c3/backup/`. **`backup/` is transient — the owner empties
it — so no version there is ever cited as a source of truth.**

**It does not argue.** No ruling markers, no history, no alternatives that were
refused. Those live in [3tk-decisions-007.md](3tk-decisions-007.md).

**Every contract and every check below is copied from `3tk/src`**, with its
`file:line`. None is inferred from what a declaration ought to check.

**Re-anchored by 3TK-70, 2026-09-09.** The module split moved nearly every line
of four files, so all 90 citations were resolved again — each from the contract
or check clause the entry itself quotes, found in the current tree, and never
from the number it carried. The free crossings are `inner::internal::` now.

**005 replaces 004, written by 3TK-66 on 2026-09-08**, and it is the largest
change this table has taken since it stopped being a reference. `004` had fallen
four stages behind: 3TK-62 through 3TK-65 each changed `3tk/src` without
revising it, which is precisely what the *It is alive* rule above forbids.

**What changed.** **The helper is first**, ahead of `mtk` and `mtk::inner`,
because it is the surface and the rest is the layer beneath. `mtk::managed` and
`stack.c3` are gone as sections because they are gone as files, and `InnerStack`
is documented at the end of `mtk::pool`, where it is `@local`. `Mailbox` and
`Pool` are `typedef … = void` over `@private` `_Mbox` and `_Pool` — **so the
seven internal methods `003` listed as reachable-by-convention are unreachable by
construction**, and that entry documented a gap that no longer exists. `is_quiet`
on both, `InnerQueue.take`, `stamp`, `check_stamped` and the four helper
crossings are new entries. `VERSION` read `"0.2.0"` and reads `"0.0.1"`. **Every
`file:line` was recomputed from the built tree**, in the same pass that repaired
[3tk-decisions-007.md](3tk-decisions-007.md).

**`004` is not in `backup/`, and this is the one thing to know about the
version.** 3TK-66 revised it **in place** first, on the strength of the *It is
alive* rule, and the owner ruled afterwards that the change deserved a version.
By then the pre-3TK-66 text no longer existed on disk — git is not run in this
work — so what `backup/` could hold would be byte-identical to this file and
would misdescribe itself. **Nothing is lost:** `003` is in `matryoshka-tk`'s
`design/secondary/lang/c3/backup/`, and what `004` said that this file does not
is recorded in [3tk-log.md](../../matryoshka-tk/design/secondary/lang/c3/3tk-log.md)
under 3TK-66.

**004 replaced 003, revised by 3TK-60 on 2026-09-04**, which applied the
two-term ruling: 3tk has exactly two terms, `Inner` and `Outer`, and the words
*handle* and *item* are retired. `003` still documented `alias Handle =
Inner*`, a declaration 3TK-59 had already deleted; that entry is gone, the
signatures spell `Inner*`, and the crossings are `to_inner` / `from_inner` /
`must_from_inner`.

**003 replaced 001, revised by 3TK-32 on 2026-08-25.** 001 is in `backup/`.
3TK-32 rewrote the 21 string literals in `3tk/src` that cited a specification
Part, and the one that carried a ruling marker, so that what a user is shown is
the fact they can act on. Every one of those strings is quoted here, so every
quote was rewritten with it. The removed markers are on `// [3tk: ...]` marks in
the source, and adding those marks moved lines, so every `file:line` on this
page was recomputed. No declaration, signature or body changed.

## What was measured

Measured live on 2026-09-08, against `3tk/src`, by 3TK-66.

- **Six files, six modules**, one module per file: `mtk`, `mtk::inner`,
  `mtk::helper <Outer>`, `mtk::queue`, `mtk::mailbox`, `mtk::pool`. `managed.c3`
  and `stack.c3` are both gone as files; `InnerStack` is `@local` at the end of
  `pool.c3`.
- **Nine members on `OuterHelper`**, and they are the user surface for an outer.
- **58 contract clauses** in `<* *>` blocks — `@require`, `@param`, `@return?`.
  No `@ensure` anywhere.
- **33 runtime checks** — 31 `mtk::@check` and 2 `always_assert`.

**What is not documented here.** `mtk::inner` declares a second, `@private`
section holding `inner_offset`. `mailbox.c3` and `pool.c3` each declare a
`@private` implementation struct — `_Mbox` and `_Pool` — with the methods that
belong to it, and `pool.c3` declares `InnerStack` `@local`. Those are internal
by construction rather than by convention, which is the change since `003`: C3
0.8.3 ignored `@private` on a method, so the seven internal methods `003` listed
were reachable; they now sit on a private type, and the public `Mailbox` and
`Pool` are `typedef … = void`.

**Every declaration below an `For internal usage.` banner is internal too**, and
is documented here only where a caller can reach it. `run-builds.sh` checks that
banner in both directions.

## How to read an entry

**Signature** — copied from the source.

- **What** — one line.
- **Promises** — what a caller may rely on.
- **Costs** — the complexity, or the lock, or the allocation.
- **Contract** — the `<* *>` clauses, verbatim, with `file:line`.
- **Checks** — the runtime checks, verbatim, with `file:line`.

**Two check tiers appear below.**

- `mtk::@check` — live in a safe build, gone entirely under `--safe=no`.
- `always_assert` — live in every build mode, including `--safe=no -O3`.

## The modules

| module | file | what is in it |
|---|---|---|
| `mtk` | `mtk.c3` | `VERSION`, the faults, `@check`, `CHECKED` |
| `mtk::helper <Outer>` | `helper.c3` | `OuterHelper` — the nine members a user calls |
| `mtk::inner` | `inner.c3` | `Inner`, `Slot`, the identity, the crossings, the link |
| `mtk::queue` | `queue.c3` | `InnerQueue` and its walker |
| `mtk::mailbox` | `mailbox.c3` | `Mailbox` |
| `mtk::pool` | `pool.c3` | `Pool`, `PoolHooks`, and `InnerStack` `@local` |

**One import gives all six.** `import mtk;` gives this module and every
submodule of it, so every name below is written unqualified at a call site.

**`mtk::helper` is first, and that is deliberate.** It is the surface; `mtk::inner` is the
layer it forwards to. A reader checking whether the reference tells the truth
starts at the helper and follows the forwarding down.

---

# `mtk::helper <Outer>` — helper.c3

**The one thing a user binds, one line per outer type.**

    alias MSG = helper::OF{Msg};

**Nine members: four crossings, `inner`, `stamp`, `linked`, `create` and
`release`.** Every one forwards to a macro in `inner.c3` and has no logic of its
own — which is exactly why this page and the next must agree.

**Every member takes `self` and no member reads it.** `Outer` arrives from the
module instantiation, and every member compares against `Outer::typeid`, the
compile-time constant that instantiation supplies.

**Nine is a ceiling, not a target.**

## The carrier

### `typedef OuterHelper = uptr`

- **What** — the receiver that gives C3's method syntax something to bind to.
- **Promises** — it holds nothing, and the value is never read, as a number or
  as anything else.
- **Costs** — none. It is a `typedef` over `uptr` because c3c refuses a struct
  with no members, and because the standard library spells its own zero-state
  carriers that way.

### `const OuterHelper OF = {}`

- **What** — the helper for `Outer`, ready to alias.
- **Promises** — uppercase, because it is a `const`, and C3 enforces the pairing
  in both directions. An uppercase alias must alias a constant, so
  `alias MSG = helper::OF{Msg};` is the only spelling.
- **Costs** — a compile-time constant.

## The four crossings

**Two independent axes, so the names are derivable rather than memorised.**
`must_` aborts on a mismatch and plain returns null; `take` empties the Slot on
success and `look` leaves it alone.

| member | on mismatch | the Slot after | accepts |
|---|---|---|---|
| `look` | null | unchanged | `Slot*` **or** `Inner*` |
| `must_look` | **aborts** | unchanged | `Slot*` **or** `Inner*` |
| `take` | null | **emptied** | `Slot*` only |
| `must_take` | **aborts** | **emptied** | `Slot*` only |

**All four check the stamp first**, on all six arms, and `run-builds.sh` asserts
that count.

### `macro Outer* OuterHelper.look(self, from)`

- **What** — from a Slot or an inner back to `Outer*`, without disturbing the
  Slot.
- **Promises** — null on an identity mismatch. A mismatch is an answer, not a
  failure. One name serves both argument types, dispatched at compile time on
  `$Typeof`; anything else is a `$error` naming the mistake.
- **Costs** — O(1), one typeid comparison and one pointer subtraction.
- **Contract** — `@param from : "a `Slot*` or an `Inner*`"` — `helper.c3:74`.
- **Checks** — `inner::internal::check_stamped(…, "the outer was never stamped: make it
with `create`, or call `stamp` once")` — `helper.c3:80` and `helper.c3:80`.

### `macro Outer* OuterHelper.must_look(self, from)`

- **What** — the same, and it aborts on a mismatch.
- **Promises** — use it where a mismatch would be your own defect; the abort
  names your line. Under `--safe=no` the check is gone.
- **Costs** — O(1), and nothing at all in a fast build.
- **Contract** — `@param from : "a `Slot*` or an `Inner*`"` — `helper.c3:97`.
- **Checks** — `inner::internal::check_stamped(…)` — `helper.c3:103` and `helper.c3:106`.

### `macro Outer* OuterHelper.take(self, Slot* slot)`

- **What** — from a Slot back to `Outer*`, emptying the Slot on success.
- **Promises** — null on an identity mismatch, and then the Slot is unchanged.
  There is no `Inner*` form: an inner has no Slot to empty.
- **Costs** — O(1).
- **Contract** — `@param slot : "the Slot holding the outer; empty afterwards on
success"` — `helper.c3:119`.
- **Checks** — `inner::internal::check_stamped(…)` — `helper.c3:123`.

### `macro Outer* OuterHelper.must_take(self, Slot* slot)`

- **What** — the same, and it aborts on a mismatch.
- **Promises** — the Slot is empty afterwards. **This form did not exist before
  3TK-64:** the old `move_from_slot` had no abort form, and that gap is what the
  two-axis naming exposed.
- **Costs** — O(1).
- **Contract** — `@param slot : "the Slot holding the outer; empty afterwards"` —
`helper.c3:133`.
- **Checks** — `inner::internal::check_stamped(…)` — `helper.c3:137`.

## The other three

### `macro Inner* OuterHelper.inner(self, Outer* outer)`

- **What** — from your pointer to the `Inner*`, stamping the identity on the way.
- **Promises** — the stamp may be written any number of times and is safe on a
  linked outer, so this costs nothing to call twice. **It is what makes the
  identity impossible to forget.**
- **Costs** — O(1), one `any_make` and one pointer addition.
- **Contract** — `@param outer : "a pointer to the outer"` — `helper.c3:150`.

### `macro void OuterHelper.stamp(self, Outer* outer)`

- **What** — writes the identity into the embedded `Inner`, and nothing else.
- **Promises** — for an outer you allocated by hand; an outer made by `create`
  is stamped already. Forgetting it is caught in a safe build, at the next
  crossing or at the next insertion, whichever comes first.
- **Costs** — O(1). It is called `stamp` and not `init` because `init` is the
  name of your own hook.
- **Contract** — `@param outer : "a pointer to the outer"` — `helper.c3:165`.

### `macro bool OuterHelper.linked(self, Outer* outer)`

- **What** — true when the outer is on some chain.
- **Promises** — **exact**, not a heuristic.
- **Costs** — O(1).
- **Contract** — `@param outer : "a pointer to the outer"` — `helper.c3:174`.

## Allocating and freeing

### `macro void? OuterHelper.create(self, Allocator a, Slot* slot)`

- **What** — allocates the outer, initializes it, stamps it, and fills the Slot.
- **Promises** — four steps in this order: allocate zeroed, call your `init(a)`
  hook if you declared one, stamp the inner, fill the Slot. **Stamping after the
  hook is deliberate:** if `init` fails the outer was never stamped, so a pointer
  that escaped a failed creation can never be mistaken for a live outer. On a
  hook failure the allocation is freed and the fault is propagated unchanged; on
  an allocation failure the Slot is untouched and the fault is returned. **The
  toolkit reads and writes no field of your outer except the `Inner`** — an outer
  that wants to keep its allocator stores this argument in its own field, under
  any name, in its own `init`.
- **Costs** — one allocation, plus whatever your hook does. It returns `void?`
  because its caller has a real decision to make.
- **Contract** — `@param a : "the allocator; it is passed to your `init` hook and
it is not stored"` — `helper.c3:191`.
- **Contract** — `@param slot : "an empty Slot, filled on success"` —
`helper.c3:192`.
- **Checks** — `mtk::@check(slot.is_empty(), "an acquisition asserts the Slot is
empty on entry")` — `helper.c3:197`.

### `macro void OuterHelper.release(self, Allocator a, Slot* slot)`

- **What** — calls your `destroy(a)` hook if you declared one, empties the Slot,
  and frees the outer.
- **Promises** — **a no-op on an empty Slot**, so a `defer` registered before the
  acquisition is safe. It returns `void`, so it needs no `!`, no `!!` and no
  `(void)` cast in a `defer`, which is why the signature is shaped this way. The
  narrower reason is that a teardown fault has no recipient: `release` runs on a
  path that is usually already unwinding.
- **Costs** — one free, plus whatever your hook does.
- **Contract** — `@param a : "the allocator the outer was created with"` —
`helper.c3:217`.
- **Contract** — `@param slot : "the Slot holding the outer; empty afterwards"` —
`helper.c3:218`.
- **Checks** — `mtk::@check(!f, "destroy failed during release")` —
`helper.c3:226`. **A failing destructor is a defect, not an outcome:** the fault
aborts in a safe build and is dropped in a fast one.

---

# `mtk` — mtk.c3

**The vocabulary every submodule and every user shares.** Four declarations, and
that is the whole of the landing page.

### `const String VERSION = "0.0.1"`

- **What** — the toolkit's version string.
- **Costs** — a compile-time constant.

### `faultdef CLOSED, TIMEOUT, NOT_AVAILABLE, NOT_CREATED, EMPTY, WOKEN, UNKNOWN_IDENTITY`

- **What** — the outcomes a correct program reaches.
- **Promises** — a 3tk call that can fail returns `void?`. A defect is not a
  fault, and a defect aborts. The first six are runtime conditions, never
  defects; a correct program reaches every one, and they are reported in every
  build mode.
- **Costs** — `UNKNOWN_IDENTITY` is the exception: it reports a defect of the
  caller. It comes from `Pool.get` and `Pool.get_wait` and from nothing else.

### `macro @check(#cond, $msg)`

- **What** — aborts in a safe build and names the message.
- **Promises** — under `--safe=no` it expands to nothing, and the condition is
  not evaluated.
- **Costs** — nothing in a fast build.
- **Contract** — `@param #cond : "the condition that must hold"` — `mtk.c3:63`.
- **Contract** — `@param $msg : "a compile-time message, named at the call
site"` — `mtk.c3:64`.

### `const bool CHECKED = env::COMPILER_SAFE_MODE`

- **What** — true where those checks are live.
- **Promises** — a `$if mtk::CHECKED:` block compiles to nothing in a fast
  build. Its one reader in `src/` is the duplicate-identity scan in
  `Pool.create`.
- **Costs** — a compile-time constant. Guard an expensive check with it.

---

# `mtk::inner` — inner.c3

**The layer beneath the helper**, and the file that decides what a user may
touch directly.

**The file is in two parts, and the banner between them is checked.** Above the
banner is the part a user calls: `Inner`, `Slot`, the Slot's five operations,
`Inner.outer_tid`, and the five crossings written as methods. Below it is
everything the helper does for you, each declaration opening its doc block with
the exact line `For internal usage.`

**The test for which part a declaration belongs to is whether the helper can do
it for you.** It cannot embed the field, it cannot read the Slot, and it cannot
read an identity before the type is known — so those stay above. **The dispatch
switch is why `outer_tid` is above:** it reads the identity before it knows the
type.

## Types

### `struct Inner { any link; }`

- **What** — the structure an application embeds in its own struct. One field.
- **Promises** — `link.ptr` is the chain link. `link.type` is the type identity,
  written once by `stamp`.
- **Costs** — 16 bytes. Every outer in the program pays it.

### `typedef Slot = Inner*`

- **What** — a container of one inner, or of nothing.
- **Promises** — emptiness is the transfer signal. Empty means the outer is
  elsewhere. Full means the outer is here.
- **Costs** — distinct, so an `Inner*` does not implicitly become a `Slot`. A
  zero-initialized Slot is empty; there is no initializer to forget.

## The identity, read

### `fn typeid Inner.outer_tid(&self) @inline`

- **What** — the identity of the outer this inner is embedded in.
- **Promises** — null for an inner that was never stamped. **It exists so that
  no user ever writes `inner.link.type`**, and it is part of the user surface: a
  dispatch switch reads it.
- **Costs** — O(1), one field read.

## The Slot

### `fn bool Slot.is_empty(&self) @inline`

- **What** — is the outer elsewhere.
- **Costs** — O(1).

### `fn bool Slot.is_full(&self) @inline`

- **What** — is the outer here.
- **Costs** — O(1).

### `fn Inner* Slot.peek(&self) @inline`

- **What** — look without taking.
- **Promises** — the Slot is unchanged. Null when it is empty.
- **Costs** — O(1).

### `fn Inner* Slot.take(&self) @inline`

- **What** — take, leaving the Slot empty.
- **Promises** — null when it was already empty, and then nothing changed.
- **Costs** — O(1).

### `fn void Slot.fill(&self, Inner* inner) @inline`

- **What** — place an inner into an empty Slot.
- **Promises** — **a full Slot is never overwritten.** That is the rule the
  whole transfer discipline rests on.
- **Costs** — O(1).
- **Contract** — `@param inner : "the inner to place; must not be null"` —
`inner.c3:149`.
- **Checks** — `mtk::@check(inner != null, "Slot.fill with a null inner")` —
`inner.c3:153`.
- **Checks** — `mtk::@check(self.is_empty(), "never overwrite a full Slot")` —
`inner.c3:155`.

## The five crossings, as methods

**These are the layer the helper's four crossings forward to**, and they are
public because a dispatch loop holding an `Inner*` with no helper bound for the
type it is testing has nowhere else to go. **Reach for the helper member first.**

### `macro Inner.to(&self, $Type)`

- **What** — from an `Inner*` back to `$Type*`. `MSG.look(inner)` is the
  spelling to prefer.
- **Promises** — null on an identity mismatch.
- **Costs** — O(1).
- **Contract** — `@param $Type : "the outer type expected"` — `inner.c3:167`.

### `macro Inner.as(&self, $Type)`

- **What** — the same, and it aborts on a mismatch. `MSG.must_look(inner)` is
  the spelling to prefer.
- **Costs** — O(1), and nothing in a fast build.
- **Contract** — `@param $Type : "the outer type asserted"` — `inner.c3:177`.
- **Contract** — `@require is_mine((Inner*)self, $Type) : "the inner is not of
this type"` — `inner.c3:178`.

### `macro Slot.to(&self, $Type)`

- **What** — from the Slot back to `$Type*`. It looks, and the Slot is
  unchanged. `MSG.look(&s)` is the spelling to prefer.
- **Costs** — O(1).
- **Contract** — `@param $Type : "the outer type expected"` — `inner.c3:167`.

### `macro Slot.must(&self, $Type)`

- **What** — the same, and it aborts on a mismatch. The Slot is unchanged.
  `MSG.must_look(&s)` is the spelling to prefer.
- **Costs** — O(1).
- **Contract** — `@param $Type : "the outer type asserted"` — `inner.c3:198`.

### `macro Slot.move(&self, $Type)`

- **What** — from the Slot back to `$Type*`, and it takes. `MSG.take(&s)` is the
  spelling to prefer.
- **Promises** — on success the Slot is left empty; on failure it is unchanged.
- **Costs** — O(1).
- **Contract** — `@param $Type : "the outer type expected"` — `inner.c3:208`.

## Internal — what the helper does for you

**Everything below the internal banner in `inner.c3`.** It is listed so that the
forwarding above can be checked, not so that it can be called.

### `macro bool is_mine(Inner* inner, $Type)`

- **What** — does this identity name my type.
- **Promises** — a null inner is not mine, and an outer that was never stamped
  carries a zeroed typeid, which matches no type. It is refused here rather than
  mis-claimed.
- **Costs** — O(1), one typeid comparison.

### `macro void stamp(outer)`

- **What** — writes the identity into the embedded inner. Reached through
  `MSG.stamp` and `MSG.inner`.
- **Promises** — call it any number of times; a second call writes what the
  first one wrote, and it is safe on a linked outer as well as an unlinked one.
  **It preserves `link.ptr`, and that is what makes it safe on a linked inner.**
  The natural maintenance edit is `any_make(null, …)`, which silently unlinks a
  linked outer, so the correct line differs from the destructive one by a single
  sub-expression.
- **Costs** — O(1), one `any_make`.
- **Contract** — `@require $defined($Typeof(*outer)::members) : "not a struct
that embeds an Inner"` — `inner.c3:252`.

### `macro check_stamped(Inner* inner, $msg)`

- **What** — the safe-build assertion that an inner carries an identity.
- **Promises** — **null is not the violation.** An empty Slot and a null
  `Inner*` are answers a checking crossing is allowed to give. Only an inner
  that exists and carries no identity is a defect.
- **Costs** — nothing in a fast build: the condition is not evaluated and the
  identity is never read.
- **Checks** — `mtk::@check(inner == null || (void*)inner.outer_tid() != null,
$msg)` — `inner.c3:284`.

### `macro Inner* to_inner(outer)`

- **What** — from your pointer to the inner. Null in, null out.
- **Costs** — O(1).
- **Contract** — `@require $defined($Typeof(*outer)::members) : "not a struct
that embeds an Inner"` — `inner.c3:290`.

### `macro from_inner(Inner* inner, $Type)` · `macro must_from_inner(Inner* inner, $Type)`

- **What** — the checking and the asserting crossing from an inner.
- **Contract** — `@require is_mine(inner, $Type) : "the inner is not of this
type"` — `inner.c3:178`.

### `macro from_slot(Slot* s, $Type)` · `macro must_from_slot(Slot* s, $Type)` · `macro move_from_slot(Slot* s, $Type)`

- **What** — the same three, taking the outer from a Slot. `move_from_slot`
  empties the Slot on success and leaves it alone on failure.
- **Promises** — **the free Slot forms were dead in user code** — one call site
  across 52 example files — which is why none of them is on the helper.

### The chain — `Inner.repoint_to`, `Inner.points_to`, `is_linked`, `reset`

- **What** — the four chain primitives.
- **Promises** — `is_linked` is **exact**, and `MSG.linked` is the member that
  reaches it. The other three are nobody's but the queue's and the stack's.
- **Costs** — O(1) each.
- **Promises** — they cannot be hidden: `InnerStack` in `mtk::pool` calls them,
  and `@private` in C3 reaches the module and nothing else.

### `macro usz inner_offset($Type)` — second, `@private` section

- **What** — finds the embedded `Inner` at compile time.
- **Promises** — a type with no `Inner` field does not compile, and a type with
  two does not either. The message names your type. **This is the whole of the
  "registration" a new outer type needs**, and it happens at compile time.
- **Costs** — nothing at runtime.

**There is no second discovery.** `required_alloc_offset` found an `Allocator`
field the same way, for the `mtk::managed` 3TK-64 deleted. Both are gone.

---
# `mtk::queue` — queue.c3

**First-in first-out. Seven operations. Nothing here allocates, the outer is the
inner, and every operation is O(1) in every build mode.**

**Nothing in this file can fail.** A take from an empty queue returns null.
That is an answer, not a fault.

## Types

### `struct InnerQueue { Inner* head; Inner* tail; usz count; }`

- **What** — the queue header.
- **Promises** — the count is kept, so `len` is O(1).
- **Costs** — three words per queue.

### `struct InnerQueueIterator { Inner* cur; }`

- **What** — a walker, taken from the queue.
- **Promises** — yields inners one at a time, exhausted when it returns null.
- **Costs** — one word. **Removing the current outer during a walk is not
  supported.**

## The guard

### `macro InnerQueue.@guard_insert(&self, Inner* inner)`

- **What** — the insert guard, run by both inserts.
- **Costs** — tier 2, and O(1). Gone in a fast build.
- **Checks** — `@check(h != null, "insert of a null inner")` — `queue.c3:209`.
- **Checks** — `@check(!is_linked(h), "the outer is already on a chain")` —
`queue.c3:211`.

## Questions

### `fn bool InnerQueue.is_empty(&self) @inline`

- **What** — is it empty.
- **Costs** — O(1).

### `fn usz InnerQueue.len(&self) @inline`

- **What** — how many.
- **Costs** — O(1), from the kept count.

### `fn InnerQueueIterator InnerQueue.iter(&self) @inline`

- **What** — a walker over the queue, from the head.
- **Costs** — O(1).

### `fn Inner* InnerQueueIterator.next(&self)`

- **What** — the next inner, or null when the walk is exhausted.
- **Promises** — the end test is `n.points_to() == n`, and a walker written
  without it does not terminate.
- **Costs** — O(1) per outer.

## Adding

### `fn void InnerQueue.push_back(&self, Inner* inner)`

- **What** — add at the back.
- **Promises** — the new outer is the tail and is self-linked. The old tail
  points at it.
- **Costs** — O(1), plus the guard above.

### `fn void InnerQueue.push_back_slot(&self, Slot* s)`

- **What** — add at the back, from a Slot.
- **Promises** — the transfer clears the Slot.
- **Costs** — O(1). **An empty Slot is a defect, not a no-op.** The check is
  tier 2 and the early return is ordinary code, so a fast build does nothing
  rather than dereference a null.
- **Checks** — `@check(s.is_full(), "push_back_slot from an empty Slot")` —
`queue.c3:102`.

## Removing

### `fn InnerQueue InnerQueue.take(&self) @inline`

- **What** — takes the whole queue by value, leaving this one empty.
- **Promises** — O(1) and atomic against nothing: it is three field writes, and
  it is what a caller under a lock uses to move a batch out and drop the lock
  before walking it.
- **Costs** — O(1).

### `fn Inner* InnerQueue.pop_front(&self)`

- **What** — take from the front.
- **Promises** — null on an empty queue. The returned outer's link is cleared.
- **Costs** — O(1).

## Moving

### `fn void InnerQueue.append_queue(&self, InnerQueue* other)`

- **What** — move every outer of another queue onto this one.
- **Promises** — `other` is empty afterwards. No repair is needed at the join.
- **Costs** — O(1), a splice. The self-move check is tier 2 and the early
  return is ordinary code; without both, the naive move rings the outers into a
  cycle and loses every one.
- **Contract** — `@param other : "the queue to empty onto this one; empty
afterwards"` — `queue.c3:155`.
- **Checks** — `@check(other != null, "append_queue with a null queue")` —
`queue.c3:159`.
- **Checks** — `@check(other != self, "a queue cannot be moved onto itself")`
— `queue.c3:161`.

---

# `mtk::mailbox` — mailbox.c3

**A queue of outers, with waiting. Many producers, many consumers, on one
object.**

**A mailbox is itself an outer.** It embeds an inner, it has a type identity,
and it can travel through another mailbox or sit on a list.

**Two queues, not one.** Out-of-band outers live in their own queue and every
take tries it first, so absolute priority with first-in first-out inside each
class falls out of the structure.

**The fields are reachable and are named with a leading underscore.** C3 0.8.3
hides neither a field nor a method. Reading them is a documentation problem
rather than a broken invariant.

**Usual flow.** `create`, then any number of `send` / `receive` calls from any
number of threads, then `close` with a queue to receive the remainder, then
`release`.

## Types and identity

### `typedef Mailbox = void`

- **What** — the mailbox, as a caller sees it: an opaque pointer.
- **Promises** — **the implementation struct is `_Mbox`, and it is `@private`.**
  Its members are the inner, a mutex, a condition variable, an allocator, the
  closed flag and its atomic twin, the active count, the two queues, and the
  wake generation. A caller can neither read nor name them. This is what
  replaced the reachable-fields note in `003`: the fields are no longer
  reachable, so the documentation problem is gone rather than managed.
- **Promises** — `_Mbox` repeats these members rather than embedding a shared
  base struct, because a shared base would put a second inner in the outer.

### `const typeid TYPE = _Mbox::typeid`

- **What** — the mailbox's type identity, under the name its callers use.
- **Promises** — it names the private implementation type, which is what the
  identity in a travelling mailbox's inner actually holds. A dispatch switch
  writes `mailbox::TYPE`, never a `::typeid` of its own.
- **Costs** — a compile-time constant.

### `macro Inner* to_inner(Mailbox* p)`

- **What** — from a mailbox to an inner. Forwards to `inner::internal::to_inner`.
- **Promises** — cannot fail.
- **Costs** — O(1).

### `macro Mailbox* of(Inner* inner)`

- **What** — the checking crossing back.
- **Promises** — null when the inner names another type.
- **Costs** — O(1).

## Lifetime

### `fn Mailbox*? create(Allocator a)`

- **What** — create a mailbox on the heap.
- **Promises** — **creation is a transaction.** Each failure undoes exactly
  what succeeded before it, through `defer catch`. Nothing partially
  constructed is ever returned or observable. The allocator is kept for life.
- **Costs** — one allocation, a mutex init and a condition-variable init.
- **Contract** — `@param a : "the allocator the mailbox keeps for life"` —
`mailbox.c3:72`.

### `fn void Mailbox.release(&mbox)`

- **What** — destroy the mutex and the condition variable, and free the
  mailbox.
- **Promises** — **the mailbox must be closed *and quiet* first, and this is the
  one precondition the toolkit refuses to soften.** It is `always_assert`: it
  aborts in every build mode, including `--safe=no -O3`. The predicate is read
  under the mutex, and `release` is never counted itself. **This is a check and
  not a wait** — a release that waited would block on application code the port
  does not control. No allocator parameter.
- **Costs** — one free.
- **Checks** — `always_assert(self._closed && self._active == 0, "releasing a
mailbox that is not quiet")` — `mailbox.c3:116`.

## Sending

### `fn void? Mailbox.send(&mbox, Slot* slot)`

- **What** — put an outer on the ordinary queue.
- **Promises** — the Slot is the answer. On success it is cleared; on a closed
  mailbox it is untouched and the sender still has the outer.
- **Costs** — O(1) under the mutex, plus one signal. An empty Slot is a defect
  checked at tier 2, with an early return behind it.
- **Contract** — `@param slot : "a full Slot; cleared on success, untouched on
CLOSED"` — `mailbox.c3:137`.
- **Contract** — `@return? mtk::CLOSED` — `mailbox.c3:138`.
- **Checks** — `mtk::@check(slot.is_full(), "Mailbox.send from an empty
Slot")` — `mailbox.c3:155`.

### `fn void? Mailbox.send_oob(&mbox, Slot* slot)`

- **What** — send ahead of every ordinary outer.
- **Promises** — first-in first-out among out-of-band outers themselves.
  **One priority level.** This is not a priority queue.
- **Costs** — as `send`. Both share `send_at`, and both share its check.
- **Contract** — `@param slot : "a full Slot; cleared on success, untouched on
CLOSED"` — `mailbox.c3:148`.
- **Contract** — `@return? mtk::CLOSED` — `mailbox.c3:149`.

## Receiving

### `fn void? Mailbox.poll(&mbox, Slot* slot)`

- **What** — take an outer if one is queued. **Never waits.**
- **Promises** — three outcomes: an outer, `EMPTY`, or `CLOSED`. A receive with
  a zero timeout has the same reach; the two differ in how the empty case is
  reported, and a caller reading outcomes is entitled to the difference.
- **Costs** — O(1) under the mutex.
- **Contract** — `@param slot : "an empty Slot; filled on success"` —
`mailbox.c3:178`.
- **Contract** — `@return? mtk::CLOSED, mtk::EMPTY` — `mailbox.c3:179`.
- **Checks** — `mtk::@check(slot.is_empty(), "an acquisition asserts the Slot
is empty on entry")` — `mailbox.c3:186`.

### `fn void? Mailbox.receive(&mbox, Slot* slot, Duration timeout)`

- **What** — take an outer, waiting up to a timeout.
- **Promises** — four outcomes: an outer, `CLOSED`, `TIMEOUT`, or `WOKEN`. The
  deadline is anchored once, before the loop. A wakeup carries no meaning and
  the state is re-evaluated from scratch every turn. A waiter leaving on a
  timeout takes one last look, and signals if anything is still queued.
- **Costs** — blocks on the condition variable. There is no interruption: C3
  has no interruptible condition wait.
- **Contract** — `@param slot : "an empty Slot; filled on success"` —
`mailbox.c3:210`.
- **Contract** — `@param timeout : "how long to wait"` — `mailbox.c3:211`.
- **Contract** — `@return? mtk::CLOSED, mtk::TIMEOUT, mtk::WOKEN` —
`mailbox.c3:212`.
- **Checks** — `mtk::@check(slot.is_empty(), "an acquisition asserts the Slot
is empty on entry")` — `mailbox.c3:219`.

### `fn void? Mailbox.receive_all(&mbox, InnerQueue* out)`

- **What** — take the whole batch at once.
- **Promises** — every queued outer is moved onto `out`, in the order `receive`
  would have taken them: out-of-band first, then ordinary, first-in first-out
  within each. Releasing the outers is the caller's work — what they are is
  knowledge the mailbox never had.
- **Costs** — two O(1) splices under the mutex.
- **Contract** — `@param out : "an empty queue; every queued outer is moved
onto it, in receive order"` — `mailbox.c3:269`.
- **Contract** — `@return? mtk::CLOSED` — `mailbox.c3:270`.

## Waking, closing, questions

### `fn void? Mailbox.wake_all(&mbox)`

- **What** — release every current waiter.
- **Promises** — each released waiter reports `WOKEN`. **The mailbox stays
  open.** The effect does not persist: a thread that starts waiting afterwards
  captures the new generation and is unaffected.
- **Costs** — one broadcast under the mutex.
- **Contract** — `@return? mtk::CLOSED` — `mailbox.c3:299`.

### `fn void Mailbox.close(&mbox, InnerQueue* out)`

- **What** — close the mailbox and give back what was left.
- **Promises** — **cannot fail.** Callable more than once; the second call
  takes nothing. Every remaining outer is moved onto `out`, in receive order.
  Every waiter is released.
- **Costs** — two O(1) splices and one broadcast, under the mutex.
- **The named mistake** — discarding the queue this returns loses the outers,
  and those outers keep their links, so a later send refuses them. The refusal
  is exact, so the mistake surfaces at the first reuse.
- **Contract** — `@param out : "an empty queue; the remainder is moved onto
it, in receive order"` — `mailbox.c3:327`.

### `fn bool Mailbox.is_closed(&mbox)`

- **What** — is it closed.
- **Promises** — a hint outside the lock, and honest under it.
- **Costs** — one atomic load, no mutex.

### `fn bool Mailbox.is_quiet(&mbox)`

- **What** — true when it is closed and no call on it is still running.
- **Promises** — the same predicate `release()` asserts, read under the mutex.
  The usual way to reach this state is to join the threads that touch the
  mailbox.
- **Costs** — one mutex.

### `fn usz Mailbox.len(&mbox)`

- **What** — how many are queued, across both queues.
- **Promises** — **a hint, and stale by the time the caller reads it.**
- **Costs** — O(1) under the mutex.

---

# `mtk::pool` — pool.c3

**A keeper of reusable outers, grouped by type identity.**

**Policy is not in the pool. Policy is in the hooks.**

**The pool's close gives nothing back to the caller.** Everything the pool
still held goes to the close hook. That is the mirror image of the mailbox's
close and the sharpest asymmetry in the toolkit.

**The identity set is fixed at creation and is not empty.** An identity outside
it is a defect of the caller: a checking build aborts, and a fast build reports
`UNKNOWN_IDENTITY`.

**There is no `put_all`.** A caller giving a batch back writes the loop itself:

    while (Inner* inner = batch.pop_front())
    {
        Slot s;
        s.fill(h);
        p.put(&s);
        if (s.is_full()) { batch.push_back(h); break; }   // refused
    }

**Usual flow.** `create` with the identity set and the hooks, then any number of
`get` / `put` calls from any number of threads, then `close`, then `release`.

## The hooks

### `interface PoolHooks`

- **What** — the three hooks, as a C3 interface. The implementing object is the
  context; there is no separate `ctx` parameter.
- **Promises** — **hooks run outside the pool's mutex, several at once on
  different threads.** This is a contract, not a warning.
- **Costs** — a hook that touches shared state protects it itself. **A hook does
  not call back into the pool, and does not block or wait.**

### `fn void PoolHooks.on_get(typeid want, usz in_pool, Slot* slot)`

- **What** — an outer of a named identity was asked for and none was available.
- **Promises** — the Slot is empty on entry. Create one, or leave it empty to
  report failure; an empty Slot afterwards becomes `NOT_CREATED`. Returning an
  outer of a different identity is a defect of the application, and the pool
  checks for it at tier 2.
- **Costs** — called with no lock held.
- **Contract** — `@param want : "the identity asked for"` — `pool.c3:41`.
- **Contract** — `@param in_pool : "how many of this identity remain, AFTER
the removal. A hint, and stale"` — `pool.c3:42`.
- **Contract** — `@param slot : "empty on entry; fill it or leave it"` —
`pool.c3:43`.

### `fn void PoolHooks.on_put(usz in_pool, Slot* slot, InnerQueue* extra)`

- **What** — an outer is being given back.
- **Promises** — four outcomes and none mandated. Released with nothing kept:
  empty the Slot. Kept as it is, or kept after a reset: leave it full. Released
  with a different outer put back: replace the contents. **A full Slot on return
  means one thing — an outer is kept, original or replacement.**
- **Costs** — called with no lock held. Outers added to `extra` are taken the
  same way, with the same checks: that is how a composite outer gives its parts
  back.
- **Contract** — `@param in_pool : "how many of this identity are held, BEFORE
the addition. A hint"` — `pool.c3:57`.
- **Contract** — `@param slot : "full on entry"` — `pool.c3:58`.
- **Contract** — `@param extra : "an empty queue; outers added here are taken
the same way, with the same checks"` — `pool.c3:59`.

### `fn void PoolHooks.on_close(InnerQueue* remaining)`

- **What** — the pool is going down.
- **Promises** — called with everything that remained, as one flat queue, and
  **the hook is responsible for processing or releasing every outer in it.**
  Called outside the mutex, after the closed flag is already set.
- **Costs** — **called once by `close`, and possibly once more with
  stragglers** from a `put` whose hook was still running when the close fired.
  A hook writes the same loop either way, and **must not free its own context
  on the first call.**
- **Contract** — `@param remaining : "everything the pool still held,
flattened across every identity. No order is promised"` — `pool.c3:75`.

## Types and identity

### `enum GetMode { AVAILABLE_OR_NEW, NEW_ONLY, AVAILABLE_ONLY }`

- **What** — the three modes of a plain get.
- **Promises** — `AVAILABLE_ONLY` is the only mode that can report
  `NOT_AVAILABLE`. `NEW_ONLY` never takes a stored outer.

### `struct PoolBucket { typeid tag; InnerStack free; }` — `@private`

- **What** — one free stack per identity.
- **Promises** — a stack, and the reason is defect surfacing: the outer just
  given back is on top, so the next `get` passes it straight to a new user and
  a stale writer collides with that user immediately instead of much later.
- **Costs** — no count field beside it. `InnerStack.len` is O(1), and the hint
  given to a hook is read from it under the lock.

### `typedef Pool = void`

- **What** — the pool, as a caller sees it: an opaque pointer.
- **Promises** — **the implementation struct is `_Pool`, and it is `@private`.**
  Its members are the inner, a mutex, a condition variable, an allocator, the
  closed flag and its atomic twin, the active count, the bucket slice, and the
  hooks. A caller can neither read nor name them.
- **Costs** — the buckets are a flat slice allocated once and scanned linearly.
  The set is small, fixed, and never grows, so a hash map would buy nothing.

### `const typeid TYPE = _Pool::typeid`

- **What** — the pool's type identity, under the name its callers use.
- **Promises** — it names the private implementation type, which is what the
  identity in a travelling pool's inner actually holds.

### `macro Inner* to_inner(Pool* p)`

- **What** — from a pool to an inner.
- **Promises** — cannot fail.
- **Costs** — O(1).

### `macro Pool* of(Inner* inner)`

- **What** — the checking crossing back.
- **Promises** — null when the inner names another type.
- **Costs** — O(1).

## Lifetime

### `fn Pool*? create(Allocator a, typeid[] tags, PoolHooks hooks)`

- **What** — create a pool on the heap.
- **Promises** — **the hooks are a parameter of creation and not a later
  step**: a pool cannot exist without them. The identity set is fixed here.
  **Creation is a transaction**: each failure undoes exactly what succeeded
  before it. Nothing partially constructed is ever returned or observable.
- **Costs** — two allocations — the pool and the bucket slice — plus a mutex
  init and a condition-variable init. **The duplicate scan is O(n²) and is
  compiled only where the tiers are live.** It runs before anything is
  allocated, so it needs no cleanup.
- **Contract** — `@param a : "the allocator the pool keeps for life"` —
`pool.c3:181`.
- **Contract** — `@param tags : "the identities this pool holds. Not empty,
and no duplicates — both checked"` — `pool.c3:182`.
- **Contract** — `@param hooks : "the policy"` — `pool.c3:183`.
- **Checks** — `mtk::@check(tags.len > 0, "the set of identities is not
empty")` — `pool.c3:188`.
- **Checks** — `mtk::@check(hooks != null, "a pool cannot exist without
hooks")` — `pool.c3:190`.
- **Checks** — `mtk::@check(t != u, "the pool's set of identities has a
duplicate")` — `pool.c3:199`.

### `fn void Pool.release(&pool)`

- **What** — destroy the mutex and the condition variable, and free the buckets
  and the pool.
- **Promises** — **the pool must be closed *and quiet* first.**
  `always_assert`, aborting in every build mode: releasing an open pool means
  the outers it still held never reached the close hook. The predicate is read
  under the mutex, and `release` is never counted itself.
- **Costs** — two frees.
- **Checks** — `always_assert(self._closed && self._active == 0, "releasing a pool that is not quiet")` —
`pool.c3:256`.

### `fn bool Pool.is_quiet(&pool)`

- **What** — true when it is closed and no call on it is still running.
- **Promises** — the same predicate `release()` asserts, read under the mutex.
  The usual way to reach this state is to join the threads that touch the pool.
- **Costs** — one mutex.

## Getting

### `fn void? Pool.get(&pool, typeid want, GetMode mode, Slot* slot)`

- **What** — take a stored outer, or ask the hook for a new one.
- **Promises** — four faults: `CLOSED`, `NOT_AVAILABLE`, `NOT_CREATED`,
  `UNKNOWN_IDENTITY`. `NOT_AVAILABLE` comes only from `AVAILABLE_ONLY`, and
  `NOT_CREATED` only from a hook that produced nothing.
- **Costs** — O(n) in the number of identities for the bucket lookup, then
  O(1). **The hook runs outside the mutex**, and everything read before
  unlocking is stale when it returns.
- **Contract** — `@param want : "the identity wanted"` — `pool.c3:283`.
- **Contract** — `@param mode : "which of the three modes"` — `pool.c3:284`.
- **Contract** — `@param slot : "an empty Slot; filled on success"` — `pool.c3:285`.
- **Contract** — `@return? mtk::CLOSED, mtk::NOT_AVAILABLE, mtk::NOT_CREATED,
mtk::UNKNOWN_IDENTITY` — `pool.c3:286`.
- **Checks** — `mtk::@check(slot.is_empty(), "an acquisition asserts the Slot
is empty on entry")` — `pool.c3:293`.
- **Checks** — `mtk::@check(b != null, "Pool.get for an identity the pool was
not created with")` — `pool.c3:308`.
- **Checks** — `mtk::@check(slot.peek().link.type == want, "the get hook
returned an outer of a different identity")` — `pool.c3:349`.

### `fn void? Pool.get_wait(&pool, typeid want, Slot* slot, Duration timeout)`

- **What** — take a stored outer, waiting up to a timeout.
- **Promises** — **it never creates.** No hook is called on this path. Where a
  plain get in `AVAILABLE_ONLY` mode reports `NOT_AVAILABLE`, this reports
  `TIMEOUT`, and the divergence is deliberate. Three faults: `CLOSED`,
  `TIMEOUT`, `UNKNOWN_IDENTITY`.
- **Costs** — blocks on the condition variable. The bucket lookup happens once,
  before the loop; the bucket slice is allocated once and never grown, moved or
  reallocated, so its address stays valid for the pool's whole life, and only
  its contents change under the lock.
- **Contract** — `@param want : "the identity wanted"` — `pool.c3:361`.
- **Contract** — `@param slot : "an empty Slot; filled on success"` — `pool.c3:362`.
- **Contract** — `@param timeout : "how long to wait"` — `pool.c3:363`.
- **Contract** — `@return? mtk::CLOSED, mtk::TIMEOUT, mtk::UNKNOWN_IDENTITY` —
`pool.c3:364`.
- **Checks** — `mtk::@check(slot.is_empty(), "an acquisition asserts the Slot
is empty on entry")` — `pool.c3:371`.
- **Checks** — `mtk::@check(b != null, "Pool.get_wait for an identity the pool
was not created with")` — `pool.c3:380`.

## Putting

### `fn void Pool.put(&pool, Slot* slot)`

- **What** — give an outer back.
- **Promises** — **returns nothing. The Slot is the answer, not the outcome.**
  Cleared means the pool took it; unchanged means it was refused and the caller
  still has the outer. **This path cannot fail and cannot be interrupted**: a
  worker that must give its outer back must always be able to.
- **Costs** — O(n) in the number of identities for each bucket lookup.
  **The put hook runs outside the mutex, and the closed flag is re-read after
  it.** A close can run to completion inside that window; anything this call is
  still holding then goes to the close hook, and the caller's Slot stays
  cleared because the pool did take the outer.
- **Contract** — `@param slot : "a full Slot; cleared if the pool took the
outer"` — `pool.c3:434`.
- **Checks** — `mtk::@check(b != null, "Pool.put of an identity the pool was
not created with")` — `pool.c3:458`.
- **Checks** — `mtk::@check(b != null, "the put hook returned an identity the
pool was not created with")` — `pool.c3:517`, reached through the private
store path for both the Slot and each outer of `extra`.

## Closing and questions

### `fn void Pool.close(&pool)`

- **What** — close the pool and give everything it held to the close hook.
- **Promises** — **cannot fail. Nothing comes back to the caller.** Callable
  more than once: the second call takes nothing and does **not** run the hook
  again. The hook is called once, outside the mutex, after the flag is set.
  Every bucket is emptied into one queue, flattened; the hook never sees
  buckets or per-identity groups. **No order is promised.**
- **Costs** — O(n) in the outers kept, once, on a pool going down. A stack keeps
  no tail, so the O(1) splice is not available. The loop repairs every outer's
  self-link on the way, which a splice would have had to walk and do anyway.

### `fn bool Pool.is_closed(&pool)`

- **What** — is it closed.
- **Costs** — one atomic load, no mutex.

### `fn usz Pool.count_of(&pool, typeid t)`

- **What** — how many of one identity are held.
- **Promises** — **a hint, stale on return.** Zero for an identity the pool was
  not created with.
- **Costs** — O(n) in the number of identities, under the mutex.

## The stack — `@local` to `pool.c3`

**Last-in first-out. Four operations and a guard, all O(1). Nothing here can
fail.** `stack.c3` was deleted by 3TK-62 and `InnerStack` moved to the end of
`pool.c3`; a comment banner marks the section, not a second module line, and
`run-builds.sh` checks that banner because the layering grep cuts at it.

**It is `@local`, so it has no user outside `pool.c3`.** It is documented here
because the pool's costs are its costs, and because `PoolBucket` names it.

**There is no walker and no splice, and no Slot-shaped insert.**

**No caller is entitled to the order.** The pool says the container is a stack;
it does not promise most-recently-returned-first.

### `macro InnerStack.@guard_insert(&self, Inner* inner)`

- **What** — the insertion guard, and the earlier of the two identity
  boundaries.
- **Promises** — an unstamped outer is caught **here**, before any crossing,
  and that is where the message has a home: at an insertion the call that
  omitted the stamp is still on the stack.
- **Costs** — nothing in a fast build.
- **Checks** — `mtk::@check(inner != null, "insert of a null inner")` —
`pool.c3:755`.
- **Checks** — `mtk::@check(!inner::internal::is_linked(inner), "the outer is already on a
chain")` — `pool.c3:757`.

### `fn bool InnerStack.is_empty(&self) @inline` · `fn usz InnerStack.len(&self) @inline`

- **What** — the two questions.
- **Costs** — O(1). `len` is a field read, which is why `PoolBucket` carries no
  count of its own.

### `fn void InnerStack.push(&self, Inner* inner)` · `fn Inner* InnerStack.pop(&self)`

- **What** — add and remove, at the top.
- **Promises** — `pop` on an empty stack returns null. That is an answer, not a
  fault.
- **Costs** — O(1), and nothing allocates.
