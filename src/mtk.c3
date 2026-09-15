// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 An outer-transfer and outer-reuse toolkit for concurrent C3 programs.

 Three small tools, each one usable on its own.
 The core is type identity for an outer, and two containers that never allocate.
 `mtk::inner` is the inner, the Slot, the link and the crossings.
 `mtk::queue` is the intrusive queue and its walker.
 `mtk::helper` is the one thing you bind, one line per outer type.
 `mtk::mailbox` is transfer of an outer between threads.
 `mtk::pool` is reuse of an outer, decided by your hooks.
 Mailbox and pool are both optional.
 The core alone is a valid use.

 Share by communicating.
 Do not share access to an outer, move the outer.
 One place has the outer at a time.
 That gives a concurrent program with no lock around application data.

 Not a container library, though `InnerQueue` is public and yours to use.
 The queue and the stack exist because the mailbox and the pool need them.
 A caller may use the queue directly.
 The stack is private to the pool.
 Not an allocator.
 Every outer is allocated and freed by your code, or by your hooks.
 Not a garbage collector.
 The toolkit never frees an outer you gave it, except through a hook you wrote.
 Not a coordinator.
 There is no `Master` type.

 One import gives the toolkit.
 `import mtk;` gives this module and every submodule of it.
 This module holds `VERSION`, the faults, `@check` and `CHECKED`.
 They are the vocabulary every submodule and every user shares.
 Each subject is on the page of the module that holds it.

 We present you [[LOC]] lines of source.
 *>
module mtk;
import std::core::env;

<*
 The toolkit's version string.
*>
const String VERSION = "0.0.1";

<*
 matryoshka-3tk lines of code
 calculated during docs generation
 includes all c3 files under src
 excludes:
 - empty lines
 - comments
 - imports
*>
const String LOC = "[[LOC]]";

// 3tk faults, returned via `void?`. Only `UNKNOWN_IDENTITY` causes abort in a
// safe build.

<*
 The mailbox or pool is closed. The call is refused.
*>
faultdef CLOSED;

<*
 A wait on the mailbox or the pool ran out its whole timeout and found nothing.
*>
faultdef TIMEOUT;

<*
 `Pool.get` asked for a free outer only, and none was free.
*>
faultdef NOT_AVAILABLE;

<*
 The pool's `on_get` hook was asked to make an outer, and left the Slot empty.
*>
faultdef NOT_CREATED;

<*
 `Mailbox.poll` found nothing queued.
*>
faultdef EMPTY;

<*
 `Mailbox.wake_all` woke a receiver that was waiting.
*>
faultdef WOKEN;

<*
 The pool was asked for a `typeid` it was not created with.

 The one fault that aborts in a safe build. Asking for an identity outside the
 pool's own set is a defect in the caller, not a runtime outcome to handle.
*>
faultdef UNKNOWN_IDENTITY;

<*
 `Mailbox.send` refused the outer: that many of the sender's own `typeid` are
 already queued.
*>
faultdef LIMIT;

<*
 Aborts in a safe build.

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
 True for safe mode
*>
const bool CHECKED = env::COMPILER_SAFE_MODE;
