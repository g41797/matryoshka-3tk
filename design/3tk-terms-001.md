# 3tk — the two terms

**3tk has exactly two terms: `Inner` and `Outer`.**
Ruled by the owner on 2026-09-04, superseding 3TK-59's decision to keep
*handle* as an English word.

**This document is scaffolding, not a book.** It holds one design decision
while it is live. The stages cite it, its content dissolves into the code, the
doc comments and the permanent books, and when it is spent it moves to
`design/backup/` with a plain `mv`. That is 3TK-61's closing act.

## 1. The statement

> **You send and receive your own struct.** To get that, you give the
> infrastructure one thing: an `Inner` embedded in it. From then on the
> infrastructure never sees your type — it moves `Inner*`, intrusively and
> type-erased. You get your struct back by crossing once, from `Inner*` to
> `Outer*`, and the identity in the `Inner` is what makes that crossing safe.

This is why there are exactly two terms: **the one you own (Outer)** and **the
one you lend to the infrastructure (Inner)**. It is also why the crossing
helpers are the only place the two meet.

## 2. The pair

- **`Inner`** — **a real C3 type.** `struct Inner { any link; }`. The field you
  embed. Chain link and identity in one. A pointer to an embedded one is
  `Inner*`, and `Inner*` is all the infrastructure ever moves.
- **`Outer`** — **not a type, a role.** The user's struct, which embeds an
  `Inner` so it can be carried intrusively with its type erased. It is a role
  because C3 cannot express it: there is no constraint that says *a struct with
  exactly one `Inner` field*. `mtk::inner::inner_offset($Type)` enforces it at
  compile time and the type system never names it.

**There is no third term.** The ruling of 3TK-59 stands and this follows from
it: *a concept gets a C3 type when the type system can express useful semantics
for it; otherwise it stays vocabulary.* **Handle** and **item** are retired.
Neither named anything the pair does not already name — *handle* was the old
word for `Inner*`, *item* was the old word for an Outer.

**`Slot` is not a third term and does not change.** It is a real C3 type,
`typedef Slot = Inner*`, a box holding one `Inner*` or nothing. It names a
container state, not a participant.

## 3. The operation set

**Everything in `helper.c3` is a spelling of three operations:**

| | operation | what it is |
|---|---|---|
| 1 | **add the offset** | `Outer*` → `Inner*`. Cannot fail. Null in, null out. |
| 2 | **subtract the offset** | `Inner*` → `Outer*`. Safe only once the identity has been compared. |
| 3 | **compare the `typeid`** | is this `Inner*` an `Outer` of the type I expect. Reads `link.type`, changes nothing. |

The seventeen macros in `helper.c3` are these three, spelled for a source
(a pointer, a `Slot`) and for a failure style (null, or abort). **Nothing else
happens at a crossing.** No container is touched, nothing moves, no allocation,
no registration.

## 4. The naming rule

**A name says which of the pair it starts from and which it ends at.**

- a macro that goes to an `Inner*` is `to_inner`; one that comes back is
  `from_inner`, and the aborting form is `must_from_inner`
- a parameter that is a pointer to the user's struct is named **`outer`**
- a parameter or local that is an `Inner*` is named **`inner`**, spelled in
  full. Not `n`, not `inr`, not `h`.
- **the embedded field is named `inner`** — `struct Msg { Inner inner; int v; }`.
  It was `node` before this stage; *node* was a third term in the same position
  *handle* held, and the ruling admits no third term. Ruled by the owner
  2026-09-04, superseding plan 024's own table, which wrote `n`.
- **`inner` does not collide with the module `mtk::inner`.** Measured on c3c
  0.8.3: a parameter, a local and a struct field all named `inner` compile,
  link and run with `import mtk::inner` in scope, because C3 keeps module paths
  and value identifiers in separate namespaces. The abbreviation bought nothing.
- `$Type` in a doc block is *"the outer type"*
- in prose: **an outer**, **the outer**, **outers**. Not *item*, not *handle*,
  not *element*, not *object*.
- a form that reads through a `Slot` keeps `slot` in the name — `from_slot`,
  `must_from_slot`, `move_from_slot` — because `Slot` is a real type

**The method spellings are unchanged**: `Inner.to`, `Inner.as`, `Slot.to`,
`Slot.must`, `Slot.move`. They read from the receiver and need no term in the
name.

## 5. Open items — managed

**Recorded here, not ruled here.** 3TK-61 reads them out of this document.

1. **`managed.c3` pushes an `Allocator` field onto every Outer.** Not by force —
   `required_alloc_offset($Type)` refuses at compile time, and the module block
   says "No type declares itself managed." But `create`/`release` are the only
   allocating helpers on offer, so an Outer that wants them pays the field in
   **every instance**, to store a value identical across all of them. It is
   worst where it is least needed: an Outer allocated through a pool hook
   duplicates per instance what the hook already holds once.
2. **Further issues the owner has not yet enumerated.** 3TK-61 begins by
   enumerating them.

**Also 3TK-61's, and adjacent:** the standing doc-loop `DIFFERS` block is
`managed.c3:5` — "Optional convenience API, not Matryoshka core." — absent from
the reference's `mtk::managed` block, and one of the two standing missing
sentences is that module's summary.

## 6. What the sweep changes, and what it must not

**3TK-60 is a rename and nothing else.** `run-builds.sh` must return numbers
**identical** to 3TK-59 — 87 checks, 0 failures, four builds green, 140 tests
each. A change with no semantics moves nothing.

**Three places say the statement of section 1 outright** rather than leaving it
to be inferred from offset arithmetic: the reference's **Participants** block,
the **`mtk::helper`** module block, and the **`mtk::inner`** module block.
