# 3tk — the rules

**Written by `3TK-67`, 2026-09-08. This is `004`, by `3TK-72`, 2026-09-09**,
which added Rule 12 — a document is versioned, not asked about. Nothing else
changed: Rules 1–11 are `003`'s, word for word. `003` is by `3TK-71`, which
added Rule 6 — the test trees allocate their outers — and renumbered the five
stage rules 6–10 into 7–11 to keep it inside Part 1. `003`, `002` and `001` are
in this repo's `backup/`, which is transient. Normative, like
[3tk-example-rules-005.md](3tk-example-rules-005.md). A rule is changed here and
nowhere else, and where this file and a descriptive document disagree, this file
wins.

**What belongs here: any rule specific to 3tk that is not already in the common
tk set.** If a rule holds for every port it stays where the shared text holds it
and 3tk links it. If it exists only because C3 is C3, or only because a 3tk
stage is run the way it is, it lives here.

**The test: a rule binds a future stage and can be checked.** If it says *this
is how 3tk is written, and here is what goes red when it is not*, it is a rule.
If it says what one stage does, when, or why we chose it, it is not — that goes
to the staging plan, to `3tk-status.md` or to `3tk-log.md`. A decision filed as
a rule binds stages that never agreed to it; a rule filed as a decision is lost
when the plan is spent.

**It does not bind `3tk/examples/`**, which
[3tk-example-rules-005.md](3tk-example-rules-005.md) already governs. Whether
the two ever merge is not decided here.

**It describes 3tk and rules for 3tk only.** It recommends nothing to dtk, otk
or ztk. A finding for another port goes to the consuming port's own folder.

**Two parts, kept apart.** Part 1 is how 3tk source is written; Part 2 is how a
3tk stage is run. Two parts rather than one list, because a reader of the
published repo comes for the first and a session comes for the second, and
mixing them makes each harder to find.

---

# Part 1 — the port rules

## 1. A contract lives inside the doc block, and an assert is not a substitute

In C3 the contract **is** the doc comment. `@require`, `@ensure`, `@param`,
`@return!` and `@pure` are directives parsed out of the `<* *>` block; there is
no separate attribute form. **Delete the block and the check is gone, silently**,
because a missing contract is not an error but an absence.

**This was proved by breaking it.** `3TK-pre-65` stripped the block from
`mtk::must_from_inner` and stripped its type check with it;
`negative/wrong_type_must` stopped aborting in a checking build, and only that
negative program noticed.

**The claim that `@require`/`@ensure` can be replaced by asserts in the body is
one-sixth true.** The manual says *"In safe mode, pre- and post-conditions are
checked using runtime asserts"*, so for the runtime check alone the two are
equivalent. Five things do not survive the swap:

1. **The compile-time catch.** A constant argument violating a `@require` is a
   *compile-time* error. An assert in a body can never be. `must_from_inner`'s
   check is on a macro with a `$Type` argument, which is the case c3c is best at
   catching statically.
2. **Which side is named.** A violated contract is reported against the
   **caller**. An assert fires inside the callee and names 3tk's own file — for
   a library whose subject is a border crossing, that points the user at the
   wrong side of it.
3. **The optimizer, and an obligation.** The compiler *may assume a contract
   holds*, and violating one is **unspecified behaviour**. An assert grants no
   such licence. The swap removes an obligation from the caller, not only a
   check.
4. **`@ensure` binds `return`.** In a body it becomes a local plus an assert
   before every exit; a macro with several exits multiplies the sites and one
   missed path is a silent hole.
5. **`@param [in]`, `[&in]`, `[out]`, `[own]`, `[drop]`, `[init]`** have no
   assert form at all.

**Precedent, measured in the C3 stdlib at `/home/g41797/dev/langs/c3/lib/std`:**
`@require` 1456 uses, `@ensure` 56, `assert(` 92.

## 2. The internal doc block: a marker, then only directives that work

