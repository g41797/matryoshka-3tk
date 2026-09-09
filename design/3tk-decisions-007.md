# 3tk — the decisions

**What was decided, and where it lives in the code.** One common section, then
one section per source file.

**This is the source of truth.** It is read instead of travelling through the
folder. It accumulates; it does not argue. An entry says what stands, not the
case that was made for it and not the alternative that was refused.

**Every entry carries its marker and its `file:line`.** The marker is the way
back to the document that ruled it. Paths are relative to
`design/secondary/lang/c3/`.

**It is alive.** It is revised whenever a decision changes, and a superseded
version goes to `backup/`. **This is `007`**, written by `3TK-61`, which ruled
the rethinking of the core's shape and built none of it; `006` is in
`backup/`, and `005` is in `matryoshka-tk`'s
`design/secondary/lang/c3/backup/`.

**Revised in place by 3TK-62, 3TK-63 and 3TK-64**, each folding its own entries
out of the ahead-of-the-source section and into the body. **3TK-64 folded the
largest group** — `RT-3`, `RT-5`, `RT-6` … `RT-10`, `RT-12` … `RT-18`, and
`HR-5` — because it is the stage that built the helper.

**This version, and every later one, lives in `matryoshka-3tk/design/`, not in
`matryoshka-tk`'s `ref/`.** Paths beginning `../3tk/` still point into
`matryoshka-tk`, where the source is edited.

**A change to `../3tk/src` revises this file in the same stage.** Not later,
and not as a debt for the next stage to pay. **This file contradicting
`../3tk/src` is a defect of the stage that changed the source** — the owner's
ruling, 2026-08-25. It binds every file under `ref/`, and it exists because
every other document in this folder is frozen: `ref/` is the only place
staleness can hide.

**It does not describe state.** What has run, and what is next, is in
[`../3tk-status.md`](../3tk-status.md).

**The `file:line` citations were repaired by 3TK-66 on 2026-09-08, in one pass
from the built tree, and that was the only pass there will be.** They had been
stale and knowingly so: 3TK-63's renumbering ran in three passes and the third
matched on old line numbers, overwriting what the first two had corrected —
many-to-one, so not reversible from the file — and 3TK-64 then moved almost
every line again, refilling `helper.c3`, rewriting parts of `inner.c3` and
deleting `managed.c3`, which 21 citations still named. The restore was withdrawn
on the owner's ruling and `reapply_decisions.py` is spent.

**How the repair was done, and what a citation now means.** Every citation was
resolved from its entry's own text, not from the number it carried, because
those numbers were the corruption. **Where an entry names a declaration, the
citation is that declaration's line** — 82 of them. **Where an entry rules
something about a file as a whole, the citation is that file's `module` line** —
124 of them, and that is the honest anchor for a ruling that has no single line.
**A citation is a pointer into a file, and only sometimes a pointer at a line.**
The 21 that named the deleted `managed.c3` now name `helper.c3`, where `create`
and `release` live.

**Anything that moves a line in `../3tk/src` must re-run that resolution**, the
same way this file's own rule below requires. It is not a debt for a later stage.

**3TK-70 re-ran it on 2026-09-09**, after the module split moved nearly every
line of four files: 230 citations here, resolved from each entry's own text
against the current tree. **A citation now names one line, the declaration's
own** — the ranges and lists the older anchors carried (`:195-205`, `:60,86,111`)
collapsed to the declarations they were pointing into, because a range measured
against a file that has since been rewritten is a number with nothing behind it.
The rules file is `3tk-rules-004.md` from `3TK-72` on.

**`3tk-boundaries-001.md` is spent, and this file cites it by part number
anyway.** 3TK-66 moved it and `3tk-terms-001.md` to `design/backup/` on
2026-09-08, once their content had dissolved into the source and the books.
**`backup/` is transient — the owner empties it — so it is never a source of
truth**, and a `Part n` or `RT-n` below is a **historical marker**, not a live
link: it says which sitting ruled the entry, and the entry itself says what
stands. **Where the two would differ, this file and `../3tk/src` are what
stands.** The surface, the invariants and the absences now live in
[3tk-reference-009.md](3tk-reference-009.md); the rules that bind a stage live
in [3tk-rules-004.md](3tk-rules-004.md).

---

## Ruled by 3TK-61 — built, and the section closed

**This section ran ahead of the source, and it does not any more.** 3TK-61 was
an analysis stage: the owner ruled the shape of the core on 2026-09-06 and no
`src/` changed, so those decisions had no `file:line` and could not go into the
body without making this file contradict `../3tk/src`. Each build stage folded
its own entries down, with real lines, and deleted them from here. **3TK-66
folded the last of them on 2026-09-08 and closed the section**, which is what
its own discharge rule said would happen.

**Where each group went.** `RT-1` … `RT-18`, `HR-1` … `HR-10` and `HS-1` …
`HS-11` are in the body, under *`inner.c3`*, *`helper.c3`*, *`queue.c3`* and
*the stack, at the end of `pool.c3`*. `RT-4` went down with 3TK-62, `RT-2` with
3TK-63, the largest group — `RT-3`, `RT-5`, `RT-6` … `RT-10`, `RT-12` … `RT-18`
and `HR-5` — with 3TK-64, and the safe-build identity check with 3TK-65.

**Four things this section said are false, and are corrected here rather than
carried down**, because a port that read them got the pre-ruling design:

- **`RT-3` — the helper's module.** This section recorded `helper.c3` declaring
  `module mtk <Outer>;`, and Boundaries `Appendix B` recorded the same as *the
  module is `mtk`, not `mtk::helper`*. **3TK-pre-65 reversed that merge** on
  2026-09-07: one generic section made the whole of `mtk` read as generic on the
  docs site, where `Inner`, `Slot` and `InnerQueue` have nothing to do with
  `Outer`. The file declares **`module mtk::helper <Outer>;`** and the binding
  line is `alias MSG = helper::OF{Msg};`.
- **`PL-6` — the stutter.** This section recorded the crossing as spelled
  `mtk::to_inner`, *because `mtk::inner` is not a module name any more*. **It is
  one again**, for the same reason `RT-3` was reversed. The free crossings are
  spelled **`inner::internal::`** since 3TK-70, and the answer `PL-6` actually gets is that a user
  reaches for the helper member and meets no stutter at all — Boundaries
  `Part 6`, and the *What is deliberately absent* section of
  [3tk-reference-009.md](3tk-reference-009.md).
- **`RT-5` and `RT-13` — `xtn` and the allocator field.** Both stand as
  superseded, and the body's *`managed.c3`* section is the deletion record.
  There is no allocator-field concept in the source at all: no discovery, no
  name rule, and no error when a field is absent. `HR-7` and `HR-10` go with
  them.
- **`RT-7` and `RT-8` — the field name.** They named it `otrid`; it was built as
  `outer_tid`. The body carries the name that is in the source.

### What the measurement established — `MS-1`, and what replaced it

**`MS-1` measured the user's vocabulary on 2026-09-06, before the helper had
users.** Across the 52 files of `../3tk/examples/`: `release` 78, `create` 61,
`.must(` 26, `.to(` 25, `.move(` 4, `.as(` 4, and one each of `is_mine` and
`from_inner`; `init` called zero times; the method forms taken 59 sites to 8,
with a `Slot` receiver in about 50 of the 59, and a bare `Inner*` met only when
dispatching.

**3TK-66 re-measured on 2026-09-08, after moving every example onto the
helper.** The crossings are now `look`, `must_look`, `take` and `must_take`, and
**the five methods beneath them are called at five sites and the free `inner::`
forms at one** — all six inside `012-type_crossing.c3` and
`013-recovering_the_type.c3`, the two examples whose subject is the layering
itself. The ruling `MS-1` supported — *prefer the method to the free form* —
stands for what is left below the helper. **What it measured is spent.**

**`test/` and `negative/` are the mirror image and are not user evidence.** They
probe the primitives deliberately, and that is why all five methods still have
callers there.

---
## Common — true across the port

### Vocabulary and shape

- **Outer and Inner.** The application's struct is the outer; the structure it
  embeds is the `Inner`. `R1`. `../3tk/src/inner.c3:90`.
- **`Outer` is a category and never a type.** No such type is declared
  anywhere. `R1`. `../3tk/src/mtk.c3:40`.
