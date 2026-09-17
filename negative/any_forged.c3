<*
 The `any` border: `.type` says one outer, and `otrtypeid` says another.

 The `any` was built by hand.
 `Twin` has the same layout as `Msg`, so the inner is found where `.type` says.
 It is not a plain wrong type, so the plain form aborts too.

 Safe build: aborts in `from_any`.
 Fast build: the check is gone; `look` answers null. Exits 0.
*>
module neg;
import mtk;
import std::io;

struct Twin
{
	int id;
	Inner inner;
}

fn void? Twin.init(&self, Allocator a) { return; }
fn void  Twin.finish(&self, Allocator a) { }

alias TWIN = helper::OF{Twin};
alias MSG = helper::OF{Msg};

fn int main()
{
	Slot s;
	if (catch TWIN.create(mem, &s)) return 1;
	any a = any_make(TWIN.must_look(&s), Msg::typeid);

	Msg* m = MSG.look(&a); // <-- the violation: a Twin dressed as a Msg

	io::printfn("no check: a forged any was read, got %p", (void*)m);
	return 0;
}
