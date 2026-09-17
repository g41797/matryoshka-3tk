<*
 The `any` border: an unstamped outer arrives.

 An outer the user made by hand and never stamped.
 It stays on the stack, because `create` always stamps.

 Safe build: aborts in `from_any`.
 Fast build: the check is gone; `to_slot` answers null. Exits 0.
*>
module neg;
import mtk;
import std::io;

alias MSG = helper::OF{Msg};

fn int main()
{
	Msg m;
	any a = &m;
	Slot s;

	Msg* got = MSG.to_slot(&a, &s); // <-- the violation: m was never stamped

	io::printfn("no check: an unstamped outer crossed the border, got %p", (void*)got);
	return 0;
}