- **A concept gets a C3 type when the type system can express useful semantics
  for it. Otherwise it stays vocabulary.** `Slot` and `Inner` are the worked
  pair. `Slot` is a `typedef`: a distinct type the compiler and the checks
  enforce — it is empty or full, `fill` requires empty and refuses null, `take`
  empties it. It earns a type name. The declaration then spelled
  `alias Handle = Inner*` was an `alias`, so the compiler only ever saw
  `Inner*`: it refused no assignment, refused no null, detected no stale
  pointer, and said nothing about who frees the outer. It bought vocabulary,
  and vocabulary does not need a C3 identifier. **The alias is removed; the
  source says `Inner*`.** `3TK-59`, ruled 2026-09-04.
  `../3tk/src/inner.c3:101`.
- **3tk has exactly two terms: `Inner` and `Outer`. There is no third.**
  `Inner` is a real C3 type and the field you lend; `Outer` is a role and the
  struct you own. **The words *handle* and *item* are retired** — from the
  source, the tests, the examples and every book. Neither named anything the
  pair does not already name: *handle* was the old word for `Inner*`, *item*
  the old word for an outer. This **supersedes `3TK-59`, which kept *handle* as
  an English word** on the porting rule. `Slot` is untouched: it is a real type
  naming a container state, not a participant. `3TK-60`, ruled 2026-09-04.
  `../3tk/src/inner.c3:90`.
- **The embedded field is named `inner`, and a local or parameter of type
  `Inner*` is named `inner`, spelled in full.** It was `node`, which was a
  third term in the same position *handle* held. Measured on c3c 0.8.3: the
  name does not collide with the module `mtk::inner`, because C3 keeps module
  paths and value identifiers in separate namespaces. `3TK-60`, ruled
  2026-09-04. `../3tk/src/helper.c3:152`.
- **Porting is not transpiling, and each port spells the pair as its own type
  system allows.** ztk has `Inner`/`ItemHandle`, C3 has `Inner` and `Inner*`
  with no name for the outer, and **dtk meets the same question**, with D's
  type system possibly giving a different answer. What binds every port is the
  pair itself, not the spelling. `3TK-59`, `3TK-60`. `../3tk/src/inner.c3:90`.
- **No general-purpose list.** Two ordering primitives instead: a queue for the
  mailbox, a stack for the pool. `R2`. `../3tk/src/mtk.c3:40`.
- **The module IS the front door.** C3 needs no re-exporting file.
  `../3tk/src/mtk.c3:40`.

### Visibility

- **Public structs with public fields.** Hiding is possible in C3 and is
  refused on cost. `D1`. `../3tk/src/mtk.c3:40`.
- **Internal fields carry a leading underscore.** Reading them is a
  documentation problem, not a broken invariant. `D1`.
  `../3tk/src/mtk.c3:40`.
- **The containers are submodules, and the reason is enforcement.** A C3
  submodule cannot see its parent's `@private`, so `mtk::mailbox` and
  `mtk::pool` are structurally outside `mtk`. `../3tk/src/mtk.c3:40`.
- **A container uses only what an application could use.** `Part 17.2`, and
  `run-builds.sh` greps for it. `../3tk/src/mtk.c3:40`,
  `../3tk/src/mtk.c3:40`.
- **`@private` does not apply to a C3 method declaration**, and the compiler
  warns that it does not. Measured 2026-08-25.
  `../3tk/src/mtk.c3:40`.

### The helper surface

- **No instantiation and no alias, for any type, ever.** The helper's members
  are macros over `$Type`, generated per call site. `H0`.
  `../3tk/src/mtk.c3:40`.
- **SUPERSEDED by 3TK-64 — `mtk::managed` is gone.** `H0b` read that it follows
  the same shape. **What follows the shape now is `OuterHelper`**, and it costs
  one alias line per outer type rather than nothing — the one place `H0`'s *not
  one line* no longer holds, and it holds nowhere else.
- **The identity is C3's own `Type::typeid`**, and the port does not re-export
  it. `Q2`. `../3tk/src/mtk.c3:40`.
- **The border is held by convention and the layering checks, not by
  visibility.** `inner_offset` is public and cannot be private; since 3TK-70 it
  is `mtk::inner::internal::inner_offset`, on a page of its own.
  `../3tk/src/inner.c3:367`.

### Checking

- **Three tiers, one port macro.** `D6`. Tier 2 is `mtk::@check`
  (`../3tk/src/mtk.c3:66`); tier 3 is `mtk::CHECKED`
  (`../3tk/src/mtk.c3:66`); tier 1 is `always_assert` and has two sites,
  `../3tk/src/mtk.c3:66` and `../3tk/src/mtk.c3:66`.
- **A plain `assert` never guards a contract anywhere in this port.** Under
  `--safe=no -O3` C3's `assert` is an assumption, not a removed check, and a
  violated assumption is undefined behaviour. `Q11`.
  `../3tk/src/mtk.c3:40`.
- **A compiled-out check is paired with ordinary code where a hole would
  otherwise open.** `Part 8.9`. `../3tk/src/mtk.c3:40`.

### Outcomes

- **C3 faults are the outcome mechanism.** `D15`. `../3tk/src/mtk.c3:40`.
- **A Part 19 outcome is a runtime condition, never a defect**, and is reported
  in every build mode. `../3tk/src/mtk.c3:40`.
- **Interruption is dropped.** C3 has no interruptible condition wait, and the
  SHOULD's own text permits the drop. `D9`, `Part 2.9`.
  `../3tk/src/mtk.c3:40`.

### Lifetime

- **A container keeps its allocator for life, and no release call takes one.**
  `D3`, `Part 13.1`. `../3tk/src/mtk.c3:40`, `../3tk/src/mtk.c3:40`.
- **An application outer keeps its allocator in the OUTER, never in the inner.**
  `D3`. `../3tk/src/mtk.c3:40`.
- **A participant is allocated once and lives for the duration of the run.**
  `Part 3.1`. `../3tk/src/mtk.c3:40`, `../3tk/src/mtk.c3:40`.
- **Creation is a transaction.** Each step's failure undoes exactly what
  succeeded before it, through `defer catch`. Nothing partially constructed is
  returned or observable. `../3tk/src/mtk.c3:40`,
  `../3tk/src/mtk.c3:40`.

### Concurrency

- **One wait-loop shape, used by every waiting call.** The deadline is anchored
  once before the loop; the state is re-evaluated from scratch every turn; a
  leaver that times out passes the signal on. `D7`. `../3tk/src/mtk.c3:40`,
  `../3tk/src/mtk.c3:40`.
- **`wait_timeout` is banned in the port.** It recomputes the deadline on every
  call. `D7`, `Part 2.5`. `../3tk/src/mtk.c3:40`.
- **The pre-lock fast read is kept, and the re-read under the lock is not
  optional.** `D16`, `Part 15.4`. `../3tk/src/mtk.c3:40`,
  `../3tk/src/mtk.c3:40`.
- **A hook runs outside the mutex.** `Part 12.3`. `../3tk/src/mtk.c3:40`.

---

## `mtk.c3`

**What it is.** The port's identity and its reading order. One constant.

- **No front-door file to write.** `import mtk` brings in everything
  `module mtk` declares, across every file that declares it. The proposal's
  re-exporting front door does not exist. `../3tk/src/mtk.c3:40`.
- **The reading order is the core in `module mtk`, then the border, then
  `Part 11`'s two optional containers.** The border and the containers are
  submodules of `mtk`. `../3tk/src/mtk.c3:40`.
- **The first five files are the required toolkit; the last two are optional
  tools.** `Part 17.1`, `Part 17.2`. `../3tk/src/mtk.c3:40`.
- **The vocabulary ruling lives here.** Outer and Inner; no `Any` prefix; no
  `NodeList`. `R1`, `R2`. `../3tk/src/mtk.c3:40`.
- **The submodule ruling lives here.** What it proves and what it does not is
  in this file. `D1`, `Part 17.2`. `../3tk/src/mtk.c3:40`.
- **Neither helper module is generic.** `H0`, `H0b`. `../3tk/src/mtk.c3:40`.
- **Part 7.1 was a SPECIFICATION defect and 004 closed it.** `V19`, `E6`.
  `../3tk/src/mtk.c3:40`.
