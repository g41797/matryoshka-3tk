# 3tk — `Inner` without `any`

**`001`, written 2026-09-16. The charter for INTR 12.**

**Status: BUILT. INTR 12 ran and closed on 2026-09-16.** See *What the stage
measured* at the end. The sections above are the charter as it was written; they
are left as they were, and the result is recorded once, below.

**An INTR stage is important work that is not part of the flow.** The flow is
[staging plan 043](https://github.com/g41797/matryoshka-ztk/blob/main/design/secondary/lang/c3/3tk-staging-plan-043.md),
the README. This interrupts it. **The number is the owner's: INTR 12.**

**Git is disabled.**

---

## The ruling

**Two worlds, and 3tk is answerable for one of them.**

- **Matryoshka's nomenclature** is `Inner`, `Outer`, `Slot`, `Mailbox`, `Pool`.
  **3tk is answerable for safety here.** Stamped, right type, not linked, the
  slot emptied on transfer.
- **C3's nomenclature** is `any`, `Deque`, `UnboundedChannel`. **An `any` is an
  ordinary C3 value and its user cares for it** — the HTTP server included.
- **At the border, 3tk converts. That is all.** It gives safe crossings between
  the two worlds, with the checks it can actually make. **It does not police
  what happens to an `any` once it is on the C3 side, and no check is written
  that implies it does.**

**So `any` has no place inside 3tk.** It is a border type. It appears in the
conversion helpers and nowhere else.

## The flow this serves

**Recorded by the owner, 2026-09-16. It is why `any` has to be a border type
and not an internal one.**

**The HTTP side has no Mailbox.** It listens on an `UnboundedChannel(<any>)`
and receives two different things on it:

- **outers coming back from the workers**, as `any`
- **io information**, as `any` — ordinary C3 values that are not outers at all

```text
   io world                        the border                  Matryoshka

   +-------------+
   | http server |
   |             |
   | listens on  |  <---- any ------------------------------ worker
   | Unbounded   |        (an outer, converted out)
   | Channel     |
   | (<any>)     |  <---- any ---- io event
   |             |
   +------+------+
          |
          | inspect a.type
          |
     +----+-----------------------------+
     |                                  |
   io info                          already an outer
     |                                  |
     v                                  v
   allocate an outer,               save it to a Slot
   or get one from the Pool         (no helper for this today)
     |                                  |
     +----------------+-----------------+
                      |
                      v
                 send via Mailbox ------------------> worker
```

**The io side uses Matryoshka without a Mailbox.** It holds outers and a Pool
and someone else's queue. **That is a supported shape, not a workaround** — all
six `h_pool` examples already use no mailbox (`037`, `038`, `039`, `040`, `042`,
`045`, measured 2026-09-16). **The conversions are what make it first-class**,
because until now a border like this had no safe crossing.

**The discriminator is `a.type`.** An `any` whose type matches a known outer is
an outer; anything else is io information. `switch` over a `typeid` compiles in
C3 — `examples/019-dispatch_switch.c3` already switches on one.

**The inbound half does not exist today, and this is the check the owner
asked for.** `OuterHelper.look` takes a `Slot*` or an `Inner*`
(`helper.c3:87`), never an `any`. `Slot.fill` takes an `Inner*`
(`inner.c3:77`). **There is no `any` → `Slot` path in the toolkit.** The
conversion stage adds it.

**So the border is two-way**, and that answers what was open: the conversion
stage carries an outbound half and an inbound half.

**Two facts for the conversion stage, both consequences of this flow.**

- **The identity is stored twice while an outer is outside.** The `any` carries
  it, and so does `otrtypeid` inside the `Inner`. **The inbound crossing can
  compare them**, and a mismatch means the `any` was built by hand or points at
  the wrong thing. **Only 3tk can make that check, and it costs one compare.**
- **The outbound crossing empties the Slot, and the push can still fail.**
  `UnboundedChannel.push` returns `CHANNEL_CLOSED`. The outer is then in an
  `any` with the Slot already empty. **The recovery is the inbound crossing**,
  putting it back into the Slot it came from.
  `examples/031-release_a_refused_transfer.c3` is the precedent for the shape,
  and the `l_` group owes an example of it.

## Why this is worth an interrupt

**`Inner.link` is an `any` whose `.ptr` is not an instance of `.type`.**
`stamp` (`inner.c3:124-127`) builds it as `any_make(chain_ptr, Outer::typeid)`.
The pointer half is `points_to()` — the next item in the queue, or `null`.

- **It is a landmine with no fence around it.** C3 0.8.3 has no field privacy,
  so any module can read `inner.link` and treat it as a real `any`. Doing so
  reads the neighbour as if it were the outer.
- **The border work makes the landmine worse.** The HTTP side wants a real
  `any` of the outer, for `UnboundedChannel(<any>)`. The codebase would then
  carry two `any`s per item that look identical and mean opposite things — one
  safe to push, one that corrupts the far side.
- **It costs nothing to remove. Measured 2026-09-16:** `struct { any link; }`
  is **16 bytes**, `struct { void* ; uptr ; }` is **16 bytes**, `any` is 16.
  **The packing never bought a byte**, and `3TK-21`'s own log entry says the
  same — *16 bytes before, 16 bytes after*.
- **It is why `stamp` is a read-modify-write of the whole field**, which status
  carries as a standing caution: a stamp racing a relink loses the link.
  **Two fields retire that caution** — `stamp` writes the identity and never
  touches the chain.

**This re-opens `3TK-21`, and does so on the owner's word, not a stage's.**
`3TK-21` replaced two named fields with the `any` on 2026-08-25. Its argument
was never size. The border work is new information it did not have.

## The shape

```c3
struct Inner
{
    Inner* link;        // the chain link
    typeid otrtypeid;   // the outer's type
}
```

- **`link` stays `link`.** Not `next`. The owner's word, 2026-09-16.
- **`otrtypeid` is the owner's spelling.** The accessor `Inner.outer_tid()`
  keeps its own name; a field and a method do not clash.
- **The chain convention does not move.** The last item of a chain points at
  itself; `link == null` means not linked.

## What does not change

**No public surface change is intended and none is to be made.**

`Slot` and its eight calls. `Inner.to` / `Inner.as` / `outer_tid`.
`InnerQueue`, `InnerStack`, `inner_offset`. The whole of `OuterHelper`,
`Mailbox`, `Pool`, `PoolHooks`, `GetMode`. The eight faults. No identifier is
renamed outside `Inner`'s own two fields. **No file is renamed. No behaviour
changes.**

**`3TK-21` claimed exactly this in the other direction and it held.** The check
is the same: `c3c test` unchanged at 148, `run-builds.sh` unchanged.

## The measured sites

**Read 2026-09-16. Re-print before trusting one.**

**`any` appears in `src/` at three sites, and that is the whole of it:**

- `inner.c3:19` — the field.
- `inner.c3:127` — `stamp`, `any_make(inner.link.ptr, ...::typeid)`.
- `inner.c3:171` — `repoint_to`, `any_make(to, self.link.type)`.

**`.link` is read at five more sites in `inner.c3`:** `:25` `outer_tid`,
`:119` `is_mine`, `:127` `stamp`, `:171` `repoint_to`, `:174` `points_to`.

**Three in `pool.c3`**, all `inner.link.type`: `:174`, `:245`, `:440`.

**Nine outside `src/`**, all reads of `.link.type`, all of which become
`outer_tid()` and read better for it:

| file | lines |
|---|---|
| `test/t_identity.c3` | `:88`, `:89`, `:104`, and **a comment block at `:17-20` that teaches the packing** and must be rewritten |
| `test/t_mailbox.c3` | `:48` |
| `test/t_pool.c3` | `:138` |
| `examples/019-dispatch_switch.c3` | `:22` |
| `examples/020-dispatch_table.c3` | `:31` |

## Probes, before anything is swept

**Rule 11: the exemplar and the check come first.** `3TK-21` probed and one of
its probes refused. These are the three its reasoning rested on.

1. **A zeroed `typeid` is falsy.** `check_stamped` (`inner.c3:131-134`) reads
   `(void*)inner.outer_tid() != null`, and Part 5.5's *uninitialized inner
   refuses to be claimed* rests on it. **`3TK-21` measured this for a zeroed
   `any`. Measure it again for a zeroed `typeid` field before the sweep.**
   `negative/` has the test that says so; it must still abort.
2. **Size and alignment.** `Inner` is 16 bytes, alignment 8, before and after.
3. **`--safe=no -O3` behaves identically**, on the same probe.

**If probe 1 refuses, stop and report.** It is the only one that can change the
design, and no workaround is to be hunted for.

## Steps — INTR 12

1. **Run the three probes.** Record each result.
2. **Change `struct Inner`** — `inner.c3:17-20`.
3. **Follow the five `inner.c3` sites.** `repoint_to` becomes a plain write of
   `link`. `stamp` writes `otrtypeid` alone and **no longer reads anything** —
   note it in the log, it is the caution retiring. `points_to` returns `link`.
   `outer_tid` and `is_mine` read `otrtypeid`.
4. **Follow the three `pool.c3` reads.** Prefer `outer_tid()` over the field.
5. **Follow the nine sites outside `src/`**, and **rewrite
   `t_identity.c3:17-20`'s comment block**, which teaches the packing as a
   fact. It is the one place that says the old shape out loud.
6. **Re-sync the reference.** Rule 14 if it needs more than a sentence.
7. **Verify** — below.
8. **Log and status.** One log entry. Status: the INTR row, the retired caution,
   and the queued stage.

## Verification

- `c3c build`, `c3c test` — green, **148 tests, unchanged**.
- `run-builds.sh` — **114 passed, 9 failed, the same 9.** Any new failure is
  this stage's.
- `check-doc-loop.sh` — 0 differing, 147 of 147, 0 banned words.
- `run-sanitizers.sh` — **this stage touches the chain field, so it runs.**
- **`grep -rn '\bany\b' src/` returns nothing.** That is the stage's own check
  and the one-line proof it did what it says.
- Every negative still refuses, `unstamped_*` and `wrong_type_*` above all.

## What this stage does not do

- **No conversions.** `Slot`/`Outer` ↔ `any` crossings are **their own stage**,
  with their own subject document, after this one lands. **INTR 12 must be
  verifiable without any new public surface.**
- **No examples group.** The `l_` group for the io border belongs with the
  conversions.
- **No README work.** Plan `043` resumes after.
- **No git. No file renamed. No behaviour changed.**

## What follows, and why in this order

1. **INTR 12** — `any` leaves `Inner`.
2. **The conversions** — `OuterHelper` gains the border crossings. **They are
   typed**, because the outer's pointer is not stored anywhere and
   `inner_offset($Type)` is what finds it. That is the price of keeping `any`
   out of `Inner`, and it is the right one: nothing is duplicated, nothing goes
   stale, and the only `any` in existence is the real one, built at the border
   on demand.
3. **The `l_` examples group** — the io border: converting out, converting
   back, and what the C3 side is answerable for. **Agreed by the owner,
   2026-09-16.** It is the twelfth group, after `k_new_in_3tk`, and it carries
   the border's own subject: **what 3tk checks, and what it cannot.**
   - It needs a carrier file `l_<name>.c3` that declares nothing, `shc.c3` to
     list it, an entry in `t_examples.c3`, and `3tk-example-rules-007.md`
     compliance — no catalog references, no file numbers, no port history.
   - **The conversion stage names the group.** `c_crossing` is
     already the `Inner` ↔ `Outer` crossing, so the `l_` name must not read as
     a second one. The subject is leaving Matryoshka for C3 and coming back.
   - **It is the first examples group with no catalog entry behind it.** The
     catalog is a port of ztk's; this border is new work. `k_new_in_3tk` is the
     precedent for a group that exists without one.
4. **`3TK-85` and the README's solution half.** `Inner`'s shape is the README's
   one code block. **It is written once, after this.**

**`3TK-85`, the problem half, is not blocked by any of this** — it ends before
the first Matryoshka term.

## Open

- **The `l_` group's name.** The conversion stage picks it. Decided that the
  group exists, 2026-09-16.
**Closed 2026-09-16: an outer keeps its stamp when it leaves through the
border.** It is not cleared on the way out, by symmetry with `release` or
otherwise. **`otrtypeid` is what the inbound crossing cross-checks the `any`
against**, and an unstamped outer coming back could not be told from a forged
one. The conversion stage states this in its own document; it is recorded here
because the temptation belongs to that stage and the reason belongs to this one.

**Closed 2026-09-16: the border is two-way.** The owner's flow above has the
HTTP side both receiving outers as `any` and sending them on through a Mailbox.

## Changelog

| version | stage | date | what changed |
|---|---|---|---|
| `001` | — | 2026-09-16 | Created as the charter for INTR 12, after the owner ruled `any` out of 3tk's internals. |


---

## What the stage measured

**INTR 12 ran 2026-09-16 and closed.**

### The probes, all three green, identically in safe and `--safe=no -O3`

- **A zeroed `typeid` is falsy and matches no type.** `check_stamped` and
  Part 5.5 survive the unpacking. **This was the one probe that could have
  stopped the stage.**
- **16 bytes, alignment 8**, before and after.
- **A stamp leaves `link` untouched**, which is the caution retiring.

### The code

**`grep -rn '\bany\b' src/` returns nothing.** That is the stage's own proof.

- `struct Inner` is `{ Inner* link; typeid otrtypeid; }`, and its doc block says
  what each field is.
- **`repoint_to` is a plain assignment** and **`stamp` reads nothing at all** —
  both were `any_make` calls.
- `outer_tid`, `is_mine` and `points_to` read a field each.
- **`pool.c3`'s three reads go through `outer_tid()`**, not the field.
- **Nine sites outside `src/` followed**, all now reading `outer_tid()`:
  `t_identity.c3` ×3, `t_mailbox.c3`, `t_pool.c3`,
  `examples/019-dispatch_switch.c3`, `examples/020-dispatch_table.c3`.
  **`t_identity.c3`'s comment block, which taught the packing, is rewritten.**

### The gates

| check | result |
|---|---|
| `c3c build` | green |
| `c3c test` | **148 passed**, unchanged |
| `run-builds.sh` | **114 passed, 9 failed — the same 9.** No new failure |
| `run-sanitizers.sh` | **3 of 3 clean**, thread at `-O0` and `-O3`, address at `-O0`, 148 tests each |
| `check-doc-loop.sh` | **0 differing, 149 of 149 found, 0 banned words** |

**The doc loop grew from 147 sentences to 149** — the two new `Inner` field
sentences — and found both in the reference.

### The documents

**Three went to a new version, per Rule 14, old ones moved to `backup/` with a
plain `mv`.**

- **`3tk-reference-013.md`** replaces `012`. The section *`any` — the pointer
  and the type, in one value* is now *The two fields — the link and the
  identity*. **`check-doc-loop.sh` and `move-module-docs.sh` both repointed.**
- **`3tk-api-007.md`** replaces `006`. **One promise in it had become false** —
  `stamp` no longer preserves the chain link, because it no longer touches it.
- **`3tk-decisions-008.md`** replaces `007`. `3TK-21`'s entry is **marked
  superseded, not deleted**, and the `any`-as-border-type ruling is recorded
  beside it.

**Edited in place:** `3tk-patterns-004.md` (one code line),
`3tk-rules-007.md` (one `@require` in Rule 1's example),
`3tk-readme-creation-001.md` (its `Inner` facts and `F-1`).

**`3tk-port-findings-005.md` gained a dated note and kept its measurements.**
It is the argument the port made, not the registry of what stands.

**Every live reference to `012`, `006` and `007` was re-anchored**, in both
repos. Historical sentences that name the version current at the time — the
log, the per-stage paragraphs in status, a changelog row — were left alone.

### Two things fixed in passing, Rule 13

- **`3tk-api-006.md` quoted two asserts that no longer exist.** `release`'s
  message on both the mailbox and the pool has said *with a call still running
  on it* since the `quiet` rename; the file still quoted the old wording and
  cited lines that had moved. Corrected in `007`, with the real text and
  `mailbox.c3:65` / `pool.c3:106`. **`rules-049.md` Part 4's *documented asserts
  must exist* is the rule, and a grep is the check.**
- **`3TK-84`'s `F-1` row** said the drafts drew two members where the code had
  one. **The code now has two.** The row is kept, reframed: a claim that was
  never measured is not made true by the code moving under it.

### What is left for the conversion stage

**Nothing about `Inner` is open.** The conversions, the `l_` group and the
inbound/outbound crossings are unstarted and unblocked.
