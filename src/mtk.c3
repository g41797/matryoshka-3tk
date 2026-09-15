// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

<*
 Matryoshka Toolkit (3tk) for building background processing in C3.
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