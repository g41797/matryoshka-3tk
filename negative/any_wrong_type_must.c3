<*
 The `any` border: `must_to_slot` on an `any` of the wrong type.

 A plain wrong type is an answer for `to_slot`, and a defect for `must_to_slot`.

 Safe build: aborts in `must_from_inner`.
 Fast build: the check is gone. Exits 0.
*>
module neg;
import mtk;
import std::io;

alias JOB = helper::OF{Job};
alias MSG = helper::OF{Msg};

fn int main()
{
	Slot s;
	if (catch JOB.create(mem, &s)) return 1;
	any a;
	JOB.must_to_any(&s, &a);

	Slot t;
	MSG.must_to_slot(&a, &t); // <-- the violation: the any holds a Job

	io::printn("no check: a Job crossed the border as a Msg");
	return 0;
}