- **The port's three ruling sets are named here** — `D1` to `D16`, `R1` to
  `R15`, and `H0`, `H0b`, `H5` to `H10`. It is the one place in the sources
  that lists them. `../3tk/src/mtk.c3:40`.
- **`VERSION` is `"0.0.1"`.** `../3tk/src/mtk.c3:45`.

---

## `inner.c3`

**What it is.** The inner (`Part 4`), the inner (`Part 10.1`), the Slot
(`Part 9`), the faults, the check macro, the link test, and the compile-time
discovery of the outer's fields. `../3tk/src/inner.c3:81`.

### The inner

- **One field, and it is a built-in pair.** `any link`: `link.ptr` is the chain
  link, `link.type` is the identity. `R6b`, `Part 4.2`, `Part 5`.
  `../3tk/src/inner.c3:81`.
- **The two meanings did not move; only where they are stored moved.** Two
  named fields until 2026-08-25. 16 bytes before, 16 after — an observation, and
  no code may depend on it. `../3tk/src/inner.c3:81`.
- **One link, not two.** `prev` is deleted. Nothing needed arbitrary removal,
  arbitrary insertion, backward traversal or a take from the back. `R5`.
  `../3tk/src/inner.c3:81`.
- **A second field is added only with a reason written down.** `D3` refused an
  allocator here; `R6` refused a membership field. `../3tk/src/inner.c3:81`.

### The self-link

- **The invariant: an outer on a chain has a non-null link, the last outer points
  at itself, an outer on no chain has `link.ptr == null`.** `R6b`.
  `../3tk/src/inner.c3:81`.
- **It replaces invariant 16, retired in place.** `R10`, `V12`.
  `../3tk/src/inner.c3:81`.
- **The price: the link carries two meanings, and a walk that forgets
  `n.points_to() == n` loops forever.** Four sites carry the end test.
  `../3tk/src/inner.c3:81`.
- **The field is named `link` and not `next` because of that price.** On the
  last outer `next` is a false claim. `../3tk/src/queue.c3:71`.

### Writing and reading the link

- **`any`'s halves are read-only**, so every link write rebuilds the whole
  value and carries the identity through by hand.
  `../3tk/src/inner.c3:81`.
- **`Inner.repoint_to` keeps the identity and swaps the chain link**, and it is
  the fourth corner of the stdlib's own table. Nine link writes go through it;
  `helper::init` is the exception. `../3tk/src/inner.c3:335`.
- **`Inner.points_to` is the reader**, and it is what lets a walk site say *the
  last outer points at itself* word for word. `../3tk/src/inner.c3:341`.
- **Methods on `Inner`, not an extension of `any`** — the owner's ruling,
  2026-08-25. Extending a builtin widens the surface past what the change may
  touch. `../3tk/src/inner.c3:90`.
- **Neither is `@private`, and the language decided that.**
  `../3tk/src/inner.c3:81`.

### The inner and the Slot

- **One inner spelling, and it is `Inner*`.** There is no inner type: a
  pointer to an embedded `Inner` is the whole of it. `D4`, `Part 10.1`,
  `3TK-59`. `../3tk/src/inner.c3:90`.
- **The Slot is a container of one inner, or of nothing, and its emptiness is
  the transfer signal.** Empty means the outer is elsewhere; full means the outer
  is here and this Slot's holder is responsible for it. `Part 9.1`.
  `../3tk/src/inner.c3:81`.
- **The Slot is distinct, and a `typedef` and not an alias is what makes it
  so.** An `Inner*` does not implicitly become a `Slot`. `D5`,
  `Part 9.2 rule 1`. `../3tk/src/inner.c3:101`.
- **A Slot starts empty by the language's default state.** There is no
  initializer to forget. `Part 9.2 rule 2`. `../3tk/src/inner.c3:81`.
- **A distinct Slot cannot be read with a bare null test, and the five reading
  members are the replacement.** `Part 9.9`. `../3tk/src/inner.c3:81`.
- **`Slot.fill` carries the never-overwrite check, and it is written once.**
  `Part 9.2 rule 1`. `../3tk/src/inner.c3:151`.

### The faults

- **The Part 19 outcome sets are C3 faults.** `D15`, `Part 15.5`.
  `../3tk/src/inner.c3:81`.
- **`UNKNOWN_IDENTITY` is not a Part 19 outcome, and that is deliberate.** The
  pool's identity set is fixed at creation, so asking outside it is a caller
  defect. It exists because the honest report used to be `NOT_AVAILABLE`, which
  `Part 19.3` reserves for the available-only mode. Reported by `Pool.get` and
  `Pool.get_wait` and by nothing else. `A3`, `P2`, `Part 11.7`.
  `../3tk/src/mtk.c3:56`.
- **`interrupted` is absent, and 003 made that legible in the outcome tables.**
  `D9`, `V13`. `../3tk/src/inner.c3:81`.

### The checks

- **`mtk::@check` is tier 2, and under `--safe=no` it expands to nothing at
  all** — the condition is not evaluated and nothing reaches the optimizer
  as a promise. `D6`, `Q11`. `../3tk/src/mtk.c3:66`.
- **It is public, not `@private`.** `@private` does not reach a submodule, and
  `Part 17.2` entitles an application to the same check.
  `../3tk/src/inner.c3:81`.
- **The message is a compile-time string**, because `always_assert` takes one.
  `../3tk/src/inner.c3:81`.
- **`mtk::CHECKED` is tier 3, and the pool's duplicate-identity scan is the
  port's last reader.** `R6b` deleted the other one. `D6`.
  `../3tk/src/mtk.c3:78`.

### The link test and the repair

- **The link test is exact, and it costs no field.** `h.points_to() != null`
  answers *is this outer on some chain* with no false negative and no false
  positive, in O(1), through the public surface. `R6b`, `Part 8.7`, `V5`.
  `../3tk/src/inner.c3:81`.
- **`Part 8.6` and its O(n) walk are deleted outright.** A check that refuses
  an outer on ANY chain catches everything the same-container walk caught.
  `V4`, `D12`. `../3tk/src/inner.c3:81`.
- **What it does not catch: a chain corrupted by code that reached around the
  container surface.** `../3tk/src/inner.c3:81`.
- **`reset` clears the LINK and not the identity.** `Part 5.4`'s identity is
  written once, by `helper::init`. `Part 8.8`. `../3tk/src/inner.c3:351`.
- **The link test and the repair live with the inner, not with a container**,
  because after `R6b` they are statements about one outer.
  `../3tk/src/inner.c3:81`.

### Compile-time discovery

- **`inner_offset` is where `Part 4.4` — one inner per outer — is checked, and
  it is the only place it can be.** Both messages name the offending type.
  `Part 4.3`, `Part 7.4`. `../3tk/src/inner.c3:367`.
- **A `return` inside `$foreach` does not end compile-time iteration**, so the
  count accumulates and the assertions run afterwards.
  `../3tk/src/inner.c3:81`.
- **`required_alloc_offset` counts as `inner_offset` counts, and refuses a
  type with two `Allocator` fields.** Before, it overwrote on every match and
  took the last silently, so which allocator `release` returned the memory to
  was decided by declaration order and stated nowhere. The two discovery macros
  now read alike and both messages name the offending type. `P1`, `Part 4.4`.
  `../3tk/src/inner.c3:367`.
- **DELETED by 3TK-64, 2026-09-07 — `required_alloc_offset` and the entries
  below it.** `P2` recorded it as declared once in `mtk::inner`, with
  `mtk::managed` its only caller. **There is no such macro, no such caller and
  no such concept.** The entries are kept as a record because a port may have
  read them; none of them describes the source. See *`managed.c3` — deleted by
  3TK-64* for what replaced the build-time gate.
- **`required_alloc_offset` lives inside a macro** because a module-scope
  `$assert` in a generic module cannot see the module's type parameter. `D3`.
  `../3tk/src/inner.c3:81`.

---

## `helper.c3`

**What it is, since 3TK-64.** `OuterHelper` — the one thing a user binds, and
the whole user surface. The crossings themselves live in `inner.c3`; this file
is the named front for them. `Part 3`, `Part 7.5`.

