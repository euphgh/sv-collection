`include "set_array_util.svh"

// set_array_util_tb test plan
// ---------------------------
// Scope:
// 1. Validate array-level equality and containment across slots.
// 2. Validate slot-wise union, intersection, and difference semantics.
// 3. Validate that *_into preserves pre-existing content in each result slot.
// 4. Validate get_* and *_with return or mutate to the pure array-level result.
// 5. Validate sprint / print render one array element per output line.
//
// Planned coverage:
// 1. equals / contains
//    - passes for slotwise identical arrays
//    - fails when any slot differs
//    - accepts slotwise subsets
// 2. union family
//    - union_into preserves pre-existing result content per slot
//    - get_union returns a pure union result
//    - union_with mutates lhs in place
// 3. intersect family
//    - intersect_into preserves untouched result slots
//    - get_intersect returns only shared slot content
//    - intersect_with mutates lhs in place
// 4. diff family
//    - diff_into preserves untouched result slots
//    - get_diff returns only lhs-only slot content
//    - diff_with mutates lhs in place
// 5. print helpers
//    - sprint formats one array element per line
//    - print emits the same row-based view

module set_array_util_tb;
    typedef set_array_util#(int unsigned, 4) int_set_array_util_t;
    typedef int_set_array_util_t::set_array_t int_set_array_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    task automatic test_equals_and_contains();
        int_set_array_t lhs;
        int_set_array_t rhs;
        int_set_array_t same_as_lhs;
        int_set_array_t rhs_subset;

        lhs[0] = '{1};
        lhs[1] = '{10};
        lhs[2] = '{20};

        rhs[0] = '{2};
        rhs[1] = '{10};
        same_as_lhs = lhs;
        rhs_subset[1] = '{10};
        rhs_subset[2] = '{20};

        check_true(int_set_array_util_t::equals(lhs, same_as_lhs),
                   $sformatf("equals should pass for elementwise identical arrays lhs=%p rhs=%p", lhs, same_as_lhs));
        check_true(!int_set_array_util_t::equals(lhs, rhs),
                   $sformatf("equals should fail when any bank differs lhs=%p rhs=%p", lhs, rhs));
        check_true(int_set_array_util_t::contains(lhs, rhs_subset),
                   $sformatf("contains should accept per-slot subsets lhs=%p rhs=%p", lhs, rhs_subset));
        check_true(!int_set_array_util_t::contains(lhs, rhs),
                   $sformatf("contains should reject a differing slot value lhs=%p rhs=%p", lhs, rhs));
    endtask

    task automatic test_union_family();
        int_set_array_t lhs;
        int_set_array_t rhs;
        int_set_array_t result;
        int_set_array_t exact_union;

        lhs[0] = '{1};
        lhs[1] = '{10};
        rhs[0] = '{2};
        rhs[1] = '{10};
        rhs[2] = '{20};
        result[3] = '{99};

        int_set_array_util_t::union_into(lhs, rhs, result);
        check_true(int_set_array_util_t::set_elem_util_t::count(result[0], 1) == 1 &&
                   int_set_array_util_t::set_elem_util_t::count(result[0], 2) == 1,
                   $sformatf("union_into should merge bank 0 keys result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[1], 10) == 1,
                   $sformatf("union_into should keep shared bank key result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[2], 20) == 1,
                   $sformatf("union_into should add rhs-only bank key result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[3], 99) == 1,
                   $sformatf("union_into should preserve preexisting result content in untouched bank result=%p", result));

        exact_union = int_set_array_util_t::get_union(lhs, rhs);
        check_true(exact_union[0].size() == 2,
                   $sformatf("get_union should return pure bank union result exact_union=%p", exact_union));
        check_true(int_set_array_util_t::set_elem_util_t::count(exact_union[2], 20) == 1,
                   $sformatf("get_union should include rhs-only bank content exact_union=%p", exact_union));

        int_set_array_util_t::union_with(lhs, rhs);
        check_true(int_set_array_util_t::set_elem_util_t::count(lhs[0], 1) == 1 &&
                   int_set_array_util_t::set_elem_util_t::count(lhs[0], 2) == 1,
                   $sformatf("union_with should mutate bank 0 lhs=%p", lhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(lhs[2], 20) == 1,
                   $sformatf("union_with should append rhs-only bank content lhs=%p", lhs));
    endtask

    task automatic test_intersect_and_diff();
        int_set_array_t lhs;
        int_set_array_t rhs;
        int_set_array_t result;
        int_set_array_t exact_intersect;
        int_set_array_t exact_diff;

        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[0], 1));
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[0], 2));
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[1], 10));
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[2], 20));

        void'(int_set_array_util_t::set_elem_util_t::insert(rhs[0], 2));
        void'(int_set_array_util_t::set_elem_util_t::insert(rhs[1], 11));
        void'(int_set_array_util_t::set_elem_util_t::insert(rhs[2], 20));

        void'(int_set_array_util_t::set_elem_util_t::insert(result[3], 99));

        int_set_array_util_t::intersect_into(lhs, rhs, result);
        check_true(int_set_array_util_t::set_elem_util_t::count(result[0], 2) == 1,
                   $sformatf("intersect_into should keep shared key in bank 0 result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[1], 10) == 0,
                   $sformatf("intersect_into should not keep lhs-only bank entry result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[2], 20) == 1,
                   $sformatf("intersect_into should keep shared bank 2 key result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[3], 99) == 1,
                   $sformatf("intersect_into should preserve existing result content in untouched bank result=%p", result));

        exact_intersect = int_set_array_util_t::get_intersect(lhs, rhs);
        check_true(exact_intersect[0].size() == 1 &&
                   int_set_array_util_t::set_elem_util_t::count(exact_intersect[0], 2) == 1,
                   $sformatf("get_intersect should return pure bank intersection exact_intersect=%p", exact_intersect));
        check_true(exact_intersect[1].size() == 0,
                   $sformatf("get_intersect should return empty set for non-overlapping bank exact_intersect=%p", exact_intersect));

        int_set_array_util_t::intersect_with(lhs, rhs);
        check_true(lhs[0].size() == 1 &&
                   int_set_array_util_t::set_elem_util_t::count(lhs[0], 2) == 1,
                   $sformatf("intersect_with should mutate bank 0 to intersection lhs=%p", lhs));
        check_true(lhs[1].size() == 0,
                   $sformatf("intersect_with should clear non-overlapping bank lhs=%p", lhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(lhs[2], 20) == 1,
                   $sformatf("intersect_with should keep overlapping bank key lhs=%p", lhs));

        lhs[0].delete();
        lhs[1].delete();
        lhs[2].delete();
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[0], 1));
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[0], 2));
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[1], 10));
        void'(int_set_array_util_t::set_elem_util_t::insert(lhs[2], 20));

        int_set_array_util_t::diff_into(lhs, rhs, result);
        check_true(int_set_array_util_t::set_elem_util_t::count(result[0], 1) == 1,
                   $sformatf("diff_into should add lhs-only key in bank 0 result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[0], 2) == 1,
                   $sformatf("diff_into should preserve preexisting result content in bank 0 result=%p", result));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[1], 10) == 1,
                   $sformatf("diff_into should keep lhs-only bank 1 key result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[2], 20) == 1,
                   $sformatf("diff_into should preserve preexisting result content in bank 2 result=%p", result));
        check_true(int_set_array_util_t::set_elem_util_t::count(result[3], 99) == 1,
                   $sformatf("diff_into should preserve unrelated preexisting result bank content result=%p", result));

        exact_diff = int_set_array_util_t::get_diff(lhs, rhs);
        check_true(exact_diff[0].size() == 1 &&
                   int_set_array_util_t::set_elem_util_t::count(exact_diff[0], 1) == 1,
                   $sformatf("get_diff should return pure bank difference exact_diff=%p", exact_diff));
        check_true(int_set_array_util_t::set_elem_util_t::count(exact_diff[1], 10) == 1,
                   $sformatf("get_diff should preserve lhs-only bank content exact_diff=%p", exact_diff));

        int_set_array_util_t::diff_with(lhs, rhs);
        check_true(lhs[0].size() == 1 &&
                   int_set_array_util_t::set_elem_util_t::count(lhs[0], 1) == 1,
                   $sformatf("diff_with should mutate bank 0 to lhs-only keys lhs=%p", lhs));
        check_true(int_set_array_util_t::set_elem_util_t::count(lhs[1], 10) == 1,
                   $sformatf("diff_with should preserve lhs-only bank 1 key lhs=%p", lhs));
        check_true(lhs[2].size() == 0,
                   $sformatf("diff_with should clear shared-only bank 2 lhs=%p", lhs));
    endtask

    task automatic test_print_demo();
        int_set_array_t a;

        void'(int_set_array_util_t::set_elem_util_t::insert(a[0], 1));
        void'(int_set_array_util_t::set_elem_util_t::insert(a[1], 10));
        void'(int_set_array_util_t::set_elem_util_t::insert(a[3], 30));

        $display("%s", int_set_array_util_t::sprint(a, "demo_array"));
        int_set_array_util_t::print(a, "demo_array");
    endtask

    initial begin
        test_equals_and_contains();
        test_union_family();
        test_intersect_and_diff();
        test_print_demo();

        $display("set_array_util_tb: PASS");
        $finish;
    end
endmodule
