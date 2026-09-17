# 3tk — the `any` border

**`001`, written 2026-09-17 by `3TK-87`. The subject document of
[staging plan 044](https://github.com/g41797/matryoshka-ztk/blob/main/design/secondary/lang/c3/3tk-staging-plan-044.md).**

**Status: DECIDED and BUILT.** The surface below was ruled by the owner on
2026-09-17. `3TK-88` built it the same day: `helper.c3`, `test/t_bridge.c3`,
five `negative/any_*` programs.

**Git is disabled.**

A stage reads *What is decided* and *What is open* first.

---

## The use case

**The README's background process, step 2 of *How to start*.**

- Two threads.
- No Mailbox, no Pool.
- Outers travel over C3's `UnboundedChannel(<any>)`.

**The HTTP side of the opening system is the same shape, with one more thing.**

- It listens on an `UnboundedChannel(<any>)`.
- Two kinds of value arrive on it:
    - outers coming back from workers
    - io events, which are ordinary C3 values
- An io event:
    - it allocates an outer, or gets one from a Pool
- An outer:
    - it puts it into a Slot
    - it sends it on through a Mailbox

**The README already promises the crossing** — debt `D-1` of
[3tk-readme-creation-002.md](3tk-readme-creation-002.md):

- *On arrival, `look` checks what arrived.*
- *Never cast. Use `look`, `must_look`, `take`, `must_take`.*

**Today both need a cast of `a.ptr`.**

## The measured facts

**Read 2026-09-17. Re-print before trusting one.** Paths under `src/` are
`matryoshka-3tk/src/`.

### What 3tk has today

- `OuterHelper.look` takes a `Slot*` or an `Inner*` — `helper.c3:87`.
- `OuterHelper.must_look`, the same — `helper.c3:107`.
- `OuterHelper.take` and `must_take` take a `Slot*` only — `helper.c3:127`,
  `helper.c3:139`.
- `OuterHelper.linked` takes an `Outer*` or an `Inner*` — `helper.c3:175`.
- `Slot.fill` takes an `Inner*` — `inner.c3:81`.
- The type test is `internal::is_mine` — `inner.c3:123`.
    - `inner != null && inner.otrtypeid == $Type::typeid`.
- The linked test is `internal::is_linked` — `inner.c3:181`.
- **No call takes an `any`.** `grep -rn '\bany\b' src/` returns nothing.

### What an `any` is

**Two values.**

- `.ptr` — the address, a `void*`.
- `.type` — the **pointee** typeid.
    - `MANUAL.md`: *"returns the underlying pointee typeid of the contained
      value"*.
    - So `any a = &req;` gives `a.type == Req::typeid`, not `Req*`.

**Built without a cast.**

- `MANUAL.md`: *"Any pointer type implicitly converts to `any`."*

**Built by hand, too.**

- `any_make(ptr, typeid)` and `retype_to(typeid)` are in the standard library.
- **So the two values can disagree with the memory they describe.**

### What the channel does

`lib/std/threads/unbounded_channel.c3`, C3 0.8.3.

- `push(Type val)` — `:49`.
    - Copies the value into a deque it grows.
    - For `<any>` that is 16 bytes. The outer is not copied.
    - Returns `CHANNEL_CLOSED` when closed — `:57`.
- `pop()` — `:87`, `try_pop()` — `:69`.
    - Return the value by copy.

**So after a `push`, the sender still has a copy of the `any`.** 3tk cannot
clear it.

### Where `look` is used only as a yes/no test

**The pointer is thrown away at these sites.**

- `if (X.look(s)) { X.release(a, s); ... }`:
    - `examples/017` ×3, `025`, `027`, `029` ×2, `035` ×2
- `expect(..., X.look(&s) != null, ...)`:
    - `examples/018` ×3, `027`, `028`, `029` ×2
    - `test/t_helper.c3:28`
- `examples/010` calls `inner::internal::is_mine` directly, because the public
  helper has no test.

## What is decided

**Everything here is the owner's ruling, 2026-09-17. A stage applies it and
does not reopen it.**

### The border

1. **3tk checks an `any` on its own side, through `OuterHelper`.**
2. **`.type` is a hint. `otrtypeid` inside the outer is the truth.**
    - The README says the same: *the type in the struct is the truth*.
3. **3tk fixes only what it can check.**
    - The copy of an `any` a sender keeps after `push` is the user's.
    - What happens to an `any` on the C3 side is the user's.

### An `any` is a kind of Slot

4. **A Slot has one value, an `Inner*` or null. An `any` has two.**
5. **Both are handled by address:** `&slot`, `&a`.
6. **An `any` is empty when `.ptr == null`.**
7. **Getting from `&a`** — `is`, `look`, `take`, `to_slot`:
    - `.ptr == null` means empty, whatever `.type` says.
    - A successful take clears both fields.
8. **Putting into `&a`** — `to_any`:
    - the target must have `.ptr == null`
    - a stale `.type` is harmless: both fields are written

### The surface, on `OuterHelper`

9. **The calls, and where each is used.**

| call | new / changed | where it is used |
|---|---|---|
| `is(from)` — `Slot*`, `Inner*`, `any*` → `bool` | **new** | dispatch by type; the io side tells outers from io events |
| `look` / `must_look` accept `any*` | **changed** | reading an `any` that arrived |
| `take` / `must_take` accept `any*`; `a` is cleared | **changed** | the receiver takes the outer out of the `any` |
| `to_any(&slot, &a)` / `must_to_any` | **new** | the sender: Slot → `any`, before `push` |
| `to_slot(&a, &slot)` / `must_to_slot` | **new** | the receiver: `any` → Slot, before a Mailbox send or `release`; the sender, after a failed `push` |

10. **A pair, one call per direction.** Named by where the outer goes.
11. **Two forms of each, as `look` and `must_look`.**
    - The plain form returns `null` or `false` on a plain wrong type, and
      leaves the source untouched.
    - The `must_` form aborts.
12. **`is` is for every holder, not only `any`.**
    - `look` stays for when the pointer is needed.
    - The yes/no sites above move to `is` in `3TK-88`.
    - `examples/010` moves off `internal::is_mine`.
12a. **No `must_is`.** Closed by the owner, 2026-09-17.
    - `is` answers a question; `false` is a normal answer.
        - an io event is not a `REQ`
        - an empty holder has nothing in it
    - A `must_` form exists to return something usable. `must_is` would return
      nothing.
    - When the type is known, `must_look`, `must_take` and `must_to_slot`
      abort and give the outer.
    - The bugs already abort inside `is`: a forged `any`, an unstamped outer.

### What always aborts, in both forms

13. **`.type` says `Outer`, and `otrtypeid` does not.**
    - The `any` was built by hand, or points at the wrong thing.
    - It is not a plain wrong type, so `look` and `take` abort too.
14. **An unstamped outer.** As everywhere else.
15. **A linked outer, in both directions.**
    - Out: an outer still in a queue would be in two places.
    - In: the other side left it in a queue, and arrival is the only moment 3tk
      sees it.
    - One rule: *an outer crosses the border unlinked.*
16. **A target that is not empty.** As `create` on a full Slot.

### The order of checks on a move

17. **Source not empty → type (`.type`, then `otrtypeid`) → stamped → not
    linked → target empty.**

### The examples group

18. **`l_bridge`.** Closed by the owner, 2026-09-17.
    - `c_crossing` is `Inner` ↔ `Outer`, inside Matryoshka. A bridge joins two
      worlds, and carries traffic both ways.
    - **Both words stay.** The border is the line between Matryoshka and C3.
      The bridge is the calls that cross it.

### The shape in use

```c3
// the sender
any a;
REQ.must_to_any(&slot, &a);
if (catch ch.push(a)) REQ.must_to_slot(&a, &slot);   // back into its Slot

// the receiver
any a = ch.pop()!;
if (REQ.is(&a))
{
    Slot s;
    REQ.must_to_slot(&a, &s);
    // send s on through a Mailbox, or release it
}
// otherwise a is an io event, and it is the user's
```

**Measured by `3TK-88`: this shape compiles and runs.**

- `test/t_bridge.c3`, `the_shape_over_a_channel` and `a_failed_push_goes_back_to_the_slot`.
- The channel type is spelled `UnboundedChannel{any}`, made by `channel::create_unbounded{any}(mem)`.
- A test body has no optional return, so the test writes `!!` where the shape writes `!`.

## What is open

**Nothing.** Both points were closed by the owner on 2026-09-17: `must_is`
(12a) and the group name (18).

## What this does to other documents

**Rule 14: more than a sentence is a new version; the old one goes to
`backup/` with `mv`.**

- **`3TK-87`:**
    - `3tk-decisions-008.md` → `009`, this ruling recorded.
    - `3tk-readme-creation-002.md`, in place: `D-1` and `D-2` point here.
- **`3TK-88`, once the code exists:**
    - `3tk-api-007.md` → `008`
    - `3tk-reference-013.md` → `014`, with `check-doc-loop.sh` and
      `move-module-docs.sh` repointed
    - `3tk-patterns-004.md` → `005`, dispatch by `is`
- **`3TK-89`:** `3tk-example-rules-007.md`, only if the `l_` group needs a rule.
- **Untouched:** `3tk-inner-without-any-001.md` is closed history.

## What this stage does not do

- No `.c3` change.
- No git.
- No copy to `matryoshka-3tk/src/`.

## Changelog

| version | stage | date | what changed |
|---|---|---|---|
| `001` | `3TK-87` | 2026-09-17 | Created. The surface ruled by the owner in discussion. |
| `001` | `3TK-88` | 2026-09-17 | In place: status BUILT; *The shape in use* measured. |
