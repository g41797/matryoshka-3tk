<*
 The demo outers shared by every example.

 - `Event` has its `Inner` at offset zero.
 - `Sensor` and `Holder` do not, and they cross the same way.

 Every outer the helper creates declares both hooks, `init` and `finish`.
 An empty body means the type has nothing to do.
 All three store their allocator in `init`.
 Storing it is each outer's choice, not a rule.
 The toolkit reads no field of an outer except the `Inner`.
 The toolkit never stores the allocator.
 An outer with no use for an allocator still declares both hooks and has no such field.

 There is no alias here, because C3 refuses an unprefixed alias from another module.
 A shared alias would have to be written `outers::HOLDER` at every call.
 So every example file declares its own alias, one line per outer type it uses.
*>
module shc::outers;
import mtk;
import std::core::mem::alloc;

struct Event  { Inner inner; int code; Allocator alloc; }
struct Sensor { int reading; Inner inner; Allocator alloc; }
struct Holder { int id; Inner inner; Allocator alloc; }

fn void? Event.init(&self, Allocator a)  { self.alloc = a; return; }
fn void? Sensor.init(&self, Allocator a) { self.alloc = a; return; }
fn void? Holder.init(&self, Allocator a) { self.alloc = a; return; }

// None of the three acquires anything in `init`, so `finish` has nothing to free.
// The empty bodies are complete, not missing code.
fn void Event.finish(&self, Allocator a)  { }
fn void Sensor.finish(&self, Allocator a) { }
fn void Holder.finish(&self, Allocator a) { }
