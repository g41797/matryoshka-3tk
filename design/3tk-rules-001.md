# 3tk — the rules

**Written by `3TK-67`, 2026-09-08.** Normative, like
[3tk-example-rules-004.md](3tk-example-rules-004.md). A rule is changed here and
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
[3tk-example-rules-004.md](3tk-example-rules-004.md) already governs. Whether
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
  the block.
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

## 3. Internal declarations are grouped, and the partition is checked both ways

All internal declarations sit **below one banner per file**, with the reason for
their being public stated once under that banner. The banner line is exact:

```c3
// For internal usage - everything below this line.
```

**The marker stays anyway, and the reason is docgen.** Docgen groups by module
alone and publishes no file structure and no `//` comment. A reader on the
generated page sees a flat list with no sections in it. **The banner organises
the source; the marker is the only thing that crosses to the site.**

**Position is the truth, the marker is its consequence.** A per-declaration
marker fails by omission and nothing looks wrong; a declaration cannot fail to be
somewhere. So the check in `run-builds.sh` is two-directional and total: **every
declaration below the banner opens with the marker, and none above it does** —
and the banner's own presence is asserted per file first, so a renamed banner
goes red rather than letting the check find no boundary and pass.

**A file has at most one such banner**, and that is checked too. `mtk.c3` and
`helper.c3` have none, because every declaration in them is the user surface.

**Why these declarations are public at all**, stated here once so no file has to
argue it again:

- `repoint_to`, `points_to`, `InnerQueue.@guard_insert`,
  `InnerStack.@guard_insert` and the internal methods of `_Mbox`, `_Pool` and
  `InnerStack` are **methods**, and C3 ignores `@private` on a method
  declaration — a method is found through its receiver type, not through a
  module path. Measured 2026-09-07: `@local` is ignored on a method too; the
  compiler warns and then accepts the call from another module.
- `reset` and `is_linked` are free functions and could be hidden, but are not:
  `InnerStack` calls them from `mtk::pool`, which is not inside `mtk::inner`.
- `inner_offset` is the one that is hidden, in `inner.c3`'s third section,
  `module mtk::inner @private;`. **`@local` does not work there and was
  measured:** with it, the file's own macros fail to resolve the name.

**Do not build half a door and call it locked.** `Inner.link` is itself public
and writable, so converting the methods to free functions would buy an
enforcement the language only partly grants. State plainly that the door is open
and who is allowed through.

## 4. A module page is a subject, and the root holds only shared vocabulary

`c3c docgen` groups by module and by nothing else, so **a module is a page and a
page wants one subject**. A module that would publish one flat list of
everything is two modules.

**`mtk` is a landing page.** It holds `VERSION`, the `faultdef`, `@check` and
`CHECKED` — four declarations, and all four are user surface, so none takes a
marker. They are the vocabulary every submodule and every user shares:
`mtk::CLOSED` is written into the standing fact `return mtk::CLOSED~;`, and
burying it in a submodule would re-spell it at every user site.

**No new file is created to hold them.** Four public declarations, one a version
and one a fault set, is what a root module is for.

**Every module carries a block.** A module page with no description is a flat
list of signatures and no subject.

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

---

# Part 2 — the stage rules

## 6. Before and after every stage: compact, clear, or nothing

**The session's obligation, not the owner's to ask for.** Before the first stage
and after every stage, say which one — **compact, clear, or nothing** — plainly,
with the reason, and **when the answer is clear, with the exact prompt to
continue with.**

## 7. Before every stage: which model is suitable, and why

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

## 8. The exemplar comes before the sweep

A stage that **changes a rule and applies it** rewrites the check and the one
exemplar declaration **first**, watches the check go red across the files that
have not been swept, and only then sweeps. This is not optional: it is the exact
shape that produced the `wrong_type_must` defect, where the stage's own new check
was what caught it.

**Negative-test a new check in both directions before trusting it.** A check that
has never been seen to fail has not been tested. `3TK-67` broke one declaration
each way — a marked declaration above the banner, an unmarked one below it — and
confirmed each went red.

## 9. A stage tunes the scripts and CI, and the port is one line

Every stage carries its script changes across to `matryoshka-3tk`. The four
ported scripts differ from this repo's copies **only** in the `ROOT` line.

**3tk sources — `.c3`, docs — are edited only in `matryoshka-tk`'s copy**, and
the owner copies them across. **The scripts, the CI `.yml` files and the design
documents under `matryoshka-3tk/design/` are edited in `matryoshka-3tk`
directly.**

## 10. Fix the definition; do not halt on it

Where a plan's stated figure and the measured one disagree, **the measurement
wins and the stage says so in the log.** An owner ruling outranks a marker, and a
count written down in a charter is not a ruling. A stage revises the definition
in passing and keeps going; it does not stop to ask.
