// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Matryoshka Toolkit (3tk) for building background processing in C3.

 Your process passes around pointers to structs that already exist.
 The code in the middle does not need to know what those structs are.

 This page holds what every module and every user shares.
 The subjects are on the six pages below.

 ## The six modules

 - `mtk` — this page. The version, the outcomes, and the safe-mode check.
 - `mtk::inner` — `Inner` and `Slot`, the two small types everything is written against.
 - `mtk::helper` — one helper per outer type. It creates, releases and checks the type.
 - `mtk::mailbox` — moves outers between threads, without copying and without allocating.
 - `mtk::pool` — keeps used outers so they can be used again, by your rules.
 - `mtk::queue` — a chain of outers that allocates nothing.

 An `::internal` page is not yours to call.

 ## The names

 - An outer is your struct. Your data, plus one `Inner`.
 - An inner is the small part inside it. It keeps the link and the type.
 - A slot is one address, or none. It says whether an outer is still yours.
 - A helper is one per outer type. There is nothing to instantiate.
 - Hooks are your code, and the pool calls them.

 ## When a call fails

 - An operation that fails, fails with one of the faults declared here.
 - The set is fixed, and it is the same set for the whole toolkit.
 - Each call's own page names the ones that call can end with.
 - Each fault is described where it is declared, below.

 ## Safe mode

 - `@check` is how the toolkit states what it refuses.
 - It aborts with a message in a safe build, and compiles away in a fast one.
 - So the checks are a way to find a mistake, not a runtime cost you pay for.
 - A mistake it would catch is still a mistake in a fast build.
 - `CHECKED` is `true` when the checks are there.
 - A `$assert` is different. It is compile time, and it is alive in every build.

 ## Two numbers

 - `VERSION` is the toolkit version.
 - `LOC` is the source line count, computed by the build and never committed.
*>
module mtk;
import std::core::env;

<*
 Toolkit version string.
*>
const String VERSION = "0.0.1";

<*
 Source lines of code, excludes:
 - empty lines
 - comments
 - imports
*>
const String LOC = "[[LOC]]";

<*
 The target container or tool is closed; operation rejected.
*>
faultdef CLOSED;

<*
 Timed out while waiting for an item.
*>
faultdef TIMEOUT;

<*
 No items available in the pool.
*>
faultdef NOT_AVAILABLE;

<*
 Creation hook failed to allocate or return an outer structure.
*>
faultdef NOT_CREATED;

<*
 Queue or mailbox is empty.
*>
faultdef EMPTY;

<*
 Wait operation was interrupted by `wake_all()`.
*>
faultdef WOKEN;

<*
 Requested `typeid` was not registered in this pool.
*>
faultdef UNKNOWN_IDENTITY;

<*
 Send buffer count exceeded user-defined type limit.
*>
faultdef LIMIT;

<*
 Debug assertion macro that triggers in safe compilation modes.

 @param #cond : "the condition that must be true"
 @param $msg : "a message"
*>
macro @check(#cond, $msg)
{
    $if env::COMPILER_SAFE_MODE:
        always_assert(#cond, $msg);
    $endif
}

<*
 `true` if compiled in safe mode.
*>
const bool CHECKED = env::COMPILER_SAFE_MODE;