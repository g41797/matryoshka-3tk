<*
 The `any` border: `to_any` into an `any` that is not empty.

 As `create` into a full Slot.

 Safe build: aborts in `to_any`.
 Fast build: the check is gone, and the any is overwritten. Exits 0.
*>
module neg;
import mtk;
import std::io;

alias MSG = helper::OF{Msg};

fn int main()
{
	Slot sa;
	Slot sb;
	if (catch MSG.create(mem, &sa)) return 1;
	if (catch MSG.create(mem, &sb)) return 1;

	any a;
	MSG.must_to_any(&sa, &a);  // the any is full from here

	MSG.to_any(&sb, &a); // <-- the violation

	io::printn("no check: to_any overwrote a full any");
	return 0;
}