An internal declaration keeps its `<* *>` block. It carries one:

```c3
<*
 For internal usage.

 @param [&in] inner
 @require inner.link.type != null : "unstamped inner"
*>
```

- **The marker is the exact string `For internal usage.`** — a sentence, with the
  period, always the **first line** of the block. Verbatim, so it is checkable
  the way `run-builds.sh` already checks the part banners and `pool.c3`'s stack
  banner. **`check-doc-loop.sh` excludes it by exact match on that string**, not
  by reasoning about punctuation, so it is not a sentence the reference owes.
- **After it, only directives that do work.** No prose, no argument, no *why*, in
  the block. **This is a ruling and not a habit, and 3TK-70 restated it as one so
  that a later stage knows it is amending a decision rather than tidying.** The
  reason is that an internal declaration's page is not a page anybody reads for
  instruction: the marker says *not yours*, and a paragraph after it invites the
  reader to act on what follows. **The consequence, written down: a declaration
  may carry an example if and only if it is not in an `::internal` module.**
- **`@param` is kept when it carries a ref annotation** — `[in]`, `[&in]`,
  `[out]`, `[own]`, `[drop]`, `[init]` — because that is static analysis and a
  null check. **It is dropped when it would be the bare name**, which merely
  restates the signature.
- **Every internal declaration gets the block, including those with no
  directives at all.** One shape, no exceptions.

**Why the block and not a `//` line.** Because the argument that produced `//` —
*the docs site shows a bare signature, which is the only "not for you" signal C3
offers* — has a stronger answer: a marker sentence beats absence, since docgen
publishes the description and publishes nothing about a missing one. And because
it ends the case where obeying the visibility rule deletes a check, so no stage
is tempted to strip a block again.

**Why no exception for a declaration with no directives.** Two shapes means two
checks, and the branch between them is *does this declaration have a contract* —
precisely the fact that broke `wrong_type_must`. Adding a `@require` later would
otherwise turn a routine edit into a formatting migration.

**Superseding `3tk-boundaries-001.md` Part 4.4a.** This rule replaces it. What
4.4a measured stands and is not re-derived: **`c3c docgen` ignores visibility
entirely** — `@private` and `@local` declarations are published as public — so
the language has no way to tell the docs site what is not yours to call. The
**accepted gap** stands with it: `_Mbox`, `_Pool` and `InnerStack` remain listed
as types on the site. Under this rule they are listed *and described as
internal*, rather than listed and undescribed. **No stage is to go looking for a
way around docgen's lack of a visibility filter.**

**The marker does not say "inner".** `Inner` is a type and one of the only two
terms; *"for inner usage"* on `Inner.points_to` would be read as being about
`Inner`.

## 3. Internal declarations live in an `::internal` module, and the partition is checked both ways

All internal declarations of a file sit in **one `mtk::X::internal` module
section**, at the foot of that file, under a banner whose line is exact:

```c3
// For internal usage - everything below this line.
```

**THE MODULE IS THE TRUTH. The banner is a section header for a human, and the
marker is what crosses to the docs site.** 3TK-70 moved the truth here from
position, and the argument changed with it.

**`001` argued from *C3 ignores `@private` on a method*** — the declarations are
public because the language leaves no choice, so the only thing left to do was
say so in a comment and check where the comment sat. **That argument is
superseded, and the answer is now that they are on their own page.** `c3c docgen`
groups by module and by nothing else and **ignores visibility entirely**, so the
one separation the generated page can see is a module. `std::core::cpudetect` is
the standard library's own precedent: **public**, called from
`std::hash::blake3`, and kept off the main page purely by having a page of its
own.

**Why the module and not the position.** A banner is a comment: it can be
renamed, duplicated or deleted, and a check keyed on it must assert its own
existence first or it quietly greps nothing. A module section is the compiler's
partition — **a declaration cannot fail to be in one**, and nothing between one
module line and the next is outside it. So the check in `run-builds.sh` is
two-directional and total: **every declaration in an `::internal` section opens
its block with the marker, and no declaration outside one does.**