**The entries below the members list are older than this file's second life.**
They were written when `helper.c3` held the crossing macros, and 3TK-63 moved
those into `inner.c3`. They are kept because what they rule is still true of the
crossings wherever the crossings sit. **Their `file:line` were re-anchored by
3TK-66 on 2026-09-08, with the rest of this file.**

### `OuterHelper` — built by 3TK-64, 2026-09-07

- **The module is `mtk::helper`, and it is generic.** `RT-3` first ruled the
  merged form — `module mtk <Outer>;`, relying on C3 permitting one name to be
  both plain and generic (Boundaries `A.6`) — and **3TK-pre-65 reversed it on
  2026-09-07**: one generic section made the whole of `mtk` read as generic on
  the docs site. The file declares `module mtk::helper <Outer>;`, the free
  crossing is spelled `inner::internal::to_inner(&m)` since 3TK-70, and the binding line is
  `alias MSG = helper::OF{Msg};`. **Nothing at a call site grew**: C3 imports a
  module's submodules with `import mtk;` and accepts the last segment of a
  module path. `../3tk/src/helper.c3:40`.
- **`OuterHelper` is a first-class citizen**, not an optional convenience: the
  books lead with it and the macros are the layer beneath. `RT-6`.
  `../3tk/src/helper.c3:59`.
- **`struct OuterHelper { typeid outer_tid; }` — its state is the type
  identity.** `RT-7`. **The field is `outer_tid`, not the `otrid` the ruling
  named**; Boundaries `Part 3.1` is the later document and the source follows
  it. `typeid`, not `void*`: same size, but it type-checks and compares directly
  against `Inner.link.type` with no cast at either end.
  `../3tk/src/inner.c3:110`.
- **The field is carried, never trusted.** No member reads `self.outer_tid` to
  decide anything; every member compares against `Outer::typeid`, the
  compile-time constant from the instantiation. `RT-8`. **`OF` is a `const`**, so
  the field cannot be clobbered even by accident — the ruling accepted a
  writable field, and the `const` made the exposure moot. **It is written into
  the file with its reason.** `../3tk/src/helper.c3:51`.
- **A user binds one alias per outer type**, `alias MSG = mtk::OF{Msg};`, and
  the casing is forced in both directions: an uppercase alias must alias a
  constant. `RT-18`, Boundaries `A.5`. `../3tk/src/helper.c3:40`.
- **An alias cannot be shared across modules.** c3c refuses an unprefixed
  cross-module alias — *"Aliases from other modules must be prefixed with the
  module name"* — so a shared alias buys nothing over the prefix, and **each
  module carries its own**. Measured by 3TK-64 on c3c 0.8.3. `RT-18`.
- **Every member forwards to an `inner.c3` macro and has no logic of its own.**
  `RT-9`. Two spellings must not drift into two behaviours.
- **The surface is designed, not mirrored.** Member names need not match the
  macro names, and not every macro is exposed. `RT-10`.
- **Nine members, and that is a ceiling rather than a target.** The four
  crossings `look`, `must_look`, `take`, `must_take`
  (`../3tk/src/helper.c3:76,99,121,135`), then `inner`, `stamp`, `linked`,
  `create`, `release` (`:146,162,172,191,218`).
- **`look` and `must_look` take a `Slot*` or an `Inner*`**, dispatched at
  compile time on `$Typeof`; `take` and `must_take` take a Slot only, because an
  inner has no Slot to empty. `../3tk/src/helper.c3:76`.
- **`must_take` is new.** The old `move_from_slot` had no abort form.
  `../3tk/src/helper.c3:135`.
- **Two ergonomic targets, and only two: forgetting `init`, and too many
  names.** `RT-16`. Forgetting is answered by `inner()`, which stamps on every
  crossing out of an `Outer*` (`../3tk/src/helper.c3:40`).
- **No dispatch construct** — users write a `switch` on the identity. `RT-17`.
  `Inner.outer_tid()` exists so no user writes `inner.link.type`.
  `../3tk/src/helper.c3:40`.

### `create` and `release` — built by 3TK-64, 2026-09-07

- **`create` and `release` take the allocator. Nothing mandatory is stored.**
  `RT-12`. This undoes a port deviation: ztk never stores it
  (`matryoshka-tk/src/polynode.zig:201,223`), and 3tk stored it only to reach a
  `release` with no argument. `../3tk/src/helper.c3:194,220`.
- **`create` establishes defaults only, and the hook does the rest.** `RT-14`.
  C3 has no struct default field initializers, but `alloc::new_try` allocates
  zeroed when given no `#init`, so the outer arrives at the hook already zeroed.
  **The `#init` struct literal is dropped: a method can set anything a literal
  can, and a method can also fail.** `../3tk/src/helper.c3:194`.
- **Four steps, in this order: allocate zeroed, call `init(a)` if declared,
  stamp, fill the Slot.** **Stamping after the hook is deliberate** — if `init`
  fails the outer was never stamped, so a pointer that escaped a failed creation
  can never be mistaken for a live outer. `../3tk/src/helper.c3:194`.
- **Both hooks are optional and both receive the allocator from the caller.**
  They never read it from the outer. A type that declares neither compiles and
  behaves as before. `../3tk/src/helper.c3:194,220`.
- **`create` returns `void?`, and so does the `init` hook — not `bool`.** A
  `bool` says something failed and nothing about what; an optional lets the
  outer's own fault reach the caller. On a hook failure the allocation is freed
  and the fault propagates unchanged. `../3tk/src/helper.c3:194`.
- **`release` returns `void`, and the reason is narrower than the ergonomics.**
  C3 refuses a bare failable call in a `defer`, and every workaround puts a
  policy choice at each call site. But the honest reason is that **a teardown
  fault has no recipient**: `release` runs on a path usually already unwinding,
  nobody can act on *"freeing failed"*, and the resource is gone either way.
  `init` is the opposite — it fails before anything is committed.
  `../3tk/src/helper.c3:220`.
- **A `destroy` fault aborts in a safe build and is dropped in a fast one.** A
  failing destructor is a defect, not an outcome — the same contract as every
  other `mtk::@check`. `../3tk/src/mtk.c3:66`.
- **The pool's create hook carries the same rule and the same sentence.**
  `RT-15`.

### The containers are ordinary clients — built by 3TK-64, 2026-09-07

- **`_Mbox` and `_Pool` are Outers**, and each takes one `@private` alias and
  crosses through it exactly as an application would. Boundaries `Part 4.6`.
  `../3tk/src/mailbox.c3:483`, `../3tk/src/mailbox.c3:483`.
- **The attribute goes before the `=`:** `alias MBOX @private = mtk::OF{_Mbox};`.
  Measured by 3TK-64 on c3c 0.8.3, at the cost of one build.
- **`to_inner` is the one crossing that does NOT go through the alias**, and the
  reason is concurrency rather than taste. The helper's `inner()` stamps on the
  way out, and this is the direction crossed concurrently: a user turning a live
  `Mailbox*` into an `Inner*` to send it does so while other threads use that
  mailbox. **A stamp writes the bytes it finds, but it writes them.** Both sites
  carry the reason. `../3tk/src/inner.c3:292`, `../3tk/src/inner.c3:292`.
- **They do not use `create`/`release`.** Their construction has four failable
  steps with staged rollback, and `Mailbox.release` is a lifetime contract
  check, not a free. Boundaries `Part 4.6`.

### The border, ruled before the file was refilled

**What it is.** The border. Every crossing between a typed pointer and a
type-erased inner. `Part 7`, `Part 7.5`.

- **Every crossing happens in this file and nowhere else.** That is what makes
  the address arithmetic auditable. `Part 7.5` MUST.
  `../3tk/src/helper.c3:40`.
- **No `inline` on the inner field.** An implicit conversion is a crossing that
  appears at no call site and in no file. `D2`. `../3tk/src/helper.c3:40`.
- **The members are macros over `$Type`; a new outer type costs not one line.**
  `H0`. `../3tk/src/helper.c3:40`.
- **The identity is `Type::typeid`, native.** No per-type mutable byte, which
  is what ztk needed against linker merging. `Q2`, `Part 7.2`.
  `../3tk/src/helper.c3:40`.
