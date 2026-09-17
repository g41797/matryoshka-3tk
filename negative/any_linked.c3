<*
 The `any` border: an outer crosses while it is still on a queue.

 One rule, both directions: an outer crosses the border unlinked.
 This provokes the inbound one.

 Safe build: aborts in `to_slot`.
 Fast build: the check is gone. Exits 0.
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
	Msg* first = MSG.must_look(&sa);

	InnerQueue q;
	q.push_back_slot(&sa);
	q.push_back_slot(&sb);

	any a = first;
	Slot t;
	MSG.to_slot(&a, &t); // <-- the violation: first is on q

	io::printn("no check: a linked outer crossed the border");
	return 0;
}
