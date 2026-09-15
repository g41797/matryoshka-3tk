<*
 One `Inner` field, anywhere in the struct, makes it an outer.

 - Creates a `Sensor`, whose `Inner` is not at offset zero.
 - Looks up the `Sensor` from its `Slot`.
 - Checks that the lookup found it.
 - Sets a field.
*>
module shc::c_crossing::embedding_the_inner;
import mtk;
import shc::outers;
import shc::helpers;

alias SENSOR = helper::OF{Sensor};

faultdef EMBEDDING_THE_INNER_FAILED;

fn void? embed_one_inner_anywhere(Allocator a)
{
    Slot s;
    defer SENSOR.release(a, &s);
    SENSOR.create(a, &s)!;

    Sensor* found = SENSOR.look(&s);
    shc::helpers::expect(EMBEDDING_THE_INNER_FAILED, found != null, "Sensor did not cross with its Inner off offset zero")!;
    found.reading = 1;
}