- **REVERSED by 3TK-63, 2026-09-07 — the border is now a wall, as far as C3
  will make one.** This entry read *"`helper.c3` is not a wall: `mtk::inner_offset`
  is public, so any module importing `mtk` can compute an offset and cast."*
  Since the merge, `inner_offset` is **`@private` to `module mtk`**
  (`../3tk/src/inner.c3:367`) and a foreign module calling it does not compile.
  Probed, not assumed. What is still open is `Inner.link` itself, which is a
  public field: the door is narrower, not shut, and the books say so plainly
  rather than claiming a lock. `H0` still neither creates nor fixes that.
- **A macro's boundary guard is a `@require` that reports at the CALLER's line.**
  `Part 15.5`'s tiers come from the language here, not from `mtk::@check`.
  `../3tk/src/mtk.c3:66`.
- **One thing is lost against per-type instantiation:** a type declared but
  never crossed with is never validated, because there is no instantiation to
  force `Part 7.4`'s check. `../3tk/src/helper.c3:40`.
- **Part 7.1 as 004 words it is what this file is**, and the history of the
  correction is kept because a reader meeting this file next to 003 should know
  which way it ran. `E6`, `V19`. `../3tk/src/helper.c3:40`.

### The members

- **`is_mine` refuses a null inner and an uninitialized outer.** A zeroed
  typeid matches no type. `Part 5.5`, `Part 7.2`.
  `../3tk/src/inner.c3:247`.
- **REVISED by 3TK-64, 2026-09-07 — the macro is `stamp`, and it no longer
  clears the link.** This entry read *"`init` writes the identity and clears the
  link in one write, and it is the ONE `any_make` in the port whose second
  argument is not an existing `link.type`."* **Both halves changed.** The name
  is `mtk::stamp`, because `init` became the name of the user's own hook and one
  word could not carry two opposite meanings inside one module; the rename
  touched about sixty call sites. And the write **preserves `link.ptr`** —
  `any_make(inner.link.ptr, ...)` — which is what makes the stamp safe on a
  linked inner as well as an unlinked one. Boundaries `Part 5.1`.
  `../3tk/src/helper.c3:167`.
- **The correct line differs from the destructive one by a single
  sub-expression**, and it is written into the file with its reason. The natural
  maintenance edit is `any_make(null, ...)` — the old `init` body verbatim — and
  it silently unlinks a linked outer. `../3tk/src/helper.c3:40`.
- **`stamp` stays a separate call and is not folded into construction** — but it
  no longer has to be remembered. `H8`, `HR-5`. `OuterHelper.inner()` stamps on
  every crossing out of an `Outer*`, and `OuterHelper.stamp()` does it alone for
  an outer allocated by hand. `../3tk/src/helper.c3:152,167`.
- **`Inner.outer_tid()` exists so that no user writes `inner.link.type`.** An
  `@inline` accessor, and the thing a dispatch `switch` reads. It is above
  `inner.c3`'s internal banner for that reason: the helper cannot read an
  identity before the type is known. `../3tk/src/inner.c3:110`.
- **`to_inner` is the only direction that adds the offset, and it cannot
  fail.** The type is inferred; no call site names it.
  `../3tk/src/inner.c3:292`.
- **An inbound crossing names its type, and that is not ceremony.** A crossing
  from an erased inner must say what it expects.
  `../3tk/src/helper.c3:40`.
- **`from_inner` returns null on a mismatch, which is a legitimate state of a
  correct program** — a walker of a heterogeneous list meets other types by
  design. `Part 6.2`, `Part 6.3`. `../3tk/src/inner.c3:298`.
- **`must_from_inner` is the asserting form, named apart**, and its `@require`
  compiles out under `--safe=no`. `Part 6.3`.
  `../3tk/src/inner.c3:309`.
- **One check, not two.** A null inner and a wrong identity are the same kind
  of wrong. `H7`, `Part 15.5`. `../3tk/src/helper.c3:40`.
- **`move_from_slot` has two postconditions and both are tested.** On a match
  the pointer is returned AND the Slot is cleared; on a mismatch null is
  returned AND the Slot is untouched. `Part 9.2 rule 4`.
  `../3tk/src/inner.c3:324`.
- **It computes from the inner `peek` observed, not from `take()`'s return
  value.** `H6`. `../3tk/src/inner.c3:136`.
- **`to` and `as` are `any`'s own names**, so a C3 reader already knows which is
  which. `../3tk/src/inner.c3:180`.
- **`to_inner`/`from_inner`, not `to_inner`/`from_inner`.** `H5`.
  `../3tk/src/inner.c3:292`.

---

## `managed.c3` — deleted by 3TK-64, 2026-09-07

**The file does not exist, and neither does the module.** `RT-5`. `create` and
`release` are members of `OuterHelper` in `module mtk::helper`, and their
entries are above under *`helper.c3`*. **The word *managed* survives in no name** in `src/`,
`test/` or `negative/`. Boundaries `Part 4.1`.

**This section is kept as the deletion record**, not as documentation of a file.
A port reading this file may have read the entries it held.

**What was deleted with it, and what replaced each thing:**

- **`required_alloc_offset`, and the whole allocator-field concept.** `RT-13`,
  superseded entirely. It refused at build time any type with no `Allocator`
  field, and refused any type with two. **Neither is an error now.** The toolkit
  reads and writes no field of an outer except the `Inner`: there is no
  discovery, no name rule, and no error when a field is absent. An outer that
  wants to keep its allocator stores the `create` argument in a field of its
  own, under any name, in its own `init` hook. `HR-7` is deleted with it.
- **The two negative programs that asserted it.**
  `nocompile_managed_no_allocator` and `nocompile_managed_two_allocators` are
  gone, and `run-builds.sh` no longer names them. **Both shapes must now compile
  AND RUN**, so the proof became positive and moved into the test suite:
  `an_outer_needs_no_allocator_field` and
  `two_allocator_fields_are_the_outers_business` in `../3tk/test/t_helper.c3`.
  The check count fell by eight — two programs across four builds.
- **`t_managed.c3`.** Replaced by `../3tk/test/t_helper.c3`.
- **The name.** `H10` ruled that *managed* meant one thing: the outer keeps the
  allocator it was created with, so its release takes none. **`release` now
  takes the allocator**, so the word describes nothing and was not kept for
  anything to describe.

**One thing the deletion did NOT withdraw.** `E7`/`H0b` — *the distinction lives
at the call site, and no type declares itself managed* — outlived the module it
was written for. **No type declares itself anything**; an outer is a struct with
an `Inner` field, and every choice is made where the call is written. The alias
line is a binding, not a declaration of kind.

---

## `queue.c3`

**What it is.** The intrusive queue, first-in first-out. `Part 8`. Eight
operations.

- **There is no general-purpose list.** `NodeList` offered sixteen operations
  and nine had no caller. `R2`, `R3`. `../3tk/src/queue.c3:22`.
- **003 made that a legal reading of `Part 8.1` rather than a deviation.** 8.1
  says *ordering primitives*. `V2`. `../3tk/src/queue.c3:22`.
- **Nothing allocates, the outer is the inner, and every operation is O(1)** — in
  every build mode, because `R6b` deleted the insert walk.
  `../3tk/src/queue.c3:22`.
- **This is the port's TRANSFER container.** What crosses the public surface is
  always an `InnerQueue`. `R13`. `../3tk/src/queue.c3:33`.
- **This is the layer where the checks live, and `Part 8.10`'s bridge is
  dropped** — C3's stdlib has no intrusive list, so there is no other side.
  `Part 8.5`. `../3tk/src/queue.c3:22`.
- **No operation here can fail, and there is no fault type in the file.** A
  take from an empty queue returns null; that is an answer.
  `Part 19.4`. `../3tk/src/queue.c3:22`.
- **The count is kept, so `len` is O(1).** `Part 11.7` asks for a separate
  count only where the length is not. `../3tk/src/queue.c3:61`.
- **The walker is `Part 8.4`, and removing the current outer during a walk is
  not supported.** `../3tk/src/queue.c3:22`.
- **The dispatch table is the application's, not something the toolkit ships.**
  `V18`, `Part 6.5`. `../3tk/src/queue.c3:22`.
- **The insert guard is ONE check, tier 2**, and it moves the guard from tier 3
  to tier 2 so a safe build pays O(1) per insert. `R6b`, `V4`.
  `../3tk/src/queue.c3:22`.
