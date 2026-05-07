module set_array_util_tb;
    import collection::*;

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

        lhs[0][1] = 1'b1;
        lhs[1][10] = 1'b1;
        lhs[2][20] = 1'b1;

        rhs[0][2] = 1'b1;
        rhs[1][10] = 1'b1;
        same_as_lhs = lhs;
        rhs_subset[1][10] = 1'b1;
        rhs_subset[2][20] = 1'b1;

        check_true(int_set_array_util_t::equals(lhs, same_as_lhs), "equals should pass for elementwise identical arrays");
        check_true(!int_set_array_util_t::equals(lhs, rhs), "equals should fail when any bank differs");
        check_true(int_set_array_util_t::contains(lhs, rhs_subset), "contains should accept per-slot subsets");
        check_true(!int_set_array_util_t::contains(lhs, rhs), "contains should reject a differing slot value");
    endtask

    task automatic test_union_family();
        int_set_array_t lhs;
        int_set_array_t rhs;
        int_set_array_t result;
        int_set_array_t exact_union;

        lhs[0][1] = 1'b1;
        lhs[1][10] = 1'b1;
        rhs[0][2] = 1'b1;
        rhs[1][10] = 1'b1;
        rhs[2][20] = 1'b1;
        result[3][99] = 1'b1;

        int_set_array_util_t::union_into(lhs, rhs, result);
        check_true(result[0].exists(1) && result[0].exists(2), "union_into should merge bank 0 keys");
        check_true(result[1].exists(10), "union_into should keep shared bank key");
        check_true(result[2].exists(20), "union_into should add rhs-only bank key");
        check_true(result[3].exists(99), "union_into should preserve preexisting result content in untouched bank");

        exact_union = int_set_array_util_t::get_union(lhs, rhs);
        check_true(exact_union[0].size() == 2, "get_union should return pure bank union result");
        check_true(exact_union[2].exists(20), "get_union should include rhs-only bank content");

        int_set_array_util_t::union_with(lhs, rhs);
        check_true(lhs[0].exists(1) && lhs[0].exists(2), "union_with should mutate bank 0");
        check_true(lhs[2].exists(20), "union_with should append rhs-only bank content");
    endtask

    task automatic test_intersect_and_diff();
        int_set_array_t lhs;
        int_set_array_t rhs;
        int_set_array_t result;
        int_set_array_t exact_intersect;
        int_set_array_t exact_diff;

        lhs[0][1] = 1'b1;
        lhs[0][2] = 1'b1;
        lhs[1][10] = 1'b1;
        lhs[2][20] = 1'b1;

        rhs[0][2] = 1'b1;
        rhs[1][11] = 1'b1;
        rhs[2][20] = 1'b1;

        result[3][99] = 1'b1;

        int_set_array_util_t::intersect_into(lhs, rhs, result);
        check_true(result[0].exists(2), "intersect_into should keep shared key in bank 0");
        check_true(!result[1].exists(10), "intersect_into should not keep lhs-only bank entry");
        check_true(result[2].exists(20), "intersect_into should keep shared bank 2 key");
        check_true(result[3].exists(99), "intersect_into should preserve existing result content in untouched bank");

        exact_intersect = int_set_array_util_t::get_intersect(lhs, rhs);
        check_true(exact_intersect[0].size() == 1 && exact_intersect[0].exists(2), "get_intersect should return pure bank intersection");
        check_true(exact_intersect[1].size() == 0, "get_intersect should return empty set for non-overlapping bank");

        int_set_array_util_t::intersect_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0].exists(2), "intersect_with should mutate bank 0 to intersection");
        check_true(lhs[1].size() == 0, "intersect_with should clear non-overlapping bank");
        check_true(lhs[2].exists(20), "intersect_with should keep overlapping bank key");

        lhs[0].delete();
        lhs[1].delete();
        lhs[2].delete();
        lhs[0][1] = 1'b1;
        lhs[0][2] = 1'b1;
        lhs[1][10] = 1'b1;
        lhs[2][20] = 1'b1;

        int_set_array_util_t::diff_into(lhs, rhs, result);
        check_true(result[0].exists(1), "diff_into should add lhs-only key in bank 0");
        check_true(result[0].exists(2), "diff_into should preserve preexisting result content in bank 0");
        check_true(result[1].exists(10), "diff_into should keep lhs-only bank 1 key");
        check_true(result[2].exists(20), "diff_into should preserve preexisting result content in bank 2");
        check_true(result[3].exists(99), "diff_into should preserve unrelated preexisting result bank content");

        exact_diff = int_set_array_util_t::get_diff(lhs, rhs);
        check_true(exact_diff[0].size() == 1 && exact_diff[0].exists(1), "get_diff should return pure bank difference");
        check_true(exact_diff[1].exists(10), "get_diff should preserve lhs-only bank content");

        int_set_array_util_t::diff_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0].exists(1), "diff_with should mutate bank 0 to lhs-only keys");
        check_true(lhs[1].exists(10), "diff_with should preserve lhs-only bank 1 key");
        check_true(lhs[2].size() == 0, "diff_with should clear shared-only bank 2");
    endtask

    initial begin
        test_equals_and_contains();
        test_union_family();
        test_intersect_and_diff();

        $display("set_array_util_tb: PASS");
        $finish;
    end
endmodule
