# Matryoshka-3tk Limited Mailbox Send Proposal

## Status

Adopted, implemented by 3TK-78.

## Idea

`Mbox` remains unbounded.

Resource limits are normally handled by `Pool` and user hooks.

A limited `send` can be added as an optional feature for cases where a user wants to limit the number of queued items of one type.

## API

Add an optional `limit` parameter to `Mbox.send`:

```c3
fn void send(Mbox* self, Slot* slot, usize limit = 0)
````

The default value is `0`.

### `limit == 0`

Normal mailbox behavior.

The item is sent without a queue limit.

Existing code does not change:

```c3
mbox.send(&slot);
```

### `limit > 0`

The mailbox checks the number of queued items having the same `typeid`.

If the number is already at the limit, `send` fails.

Example:

```c3
mbox.send(&slot, 100);
```

This allows up to 100 queued items of the item's `typeid`.

The limit applies to items currently queued in the mailbox.

It does not limit the total number of items existing in the system.

## Failure

Add a new send error for the limit condition.

For example:

```c3
error{ Closed, Limit }
```

When the limit is reached:

* `send` returns `Limit`.
* The `Slot` remains unchanged.
* The item is not inserted into the mailbox.

The exact error name can be decided during implementation.

## Type ID

The limit is per `typeid`.

Different item types do not share the same limit.

For example:

```text
limit = 10

Type A:  10 queued -> next A is rejected
Type B:   3 queued -> B can still be sent
```

The mailbox does not need to know the concrete outer type.

It only uses the existing `typeid` carried by the inner node.

## Concurrency

The limit check and insertion must happen under the mailbox lock.

Otherwise several concurrent senders could all observe the same queue count and exceed the limit.

Conceptually:

```text
lock
  check closed
  check typeid limit
  insert item
unlock
```

## Complexity

The first implementation can simply scan the mailbox queue when a non-zero limit is requested.

Normal sends with:

```c3
limit == 0
```

should keep the existing fast path.

No per-type counter or additional mailbox data structure is required by this proposal.

If a real use case later shows that scanning is too expensive, the implementation can be reconsidered.

## OOB Send

`send_oob` remains unbounded.

It does not use the `limit` parameter.

```c3
mbox.send_oob(&slot);
```

OOB items are therefore not affected by the limited-send mechanism.

## Why This Is Optional

The mailbox itself is still unbounded.

The new parameter provides a small additional policy mechanism without changing the basic Mailbox model.

The normal design remains:

```text
Pool
  |
  | resource limits
  | lifecycle
  | hooks
  v
items

Mailbox
  |
  | handle transfer
  | optional queued-item limit
  v
consumer
```

The limited send is useful when the application needs a bound on queued work but does not want to introduce another mailbox type or a separate bounded queue.

## Example

Without a limit:

```c3
mbox.send(&slot);
```

With a limit:

```c3
mbox.send(&slot, 64);
```

OOB:

```c3
mbox.send_oob(&slot);
```

The three operations remain conceptually simple:

```text
send(slot)          -> unbounded
send(slot, limit)   -> optional per-type queue limit
send_oob(slot)      -> unbounded OOB
```

## Scope

This proposal does not introduce:

* a bounded mailbox
* a mailbox capacity
* a global mailbox limit
* a Pool limit
* automatic backpressure
* blocking when the limit is reached
* changes to `send_oob`
* a new mailbox type

It only adds an optional per-`typeid` limit to `Mbox.send`.