- **The end test `n.points_to() == n` is not optional.** A walker that followed
  the link blindly would hand the last outer back for ever.
  `../3tk/src/queue.c3:22`.
- **There is no `push_front`.** `R15` dropped `Pool.put_all`, its only caller.
  `../3tk/src/queue.c3:22`.
- **`push_back_slot` is required at the public surface**, because `Part 12.5`'s
  composite hook gives a container to the application. `V3`.
  `../3tk/src/queue.c3:100`.
- **An empty Slot is a defect on an insert, not a no-op.** Rule 6's tolerance
  is for release. `../3tk/src/queue.c3:22`.
- **`pop_front` recognises the sole outer by `head == tail`**, not by a null
  link: with the self-link there is no null link on a chain.
  `../3tk/src/queue.c3:115`.
- **`append_queue` is O(1) and needs no repair at the join.** `other.tail` is
  already self-linked. `Part 8.9`. `../3tk/src/queue.c3:157`.
- **Self-move is refused twice — an assert and an early return** — because the
  naive move rings the outers into a cycle and loses every one.
  `Part 8.9`. `../3tk/src/queue.c3:22`.
- **`take()` gives the caller everything the queue holds and empties the
  source, O(1), and cannot fail.** Written for the by-value `Pool.on_close`,
  `P6`, built by 3TK-56. `../3tk/src/queue.c3:22`.

---

## The stack, at the end of `pool.c3`

**What it is.** The intrusive stack, last-in first-out. `Part 8`. Four
operations. **Since 3TK-62, 2026-09-07, it is not a file and not a module**: it
is the last section of `pool.c3`, inside `module mtk::pool`, marked by a comment
banner and not by a second module line. `../3tk/src/pool.c3:126`.

- **It is private to the pool, and that reverses 3TK-45.** The 2026-08-26
  ruling — *"it is available to a caller like the queue"* — is **withdrawn**.
  `InnerStack` is no longer a name a user can reach: `mtk::stack` is gone,
  `test/t_stack.c3` is deleted, and `pool.c3` is its only user, as it always
  was in practice. `RT-4`. `../3tk/src/pool.c3:742`.
  - **What made the reversal available** is that `@private` reaches the module
    and nothing else, so *"who may call this"* has one answer: do we share a
    module. Boundaries `Part 4.2`, `Part 4.3`.
  - **What it cost** is that `mtk::pool` is a submodule and cannot see `mtk`'s
    privates, so `mtk::inner::reset` and `mtk::inner::is_linked` — which the
    stack calls — **cannot become `@private`**. Boundaries `Part 4.3`, and
    3TK-63 writes them the *"public because"* line.
  - **What it did not cost** is the layering check. `run-builds.sh`'s grep for
    a container reaching around the container surface works on `pool.c3` as a
    file, and the stack *is* the surface. It was **narrowed** in the same pass
    to the container half of the file, cut at the banner, with the emptiness of
    that half asserted — because Boundaries `Part 4.5` records it as the only
    enforcement there is. `../3tk/run-builds.sh:229-263`.
- **`Part 8.1` permits it in the plural since 003.** `V2`.
  `../3tk/src/pool.c3:126`.
- **The pool keeps one per identity, and it is the only `InnerStack` in the
  port.** It is on no signature 3tk publishes — the four container-typed ones
  take an `InnerQueue*`. `R2`, `R11`, `R13`. `../3tk/src/pool.c3:742`.
- **No walker** — nothing walks a free list and `Part 8.4` is a SHOULD — **and
  no splice**, because a stack keeps no tail. `../3tk/src/pool.c3:126`.
- **There is no Slot-shaped insert.** `push_slot`'s only caller was `put_all`,
  which `R15` dropped; with that gone it had none, and it was deleted
  2026-08-24 on the owner's instruction. `R15`, `R13`, `P6`.
  `../3tk/src/pool.c3:126`.
- **The stack is the storage container, where the queue is the transfer
  container.** Outers rest in it until they are wanted again. That is the
  stack's own reason, and it does not depend on the pool. `R2`.
  `../3tk/src/pool.c3:742`.
- **The pool reuses last-in first-out for DEFECT SURFACING, not for
  performance.** The outer just given back is on top, so a stale writer and a new
  holder collide immediately instead of much later. It is the owner's reason, and
  this entry is the only place it is written down. `R11`.
  `../3tk/src/pool.c3:126`.
- **No caller is entitled to the order, and that is what keeps the property
  useful.** `Part 11.7` stays silent on order; `Part 11.10` MUST already
  promises nothing. `R11`, `R14`. `../3tk/src/pool.c3:742`.
- **There is no `tail`.** That is what makes `Pool.close`'s flatten O(n) rather
  than a splice, and `R12` accepted the cost. `../3tk/src/pool.c3:532`.
- **`top` and a kept count, so `len` is O(1)**, and `Part 12.4`'s hint is read
  from it under the lock. `../3tk/src/pool.c3:773`.
- **The insert guard is the same one the queue carries, for the same reason.**
  `R6b`. `../3tk/src/pool.c3:126`.
- **The bottom outer points at itself, and `pop` recognises the sole outer by
  `h.points_to() == h`.** `../3tk/src/pool.c3:796`.
- **Nothing here can fail.** `Part 19.4`. `../3tk/src/pool.c3:126`.

---

## `mailbox.c3`

**What it is.** A queue of outers, with waiting. Many producers, many consumers,
on one object. `Part 11.3` to `11.6`, `Part 19.1`.

### The structure

- **The mailbox is itself an outer.** It embeds an inner, has a type identity,
  and can travel through another mailbox. `D1` kept that literal by refusing the
  opaque-type route: a `typedef Mailbox = void` embeds nothing. `Part 11.1`.
  `../3tk/src/mailbox.c3:27`.
- **The five parts are spelled out rather than shared.** Sharing them would put
  a second inner in the outer and break `Part 4.4`. After 003 the refusal is the
  specification's to allow. `V6`, `Part 11.2`.
  `../3tk/src/mailbox.c3:27`.
- **TWO queues, not one list with an anchor.** Out-of-band outers live in their
  own queue and every take tries `_oob` first, so absolute priority with
  first-in first-out inside each class falls out of the structure. `R7`, `V7`,
  `Part 11.3`. `../3tk/src/mailbox.c3:27`.
- **Invariant 22 is kept; only the mechanism that produced it was deleted.**
  `R9`. `../3tk/src/mailbox.c3:27`.
- **The closed flag is a pair** — read and set under the mutex, also readable
  through the atomic and always re-read under it. `D16`, `Part 15.3`,
  `Part 15.4`. `../3tk/src/mailbox.c3:27`.
- **The wake generation is bumped by the waker, captured by each waiter before
  it waits, compared after every wakeup.** `Part 11.5`.
  `../3tk/src/mailbox.c3:27`.
- **REVISED by 3TK-64, 2026-09-07 — the container writes an alias after all.**
  This entry read *"the container's own crossings are macros forwarding to
  `mtk::helper`; `H0` left no alias to write."* Boundaries `Part 4.6` makes the
  container an ordinary client, so it writes the same one line an application
  writes: `alias MBOX @private = mtk::OF{_Mbox};`.
  `../3tk/src/mailbox.c3:53`. **`to_inner` is the exception** and the reason is
  in the *`helper.c3`* section.

### The operations

- **Creation is a transaction**, in the shape `std::threads::channel` uses.
  `../3tk/src/mailbox.c3:27`.
- **Close before release is the one precondition the toolkit refuses to
  soften**, and it is tier 1: `always_assert`, aborting in every build mode.
  `D6`, `Part 11.12` MUST. `../3tk/src/mailbox.c3:27`.
- **`send` is Slot-shaped: on success the Slot is cleared, on a closed mailbox
  it is untouched and the sender still has the outer.** `Part 9.3`,
  `Part 11.6`. `../3tk/src/mailbox.c3:140`.
- **Out-of-band is ONE priority level, not a priority queue**, and two queues
  are one level with a cleaner home. `D14`, `R7`, `Part 11.4`.
  `../3tk/src/mailbox.c3:27`.
- **`poll` is kept beside `receive` although a zero-timeout receive has the
  same reach**, because the two differ in how the empty case is reported.
  `D13`. `../3tk/src/mailbox.c3:181`.
