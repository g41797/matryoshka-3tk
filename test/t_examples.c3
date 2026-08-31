<*
 The wrappers for `examples/`, catalog sections "Slot and transfer idioms" and
 "Crossing the border".

 Every example is called by one `@test` here, and `always_assert` appears in
 this file and nowhere in `examples/`.
*>
module mtk_test;
import mtk;
import mtk::managed;
import mtk::mailbox;
import std::core::mem::alloc;
import std::time;
import exm::outers;
import exm::empty_slot;
import exm::transfer_empties_slot;
import exm::insert_from_slot;
import exm::null_safe_cleanup;
import exm::defer_put_early;
import exm::defer_release_early;
import exm::defer_for_received_outer;
import exm::refused_put_fallback;
import exm::no_raw_allocator_call;
import exm::embedding_the_inner;
import exm::type_crossing;
import exm::recovering_the_type;
import exm::walk_a_batch;
import exm::reach_into_a_full_slot;

fn void test_example_empty_slot() @test
{
    if (catch f = exm::empty_slot::acquire_into_an_empty_slot(mem)) always_assert(false, "empty_slot example failed");
}

fn void test_example_transfer_empties_slot() @test
{
    if (catch f = exm::transfer_empties_slot::demonstrate_transfer_empties_slot(mem)) always_assert(false, "transfer_empties_slot example failed");
}

fn void test_example_insert_from_slot() @test
{
    InnerQueue q;
    if (catch f = exm::insert_from_slot::insert_from_a_slot(mem, &q)) always_assert(false, "insert_from_slot example failed");
    while (Handle h = q.pop_front())
    {
        Slot s;
        s.fill(h);
        mtk::managed::release(exm::outers::Holder, &s);
    }
}

fn void test_example_null_safe_cleanup() @test
{
    if (catch f = exm::null_safe_cleanup::cleanup_survives_an_empty_slot(mem)) always_assert(false, "null_safe_cleanup example failed");
}

fn void test_example_defer_put_early() @test
{
    if (catch f = exm::defer_put_early::defer_put_goes_before_the_get(mem)) always_assert(false, "defer_put_early example failed");
}

fn void test_example_defer_release_early() @test
{
    if (catch f = exm::defer_release_early::defer_release_goes_before_the_create(mem)) always_assert(false, "defer_release_early example failed");
}

fn void test_example_defer_for_received_outer() @test
{
    if (catch f = exm::defer_for_received_outer::defer_covers_both_paths(mem)) always_assert(false, "defer_for_received_outer example failed");
}

fn void test_example_refused_put_fallback() @test
{
    if (catch f = exm::refused_put_fallback::fallback_releases_what_the_pool_refused(mem)) always_assert(false, "refused_put_fallback example failed");
}

fn void test_example_no_raw_allocator_call() @test
{
    if (catch f = exm::no_raw_allocator_call::never_a_raw_allocator_call(mem)) always_assert(false, "no_raw_allocator_call example failed");
}

fn void test_example_embedding_the_inner() @test
{
    if (catch f = exm::embedding_the_inner::embed_one_inner_anywhere(mem)) always_assert(false, "embedding_the_inner example failed");
}

fn void test_example_type_crossing() @test
{
    if (catch f = exm::type_crossing::cross_with_dollar_type(mem)) always_assert(false, "type_crossing example failed");
}

fn void test_example_recovering_the_type() @test
{
    if (catch f = exm::recovering_the_type::recover_four_ways(mem)) always_assert(false, "recovering_the_type example failed");
}

fn void test_example_walk_a_batch() @test
{
    if (catch f = exm::walk_a_batch::walk_a_received_batch(mem)) always_assert(false, "walk_a_batch example failed");
}

fn void test_example_reach_into_a_full_slot() @test
{
    Mailbox* mb = mtk::mailbox::create(mem)!!;
    defer { InnerQueue left; mb.close(&left); mb.release(); }
    if (catch f = exm::reach_into_a_full_slot::reach_in_then_send(mem, mb)) always_assert(false, "reach_into_a_full_slot example failed");
    Slot s;
    if (catch f = mb.receive(&s, time::ms(100))) return;
    mtk::managed::release(exm::outers::Holder, &s);
}