**A file has at most one `::internal` section**, and that is checked too.
`mtk.c3` and `helper.c3` have none, because every declaration in them is the user
surface. The banner is still asserted per file, by name — it is no longer load
bearing for the check, and it is still the only section header the source gives a
maintainer.

**The intent is visibility on the docs site, not preventing use**, and where a
visibility attribute and the split disagree **the split wins**. `_Mbox` and
`_Pool` lost `@private` because a `@private` declaration in a submodule is not
visible to its parent, and both parents cast to them on the first line of every
public method. `inner_offset` lost the `module mtk::inner @private;` section for
the same reason. `InnerStack` keeps `@local`, because nothing obstructs it.
**No new attribute is added anywhere to make the split work.**

**Why these declarations are public at all**, stated here once so no file has to
argue it again:

- `repoint_to`, `points_to`, `InnerQueue.@guard_insert`,
  `InnerStack.@guard_insert` and the internal methods of `_Mbox`, `_Pool` and
  `InnerStack` are **methods**, and C3 ignores `@private` on a method
  declaration — a method is found through its receiver type, not through a
  module path. Measured 2026-09-07: `@local` is ignored on a method too; the
  compiler warns and then accepts the call from another module.
- `reset` and `is_linked` are free functions and could be hidden, but are not:
  `InnerStack` calls them from `mtk::pool::internal`, which is not inside
  `mtk::inner`.
- `inner_offset` **was** the one that was hidden. Measured, and it still holds:
  `@local` does not work for it — with it, the file's own macros fail to resolve
  the name — and `@private` in `mtk::inner::internal` would hide it from
  `mtk::inner`'s own crossings. It is public and on the internal page.

**Do not build half a door and call it locked.** `Inner.link` is itself public
and writable, so converting the methods to free functions would buy an
enforcement the language only partly grants. State plainly that the door is open
and who is allowed through.

## 4. A module page is a subject, and the root holds only shared vocabulary

`c3c docgen` groups by module and by nothing else, so **a module is a page and a
page wants one subject**. A module that would publish one flat list of
everything is two modules.

**The second criterion, added by 3TK-70: a submodule is warranted when the
direction of the call inverts** — when the toolkit is the caller and the user is
the implementer. That is why `PoolHooks` and its four-clause charter are
`mtk::pool::hooks` and not a heading on `mtk::pool`'s page: everything else there
is what you *call*, and the charter is a contract on *your* code.

**`GetMode` therefore stays on `mtk::pool`.** It is a value passed on a call the
user makes. **Topic is not the test; direction is.** Without this sentence the
next stage argues for `mtk::pool::modes` on the same reasoning that produced
`::hooks`.

**And an inversion with nothing to declare gets no module.** `OuterHelper`'s
`create` and `release` call the outer's optional `init` and `destroy`, so the
inversion is real — but the hooks are declared nowhere, being resolved
structurally by `$defined`, and a module needs declarations. Moving `create` and
`release` into one would invert the inversion: the user calls them. An inert
`interface OuterHooks` would read as mandatory when both hooks are optional.
**`mtk::helper`'s module block names them in words instead.**

**`mtk` is a landing page.** It holds `VERSION`, the `faultdef`, `@check` and
`CHECKED` — four declarations, and all four are user surface, so none takes a
marker. They are the vocabulary every submodule and every user shares:
`mtk::CLOSED` is written into the standing fact `return mtk::CLOSED~;`, and
burying it in a submodule would re-spell it at every user site.

**No new file is created to hold them.** Four public declarations, one a version
and one a fault set, is what a root module is for.

**Every module carries a block.** A module page with no description is a flat
list of signatures and no subject. **All eleven of them**, `::internal` sections
included: an internal page with no description is exactly the page a reader
cannot tell is internal. `check-doc-loop.sh` diffs every one against its labelled
block in the reference, `mtk::helper`'s generic module line included since
3TK-70.

