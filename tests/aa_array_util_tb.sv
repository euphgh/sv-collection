module aa_array_util_tb;
    import collection::*;

    typedef aa_array_util#(4, int unsigned, int unsigned) int_aa_array_util_t;
    typedef int_aa_array_util_t::aa_t int_aa_t;
    typedef int_aa_array_util_t::aa_array_t int_aa_array_t;
    typedef int_aa_array_util_t::key_set_t int_key_set_t;
    typedef int_aa_array_util_t::key_set_array_t int_key_set_array_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    task automatic test_bank_contains_helpers();
        int_aa_array_t banks;
        int_aa_t subset;
        int_key_set_t keys;
        int_aa_array_t rhs_array;

        banks[0][1] = 10;
        banks[0][2] = 20;
        banks[1][7] = 70;

        subset[1] = 10;
        keys[1] = 1'b1;
        keys[2] = 1'b1;
        rhs_array[0][1] = 10;
        rhs_array[1][2] = 20;

        check_true(int_aa_array_util_t::contains_key(banks, 0, 1), "contains_key should find existing key in selected bank");
        check_true(!int_aa_array_util_t::contains_key(banks, 0, 9), "contains_key should reject absent key in selected bank");
        check_true(int_aa_array_util_t::contains(banks, 0, subset), "contains should accept sub-map for selected bank");
        check_true(int_aa_array_util_t::contains_keys(banks, 0, keys), "contains_keys should accept selected bank key subset");
        check_true(int_aa_array_util_t::contains_aa_array(banks, 0, rhs_array), "contains_aa_array should require selected bank to contain all rhs banks as sub-maps");
    endtask

    task automatic test_equals_and_merge_family();
        int_aa_array_t lhs;
        int_aa_array_t rhs;
        int_aa_array_t same_as_lhs;
        int_aa_array_t result;
        int_aa_array_t exact_merge;
        int_aa_array_t overwritten;

        lhs[0][1] = 10;
        lhs[0][2] = 20;
        lhs[1][7] = 70;

        rhs[0][2] = 99;
        rhs[0][3] = 30;
        rhs[2][8] = 80;

        same_as_lhs = lhs;
        result[3][99] = 999;

        check_true(int_aa_array_util_t::equals(lhs, same_as_lhs), "equals should pass for elementwise equal aa-array");
        check_true(!int_aa_array_util_t::equals(lhs, rhs), "equals should fail when any bank differs");

        int_aa_array_util_t::merge_into(lhs, rhs, result);
        check_true(result[0].size() == 3, "merge_into should overwrite bank 0 with merged map");
        check_true(result[0][2] == 99 && result[0][3] == 30, "merge_into should apply aa merge semantics per bank");
        check_true(result[2][8] == 80, "merge_into should include rhs-only bank content");
        check_true(!result[3].exists(99), "merge_into should overwrite stale result bank content");

        exact_merge = int_aa_array_util_t::get_merge(lhs, rhs);
        check_true(exact_merge[0].size() == 3 && exact_merge[0][2] == 99, "get_merge should return pure per-bank merge result");

        overwritten = int_aa_array_util_t::get_intersect_merge_with(lhs, rhs);
        check_true(overwritten[0].size() == 1 && overwritten[0][2] == 20, "get_intersect_merge_with should report overwritten entries per bank");
        check_true(lhs[0][2] == 99 && lhs[0][3] == 30, "get_intersect_merge_with should update lhs per bank");
        check_true(lhs[2][8] == 80, "get_intersect_merge_with should add rhs-only bank content");
    endtask

    task automatic test_intersect_and_diff_family();
        int_aa_array_t lhs;
        int_aa_array_t rhs;
        int_aa_array_t result;
        int_aa_array_t exact_intersect;
        int_aa_array_t exact_diff;

        lhs[0][1] = 10;
        lhs[0][2] = 20;
        lhs[1][7] = 70;
        lhs[2][8] = 80;

        rhs[0][2] = 200;
        rhs[1][9] = 90;
        rhs[2][8] = 800;

        result[3][99] = 999;

        int_aa_array_util_t::intersect_into(lhs, rhs, result);
        check_true(result[0].size() == 1 && result[0][2] == 20, "intersect_into should keep lhs payload for shared key in bank 0");
        check_true(result[1].size() == 0, "intersect_into should clear non-overlapping bank");
        check_true(result[2].size() == 1 && result[2][8] == 80, "intersect_into should preserve lhs payload for shared bank 2 key");
        check_true(!result[3].exists(99), "intersect_into should overwrite stale result bank content");

        exact_intersect = int_aa_array_util_t::get_intersect(lhs, rhs);
        check_true(exact_intersect[0].size() == 1 && exact_intersect[0][2] == 20, "get_intersect should return pure per-bank intersection");

        int_aa_array_util_t::intersect_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0][2] == 20, "intersect_with should mutate bank 0 to intersection result");
        check_true(lhs[1].size() == 0, "intersect_with should clear non-overlapping bank 1");
        check_true(lhs[2].size() == 1 && lhs[2][8] == 80, "intersect_with should keep shared bank 2 key");

        lhs[0].delete();
        lhs[1].delete();
        lhs[2].delete();
        lhs[0][1] = 10;
        lhs[0][2] = 20;
        lhs[1][7] = 70;
        lhs[2][8] = 80;

        int_aa_array_util_t::diff_into(lhs, rhs, result);
        check_true(result[0].size() == 1 && result[0][1] == 10, "diff_into should keep lhs-only key in bank 0");
        check_true(result[1].size() == 1 && result[1][7] == 70, "diff_into should keep lhs-only bank 1 content");
        check_true(result[2].size() == 0, "diff_into should remove shared-only bank 2 content");
        check_true(!result[3].exists(99), "diff_into should overwrite stale result bank content");

        exact_diff = int_aa_array_util_t::get_diff(lhs, rhs);
        check_true(exact_diff[0].size() == 1 && exact_diff[0][1] == 10, "get_diff should return pure per-bank difference");

        int_aa_array_util_t::diff_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0][1] == 10, "diff_with should mutate bank 0 to lhs-only entries");
        check_true(lhs[1].size() == 1 && lhs[1][7] == 70, "diff_with should preserve lhs-only bank 1");
        check_true(lhs[2].size() == 0, "diff_with should clear shared-only bank 2");
    endtask

    task automatic test_key_projection_helpers();
        int_aa_array_t banks;
        int_key_set_t keys;
        int_key_set_array_t key_sets;

        banks[0][1] = 10;
        banks[0][2] = 20;
        banks[2][8] = 80;

        keys = int_aa_array_util_t::get_keys(banks, 0);
        check_true(keys.size() == 2 && keys.exists(1) && keys.exists(2), "get_keys should return selected bank key set");

        key_sets = int_aa_array_util_t::get_key_sets(banks);
        check_true(key_sets[0].size() == 2 && key_sets[0].exists(1) && key_sets[0].exists(2), "get_key_sets should return bank 0 key set");
        check_true(key_sets[2].size() == 1 && key_sets[2].exists(8), "get_key_sets should return bank 2 key set");
        check_true(key_sets[1].size() == 0, "get_key_sets should return empty set for empty bank");
    endtask

    initial begin
        test_bank_contains_helpers();
        test_equals_and_merge_family();
        test_intersect_and_diff_family();
        test_key_projection_helpers();

        $display("aa_array_util_tb: PASS");
        $finish;
    end
endmodule