- **The wait loop carries four MUSTs**: the deadline anchored once; a wakeup
  carries no meaning; a leaver on a timeout signals if the queue is not empty;
  the closed flag read under the mutex. `D7`, `Part 2.4`, `Part 2.5`,
  `Part 2.6`, `Part 15.3`. `../3tk/src/mailbox.c3:27`.
- **The leaver must test BOTH queues**, or it consumes a signal and leaves a
  queued out-of-band outer with nobody woken.
  `../3tk/src/mailbox.c3:27`.
- **The give-back order, one rule for `receive_all` and `close` both:** the
  queue is in the order `receive` would have taken them out — out-of-band first,
  then ordinary, first-in first-out within each. `R8`.
  `../3tk/src/mailbox.c3:272`.
- **`receive_all` gives the whole batch to the caller, and releasing the outers
  is the caller's work.** What they are is knowledge the mailbox never had.
  `Part 11.6`. `../3tk/src/mailbox.c3:272`.
- **`wake_all` does not persist.** A thread that starts waiting afterwards
  captures the new generation and is unaffected. `Part 11.5`.
  `../3tk/src/mailbox.c3:301`.
- **`close` is callable more than once, and the test-and-set is inside the
  mutex.** `Part 11.12`. `../3tk/src/mailbox.c3:329`.
- **The named mistake: discarding the queue `close` returns drops the outers**,
  and after `R6b` the refusal at the first reuse is exact.
  `Part 11.6`. `../3tk/src/mailbox.c3:329`.
- **`receive_all` and `close` assert the caller's queue is empty on entry, the
  way every Slot acquisition does.** Both say so in the contract and neither
  checked it; both call `append_queue`, which appends. A reused queue got a
  silently longer chain with no way to tell where the mailbox's outers began.
  Tier 2, and no paired `if` — appending onto a non-empty queue in a fast build
  is defined, not a hole. `P3`, `Part 9.2 rule 3`.
  `../3tk/src/mailbox.c3:272`, `../3tk/src/mailbox.c3:272`.
- **The two vacuous `Part 2.6` signals are gone.** A timed-out waiter reached
  `if (self.has_queued()) self._cv.signal()` only when the `dequeue` two lines
  above had returned null, and under the same held mutex — the condition could
  not be true. `Part 2.6` is satisfied by that dequeue and by a stronger route:
  a waiter that finds an outer does not leave at all, so the wakeup it might
  have consumed it consumed by taking the outer. Removed rather than kept, on
  the `A3` precedent recorded for the pool's get loop: a live-looking branch
  that cannot be taken is a reader's trap. The function-level `Part 2.6` marker
  stands, because the port still owes and still keeps the MUST. `P4`.
  `../3tk/src/mailbox.c3:214`, `../3tk/src/mailbox.c3:214`.
- **`len` is read under the lock and is stale by the time the caller reads
  it.** `Part 12.4`. `../3tk/src/mailbox.c3:374`.

---

## `pool.c3`

**What it is.** A keeper of reusable outers, grouped by type identity. Policy is
not in the pool; policy is in the hooks. `Part 11.7` to `11.10`, `Part 12`,
`Part 19.2`.

### The shape

- **The sharpest asymmetry in the toolkit lives here:** the mailbox gives
  everything back to a caller, and the pool's close gives nothing back at all.
  `Part 11.8`. `../3tk/src/pool.c3:126`.
- **`put_all` is gone.** It was `Pool.put` in a loop — no lock kept, the hook
  still run per outer, no batching and no atomicity — and it gave the difficult
  case back in a different shape. `R15`. `../3tk/src/pool.c3:436`.
- **The counter is recorded:** the caller now writes that loop itself, with a
  chance of getting the refusal case wrong. `R15`.
  `../3tk/src/pool.c3:126`.
- **The hooks are a C3 interface, and `ctx` disappears** — the implementing
  object IS the context. `Part 12.1` MUST. `../3tk/src/pool.c3:126`.
- **A hook runs outside the mutex, several at once on different threads. It
  protects its own shared state, does not call back into the pool, and does not
  block.** `Part 12.3`. `../3tk/src/pool.c3:126`.
- **One free STACK per identity.** `R11`, `Part 11.7`.
  `../3tk/src/pool.c3:126`.
- **No count field beside the stack**, because `InnerStack.len` is O(1) and
  `Part 12.4`'s hint is read from it under the lock.
  `../3tk/src/pool.c3:773`.
- **The buckets are a flat slice, allocated once and scanned linearly.** A hash
  map would buy nothing: the set is small, fixed, and never grows.
  `Part 11.7`. `../3tk/src/pool.c3:126`.
- **The five parts are repeated rather than shared, as in the mailbox.** `V6`.
  `../3tk/src/pool.c3:126`.
- **Only the public surface of the core is used** — five types, `InnerStack`
  being the new one. `Part 17.2`. `../3tk/src/pool.c3:742`.

### The hook contracts

- **`on_get`:** the Slot is empty on entry; create one, or leave it empty to
  report failure. An empty Slot afterwards becomes `NOT_CREATED`. Returning a
  different identity is a defect of the application. `Part 12.2`.
  `../3tk/src/mtk.c3:56`.
- **The contract says which build catches it.** The identity check is
  `mtk::@check`, and `Q4` confirmed the tier: `Part 12.2` files a hook's wrong
  identity as an ordinary defect of the application, so it is not one of the
  two `always_assert` sites. A fast build therefore cannot catch it, and the
  hook contract now says so. Without that sentence a reader could take the rule
  for a guarantee, when the failure is silent: every crossing downstream then
  answers correctly about the wrong type. `W2`. `../3tk/src/mtk.c3:66`.
- **`on_put` has four outcomes and none is mandated.** A full Slot on return
  means one thing: an outer is kept, original or replacement. `Part 12.2`.
  `../3tk/src/pool.c3:126`.
- **`extra` is the composite mechanism**: outers added there are taken the same
  way, with the same checks. `Part 12.5`. `../3tk/src/pool.c3:126`.
- **`on_close` is called once by `close`, and possibly once more with
  stragglers**, and a hook must not free its own context on the first call.
  003 weakened `Part 12.2` for exactly this, and it is the only MUST 003
  weakens. `V11`. `../3tk/src/pool.c3:532`.
- **`on_close` receives one flat queue and no order is promised.** `R12`.
  `../3tk/src/pool.c3:126`.
- **`on_close` takes the queue by value, not by pointer.** *I do not care what
  you did* — the pool passes the outers to the hook and keeps nothing: no
    pointer, no count, no check. `P6` (`3tk-open-defects.md`), ruled
  2026-08-28, built by
  3TK-56. `InnerQueue.take()` (`../3tk/src/queue.c3`) is the O(1) move both call
  sites use. `../3tk/src/pool.c3:126`.
- **The count a hook is given is a hint and is stale** — after the removal on
  get, before the addition on put. `Part 12.4`.
  `../3tk/src/pool.c3:126`, `../3tk/src/pool.c3:126`.

### Creation and release

- **The hooks are a parameter of creation, not a later step.** A pool cannot
  exist without them. `Part 12.1` MUST. `../3tk/src/pool.c3:126`.
- **The identity set is fixed at creation and is not empty.** `Part 11.7`.
  `../3tk/src/pool.c3:126`.
- **A duplicate identity is refused at creation**, because `bucket_for` returns
  the FIRST match and a second bucket would be unreachable for the pool's whole
  life — a silent halving rather than a fault. `Part 11.7`.
  `../3tk/src/pool.c3:185`.
- **That scan is tier 2 with its O(n^2) cost behind the tier gate** — the
  technique `Part 8.6` used, surviving the Part's deletion with no Part left to
  cite. `D6`. `../3tk/src/pool.c3:126`.
- **Creation is a transaction**, and the bucket array is the last thing
  allocated and the one most likely to fail.
  `../3tk/src/pool.c3:126`.
- **Releasing an open pool aborts in every build mode.** The second of the
  port's two tier 1 sites. `D6`, `Part 11.12` MUST.
  `../3tk/src/pool.c3:126`.

### Get, put, close

- **`Part 19.3`'s asymmetry:** `NOT_AVAILABLE` comes only from
  `AVAILABLE_ONLY`, and `NOT_CREATED` only from a hook that produced nothing.
  `../3tk/src/mtk.c3:56`.