**And `c3fmt` is not run on `src/`.** Ruled by the owner 2026-09-09, after
3TK-71 met it. The formatter hard-wraps doc-block prose at about 120 columns and
the doc loop cannot survive that. **Measured, on the one run there has been: four
module blocks went `DIFFERS` and the descriptor count went 443 to 453** — a
wrapped continuation line is counted as a sentence of its own, and a wrapped
block no longer matches its labelled block in the reference. The formatter also
deletes the *Little-endian imports* banners and moves the imports under them.
**A stage that wants the source formatted answers the doc loop first**; until
then the committed formatting is what `src/` carries.

## 5. Generated content is never committed

A number, a date or a count that a build computes is **not** committed. It is
injected downstream of the checkout — in CI's own ephemeral checkout, or under a
flag a person typed on a tree they mean to leave dirty. The committed source
carries a token in its place, `[[LOC]]` and — for the shapes that follow it —
`[[NAME]]`.

Three things it would break if generated content were committed instead, and
they are the test for any future proposal of the same shape:

- **The doc loop** would carry a number that is wrong the moment any line of
  `src/` changes, turning a clean run into a permanent `DIFFERS`. A token is
  identical on both sides and never drifts.
- **The two repos would diverge** on a line that is not `ROOT`, because CI runs
  in `matryoshka-3tk`. A committed token is the same line in both.
- **The tree comes back dirty after a build**, which is the noise that hides a
  real change. Injection happens only in CI's ephemeral checkout or under an
  explicit flag, never as a side effect of a local run.

## 6. A test's outer is allocated too, unless the test's subject forbids it

**An outer in `test/` or `negative/` is heap-allocated through the helper,
unless the test's subject forbids it — and then the site says so.**

The shape is the one `test/t_helper.c3` and `examples/006-defer_put_early.c3`
already carry, and nothing about it is new:

```c3
Slot s;
defer HOLDER.release(mem, &s);
if (catch HOLDER.create(mem, &s)) { always_assert(false, "create failed"); }
```

**Why a stack outer is wrong here and not merely untidy.** 3tk computes an
outer's address from its embedded `Inner` at every crossing, and a frame address
is valid for exactly one lexical instance of one frame. A copy of it, or a use
after the frame returns, reaches through a stale address — **and it can appear
to work before it fails.** Stage A ruled a stack outer illegal on 2026-08-31;
`examples/` was cleaned then and the two test trees were not in its scope.

**The exemption is by subject, and it is narrow.** A test whose subject is an
outer that was never stamped cannot use `create`, because `create` always
stamps: `uninitialized_inner_is_refused`, `negative/unstamped_insert` and
`negative/unstamped_crossing` are the three, and `inner_stamps_on_the_way_out` is
a fourth — its subject is an outer the user made by hand. **A site that stays on
the stack carries a sentence at the site saying why** — not a reference to a
plan and not a mark, a sentence a reader of the test understands without leaving
the file. Without it the next reader takes the site for another leftover, which
is exactly how 41 of them survived `3TK-60` through `3TK-70`.

**And an outer allocated on one thread is released on that thread.** `mem` is
per-thread in C3, so a test that creates outers for a worker creates them on the
thread that will free them. Measured by `3TK-71`, which broke
`close_then_join_then_release` by allocating inside the sender thread and
freeing in the parent.

**No check enforces this, deliberately.** A grep cannot tell necessity from
history; it would need an allow-list, and the allow-list would be the judgment
restated in a shell script, where a reader of the test never sees it. The
enforcement that does exist is real: `c3c test` detects leaks in all four
builds, so a `create` without its `release` fails the build rather than passing
quietly.

