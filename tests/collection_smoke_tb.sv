`timescale 1ns / 1ps

`include "aa_util.svh"

module collection_smoke_tb;
    typedef set_util#(int unsigned) int_set_util_t;
    typedef int_set_util_t::set_t int_set_t;

    typedef aa_util#(int unsigned, int unsigned) int_aa_util_t;
    typedef int_aa_util_t::aa_t int_aa_t;
    typedef int_aa_util_t::key_set_t int_key_set_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("EXPECT FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    initial begin
        int_set_t lhs_set;
        int_set_t rhs_set;
        int_set_t union_set;
        int_set_t exact_union_set;
        int_set_t intersect_set;
        int_set_t diff_set;

        int_aa_t lhs_aa;
        int_aa_t rhs_aa;
        int_aa_t merged_aa;
        int_aa_t intersect_aa;
        int_aa_t diff_aa;
        int_aa_t overwritten_aa;
        int_key_set_t required_keys;

        int_set_util_t::insert(lhs_set, 1);
        int_set_util_t::insert(lhs_set, 2);
        int_set_util_t::insert(rhs_set, 2);
        int_set_util_t::insert(rhs_set, 3);
        int_set_util_t::insert(union_set, 99);

        check_true(int_set_util_t::contains_key(lhs_set, 1), "lhs_set should contain key 1");
        check_true(!int_set_util_t::contains_key(lhs_set, 3), "lhs_set should not contain key 3");
        check_true(!int_set_util_t::contains_set(lhs_set, rhs_set), "lhs_set should not contain rhs_set");

        int_set_util_t::union_into(lhs_set, rhs_set, union_set);
        check_true(union_set.exists(1), "union_into should add lhs key 1");
        check_true(union_set.exists(2), "union_into should add shared key 2");
        check_true(union_set.exists(3), "union_into should add rhs key 3");
        check_true(union_set.exists(99), "union_into should preserve existing result content");

        exact_union_set = int_set_util_t::get_union(lhs_set, rhs_set);
        check_true(exact_union_set.size() == 3, "get_union should return only union keys");

        intersect_set = int_set_util_t::get_intersect(lhs_set, rhs_set);
        check_true(intersect_set.size() == 1 && intersect_set.exists(2), "get_intersect should keep only shared key 2");

        diff_set = int_set_util_t::get_diff(lhs_set, rhs_set);
        check_true(diff_set.size() == 1 && diff_set.exists(1), "get_diff should keep only lhs-only key 1");

        lhs_aa[1] = 10;
        lhs_aa[2] = 20;
        rhs_aa[2] = 99;
        rhs_aa[3] = 30;

        merged_aa = int_aa_util_t::get_merge(lhs_aa, rhs_aa);
        check_true(merged_aa.size() == 3, "get_merge should produce three entries");
        check_true(merged_aa[1] == 10, "get_merge should keep lhs-only entry");
        check_true(merged_aa[2] == 99, "get_merge should let rhs overwrite shared key");
        check_true(merged_aa[3] == 30, "get_merge should include rhs-only entry");

        required_keys[1] = 1'b1;
        required_keys[3] = 1'b1;
        check_true(int_aa_util_t::contains_keys(merged_aa, required_keys), "merged aa should contain required keys");
        check_true(int_aa_util_t::contains(merged_aa, rhs_aa), "merged aa should contain rhs as sub-map");

        intersect_aa = int_aa_util_t::get_intersect(lhs_aa, rhs_aa);
        check_true(intersect_aa.size() == 1, "get_intersect should return one shared key");
        check_true(intersect_aa[2] == 20, "get_intersect should preserve lhs value on shared key");

        diff_aa = int_aa_util_t::get_diff(lhs_aa, rhs_aa);
        check_true(diff_aa.size() == 1, "get_diff should return one lhs-only key");
        check_true(diff_aa[1] == 10, "get_diff should preserve lhs-only value");

        overwritten_aa = int_aa_util_t::get_intersect_merge_with(lhs_aa, rhs_aa);
        check_true(overwritten_aa.size() == 1, "get_intersect_merge_with should report overwritten entries");
        check_true(overwritten_aa[2] == 20, "overwritten entry should preserve old lhs value");
        check_true(lhs_aa[2] == 99, "get_intersect_merge_with should update lhs in place");
        check_true(lhs_aa[3] == 30, "get_intersect_merge_with should add rhs-only key to lhs");

        $display("collection_smoke_tb: PASS");
        $finish;
    end
endmodule