- **An identity outside the pool's set is a caller defect.** A checking build
  aborts; a fast build reports `UNKNOWN_IDENTITY`. `A3`, `P2`, `Part 11.7`.
  `../3tk/src/mtk.c3:56`.
- **Everything read before the pool unlocks for a hook is stale when the hook
  returns.** `Part 12.3`. `../3tk/src/pool.c3:126`.
- **No lock is held across a call into application code.** `Part 12.3`,
  `Part 15.2`. `../3tk/src/pool.c3:126`.
- **`get_wait` never creates. No hook is called on that path**, and where a
  plain get in `AVAILABLE_ONLY` reports `NOT_AVAILABLE` this reports `TIMEOUT`.
  `Part 11.9` calls the divergence deliberate. `../3tk/src/pool.c3:366`.
- **ztk's book says twice that `get_wait` calls the creation hook. The ztk code
  says it does not, and the code is the truth.**
  `../3tk/src/pool.c3:366`.
- **`get_wait` reports `UNKNOWN_IDENTITY` too, on two grounds that are not
  conformance:** the two gets must not disagree about the same defect, and a
  defect that sleeps for the whole timeout gets diagnosed as a performance
  problem. `A3`. `../3tk/src/pool.c3:366`.
- **`get_wait` is the one place that holds a `PoolBucket*` across a release of
  the mutex**, and it is safe because the bucket slice is allocated once and
  never grown, moved or reallocated. Only the contents change, and they are
  re-read every turn. `../3tk/src/pool.c3:366`.
- **No such pointer may be held across a call into application code.** A hook
  may put outers back, and the rule there is to look the bucket up again by
  identity. `../3tk/src/pool.c3:126`.
- **No `if (b)` guard on either pop in the loop.** The early return made `b`
  non-null, and a live-looking branch that cannot be taken is a reader's trap.
  `A3`. `../3tk/src/pool.c3:126`.
- **`put` returns nothing: the Slot is the answer, not the outcome.** Cleared
  means the pool took it; unchanged means it was refused. `Part 9.4`.
  `../3tk/src/pool.c3:436`.
- **Unchanged means the POOL refused it, before any hook ran.** All four such
  paths — an empty Slot, the fast closed read, the closed flag under the mutex,
  an unknown identity — precede the hook, and none of `on_put`'s four outcomes
  gives the outer back. The contract said only *it was refused*, which read as
  though a hook could hand it back. Reworded, not rebuilt: taking the outer
  before the answer is known is the ruled design. `W1`, ruled 2026-08-24.
  `../3tk/src/pool.c3:126`.
- **`put` cannot fail and cannot be interrupted.** A worker that must give its
  outer back must always be able to. `Part 2.10`.
  `../3tk/src/pool.c3:436`.
- **`put` re-reads the closed flag after the hook.** `Part 12.3` MUST forces
  the mutex open across a hook, and a close can run to completion inside that
  window. `P1`, ruled 2026-08-24. `../3tk/src/pool.c3:436`.
- **One rule for that window, and it is the pool's own: what the pool holds
  when it discovers it is closed goes to `on_close`.** Invariant 34 holds —
  nothing lands in a bucket after the flag is set. `Part 11.8` holds — nothing
  comes back to the caller. `P1`, `V11`. `../3tk/src/pool.c3:126`.
- **The alternative, restoring the caller's Slot, cannot carry `extra`**, whose
  outers the caller never had. `../3tk/src/pool.c3:126`.
- **`close` empties every bucket into ONE queue, flattened.** The close hook
  never sees buckets or per-identity groups. `R12`.
  `../3tk/src/pool.c3:532`.
- **That flatten is `pop` then `push_back`, O(n) once, on a pool going down**,
  and the loop repairs every outer's self-link on the way — which a splice would
  have had to walk and do anyway. `R12`. `../3tk/src/pool.c3:796`.
- **No order is promised, and `push_back` is chosen for being the simplest
  write.** `R12`. `../3tk/src/queue.c3:85`.
- **`close` is callable more than once and does NOT run the hook again.** The
  test-and-set is inside the mutex. `Part 11.12`.
  `../3tk/src/pool.c3:532`.
- **The hook is called ONCE, OUTSIDE the mutex, AFTER the flag is set.**
  `Part 12.2`. `../3tk/src/pool.c3:126`.
- **`count_of` is a hint, stale on return.** `Part 12.4`.
  `../3tk/src/pool.c3:589`.

---

## Appendix A — markers ruled in the folder that no source cites

**Accounted for, not restated.** Each is a real ruling; none of them appears in
`3tk/src` today, and the reason is given.

| Marker | What it decided | Why no source cites it |
|---|---|---|
| `R3` | Nine of `Part 8.2`'s sixteen operations are deleted | A consequence of `R2`. `queue.c3` and `stack.c3` carry what survived |
| `R4` | The queue keeps a front insert for `Part 11.8` | **RETIRED by `R15`.** `queue.c3:136` records the deletion |
| `R6` | A membership field in `Inner` | **REFUSED 2026-08-23.** Named at `inner.c3:38` as one of the two refusals |
| `R10` | Invariant 16 is retired and replaced by the self-link invariant | Reaches the source as `V12`, `inner.c3:52` |
| `R14` | The specification moves to 003; `Part 11.7` stays silent on order | A specification action. Its second half was at `stack.c3:46`; `stack.c3` was deleted by 3TK-62 and `InnerStack` is now `@local` at the end of `pool.c3` |
| `D8` | The names — `AnyNode`, `AnyHandle`, `NodeList` | Superseded by `R1` and `R2`. No name it chose survives |
| `D11` | The porting order is `Part 22` as written | A process ruling. Nothing in the code can carry it |
| `H1` to `H4` | The per-type helper instance, `OFF` private, `TYPE` public | Written before `H0` and superseded by it. `H0` left no per-type object |
| `H9` | The two layout tests stop asking the helper for the offset | A ruling about `3tk/test`, not about `src/`. `mtk.c3:54` names it in the ruling list only |
| `A4` | `Part 6.5` is defaulted, not skipped | Its subject is `P5` in the audit, not a line of code |
| `A5` | The doc comments are a debt | The subject of plan 015, not of a source line |
| `Q1`, `Q3` to `Q10`, `Q12` | The C3 capability probes | Answered in `../c3-capabilities-001.md`. `Q2` and `Q11` are the two whose answers changed a design decision, and both are cited above |
| `S1` to `S7` | The sanitizer findings | `../3tk-sanitizer-notes-001.md`. About the runs and the tests, not about `src/` |
| `V8` to `V10`, `V14` to `V17` | Specification edits carried into 003 | Edits to the specification's own text. The port's side of each is above, under the file it belongs to |
| `P3`, `P4`, `P5` | Audit findings, still open | Not fixed, so no source line records them. `../3tk-deviations-001.md` holds them |
| `P7` | The wait loop passes the timeout again on every iteration | A finding of `../3tk-drafts-review-001.md` about a draft, not a ruling of this port. See Appendix B |
| `E7` | Nothing is lost by `H0b`; the premise was wrong | It was cited at `managed.c3:21`; `managed.c3` was deleted by 3TK-64, and the ruling itself outlived it — see the closing paragraph of *`managed.c3` — deleted by 3TK-64* |

---

## Appendix B — two things found, and neither is ruled here

**Reported, not decided.** `3TK-19`'s precedent: a decision no document holds is
not taken by this stage.

- **The marker letters collide across two documents.**
  `../3tk-drafts-review-001.md` numbers its own findings `P1` to `P19`, `D1` to
  `D20` and `H1` to `H7`, and those are different decisions from the `P`, `D`
  and `H` series of the audit and the two proposals. A reader who meets a bare
  `D3` cannot tell which document it belongs to without the context. This file
  uses the proposals' and the audit's series throughout, and names the drafts
  review where it means it.

- **`required_alloc_offset` was declared twice, identically. Ruled 2026-08-27,
  and the macro itself is gone.** The copy in `managed.c3` had no reader, and it
  was removed then; `3TK-64` deleted the remaining declaration with the whole
  allocator-field concept. **Neither copy exists, and neither does the idea.**
  `P2`. See *`managed.c3` — deleted by 3TK-64*.