**It does not bind `examples/`**, which
[3tk-example-rules-005.md](3tk-example-rules-005.md) governs with an absolute
allocation MUST and no exemption at all. The two rules differ in kind — absolute
there, defeasible-by-subject here — and neither is written in terms of the
other.

---

# Part 2 — the stage rules

## 7. Before and after every stage: compact, clear, or nothing

**The session's obligation, not the owner's to ask for.** Before the first stage
and after every stage, say which one — **compact, clear, or nothing** — plainly,
with the reason, and **when the answer is clear, with the exact prompt to
continue with.**

## 8. Before every stage: which model is suitable, and why

**Also the session's obligation, unasked, and it cuts both ways.** A stage that
is a mechanical sweep against a settled rule says so, rather than silently taking
the strongest model.

**The basis, so the advice is a judgment and not a coin toss: how much of the
stage is deciding rather than applying.** A stage that rules, measures, probes,
or writes prose that binds later stages wants the strongest model. A stage that
applies a rule already written, across many files, with a build check that says
when it is wrong, does not. **The middle case is a stage that both changes a rule
and applies it** — the deciding part is small but load-bearing, so it takes the
stronger model and the sweep is cheap either way.

**Each charter in the staging plan carries its own recommendation, by name**, the
way each carries a *where to start*. **It is advice and not an action:** the
session names the model the stage wants; the choice stays the owner's.

**If a pinned model name no longer exists when the stage runs, the basis above
governs and the stage picks its nearest equivalent.** A stale name is not a
reason to stall, and it is not a design question to bring back to the owner.

## 9. The exemplar comes before the sweep

A stage that **changes a rule and applies it** rewrites the check and the one
exemplar declaration **first**, watches the check go red across the files that
have not been swept, and only then sweeps. This is not optional: it is the exact
shape that produced the `wrong_type_must` defect, where the stage's own new check
was what caught it.

**Negative-test a new check in both directions before trusting it.** A check that
has never been seen to fail has not been tested. `3TK-67` broke one declaration
each way — a marked declaration above the banner, an unmarked one below it — and
confirmed each went red.

## 10. A stage tunes the scripts and CI, and the port is one line

Every stage carries its script changes across to `matryoshka-3tk`. The four
ported scripts differ from this repo's copies **only** in the `ROOT` line.

**3tk sources — `.c3`, docs — are edited only in `matryoshka-tk`'s copy**, and
the owner copies them across. **The scripts, the CI `.yml` files and the design
documents under `matryoshka-3tk/design/` are edited in `matryoshka-3tk`
directly.**

## 11. Fix the definition; do not halt on it

Where a plan's stated figure and the measured one disagree, **the measurement
wins and the stage says so in the log.** An owner ruling outranks a marker, and a
count written down in a charter is not a ruling. A stage revises the definition
in passing and keeps going; it does not stop to ask.

## 12. A document is versioned, not asked about

**When a document a stage touches needs more than a sentence changed, the stage
writes the new version and moves the old one to `backup/` — in the stage, and
without asking.**

- **A new version of a document that already exists is not a new document.**
  The standing *ask the owner before creating a file in
  `matryoshka-3tk/design/`* governs a subject that has no book yet. It does not
  govern `NNN` becoming `NNN+1`.
- **The alternative is worse, which is why this is a rule.** A stage that halts
  costs a round trip and gets the same answer; a stage that edits in place to
  avoid halting loses the text it overwrote, and `backup/` is the only copy
  there ever was.
- **The new version says what changed and who ruled it**, in the header, naming
  the stage and the date — the shape every version in this repo already uses.
- **The old version moves with a plain `mv`.** No git.
- **Live references are re-anchored in the same stage.** A link to the
  superseded number, outside `backup/`, is a defect of the stage that made it
  stale.
- **`backup/` is transient** — the owner empties it — so a superseded version is
  never cited as a source of truth.

**Ruled by the owner, 2026-09-09**, after `3TK-72` halted to ask whether
`3tk-example-rules-004.md` could become `005`.
