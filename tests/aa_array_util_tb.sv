`include "aa_array_util.svh"

// aa_array_util_tb test plan
// --------------------------
// Scope:
// 1. Validate elementwise equality and containment across array banks.
// 2. Validate bank-wise merge, intersection, and difference semantics.
// 3. Validate that *_into preserves pre-existing content in each result bank.
// 4. Validate bank-local key projection helpers.
// 5. Validate sprint / print render one bank per output line.
//
// Planned coverage:
// 1. equals / contains
//    - passes for bankwise identical arrays
//    - fails when any bank differs
//    - accepts bankwise subsets
// 2. merge family
//    - merge_into updates touched banks
//    - merge_into preserves unrelated result banks
//    - get_merge returns a pure merged array
//    - merge_with mutates lhs in place
// 3. intersect family
//    - intersect_into keeps only shared banks
//    - intersect_into preserves unrelated result banks
//    - get_intersect returns only shared bank content
//    - intersect_with mutates lhs in place
// 4. diff family
//    - diff_into keeps lhs-only banks
//    - diff_into preserves unrelated result banks
//    - get_diff returns only lhs-only bank content
//    - diff_with mutates lhs in place
// 5. projections
//    - get_keys returns the key sets for all banks
// 6. print helpers
//    - sprint formats one array element per line
//    - print emits the same row-based view

module aa_array_util_tb;
    `include "tests_util.svh"

    typedef aa_array_util#(4, int unsigned, int unsigned) int_aa_array_util_t;
    typedef int_aa_array_util_t::aa_array_t int_aa_array_t;
    typedef int unsigned key_q_t[$];
    typedef int_aa_array_util_t::key_set_array_t int_key_set_array_t;

    function automatic bit aa_equals(const ref int_aa_array_t lhs,
                                     const ref int_aa_array_t rhs);
        foreach (lhs[i]) begin
            if (!int_aa_array_util_t::elem_util::equals(lhs[i], rhs[i]))
                return 0;
        end

        return 1;
    endfunction

    function automatic bit key_set_contains(const ref key_q_t keys,
                                            input int unsigned key);
        foreach (keys[i]) begin
            if (keys[i] == key)
                return 1;
        end

        return 0;
    endfunction

    task automatic check_aa_equals(const ref int_aa_array_t actual,
                                   const ref int_aa_array_t expected,
                                   input string msg);
        check_true(aa_equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
    endtask

    task automatic test_equals_and_contains();
        int_aa_array_t lhs;
        int_aa_array_t rhs;
        int_aa_array_t same_as_lhs;
        int_aa_array_t rhs_subset;

        lhs[0][1] = 10;
        lhs[0][2] = 20;
        lhs[1][7] = 70;

        rhs[0][1] = 11;
        rhs[1][7] = 70;
        same_as_lhs = lhs;
        rhs_subset[1][7] = 70;

        check_true(int_aa_array_util_t::equals(lhs, same_as_lhs),
                   "equals should pass for bankwise identical arrays",
                   $sformatf("lhs=%p rhs=%p", lhs, same_as_lhs));
        check_true(!int_aa_array_util_t::equals(lhs, rhs),
                   "equals should fail when any bank differs",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));
        check_true(int_aa_array_util_t::contains(lhs, rhs_subset),
                   "contains should accept bankwise subsets",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs_subset));
        check_true(!int_aa_array_util_t::contains(lhs, rhs),
                   "contains should reject a differing bank value",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));
    endtask

    task automatic test_merge_family();
        int_aa_array_t lhs;
        int_aa_array_t rhs;
        int_aa_array_t result;
        int_aa_array_t exact_merge;

        lhs[0][1] = 10;
        lhs[1][7] = 70;
        rhs[0][2] = 20;
        rhs[1][7] = 71;
        rhs[2][8] = 80;
        result[3][99] = 999;

        int_aa_array_util_t::merge_into(lhs, rhs, result);
        check_true(result[0].size() == 2 && result[0][1] == 10 && result[0][2] == 20,
                   "merge_into should merge bank 0 keys",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[1].size() == 1 && result[1][7] == 71,
                   "merge_into should apply rhs values to shared banks",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[2].size() == 1 && result[2][8] == 80,
                   "merge_into should include rhs-only bank content",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[3].size() == 1 && result[3][99] == 999,
                   "merge_into should preserve unrelated pre-existing result content",
                   $sformatf("result=%p", result));

        exact_merge = int_aa_array_util_t::get_merge(lhs, rhs);
        check_true(exact_merge[0].size() == 2 && exact_merge[0][2] == 20,
                   "get_merge should return a pure merged array",
                   $sformatf("exact_merge=%p", exact_merge));

        int_aa_array_util_t::merge_with(lhs, rhs);
        check_true(lhs[0].size() == 2 && lhs[0][2] == 20,
                   "merge_with should mutate lhs in place",
                   $sformatf("lhs=%p", lhs));
        check_true(lhs[1].size() == 1 && lhs[1][7] == 71,
                   "merge_with should update shared banks",
                   $sformatf("lhs=%p", lhs));
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
        check_true(result[0].size() == 1 && result[0][2] == 20,
                   "intersect_into should keep only shared bank content",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[1].size() == 0,
                   "intersect_into should clear non-overlapping bank entries",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[2].size() == 1 && result[2][8] == 80,
                   "intersect_into should preserve lhs payload on shared keys",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[3].size() == 1 && result[3][99] == 999,
                   "intersect_into should preserve unrelated pre-existing result content",
                   $sformatf("result=%p", result));

        exact_intersect = int_aa_array_util_t::get_intersect(lhs, rhs);
        check_true(exact_intersect[0].size() == 1 && exact_intersect[0][2] == 20,
                   "get_intersect should return only shared bank content",
                   $sformatf("exact_intersect=%p", exact_intersect));

        int_aa_array_util_t::intersect_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0][2] == 20,
                   "intersect_with should mutate lhs in place",
                   $sformatf("lhs=%p", lhs));
        check_true(lhs[1].size() == 0,
                   "intersect_with should clear non-overlapping bank 1",
                   $sformatf("lhs=%p", lhs));

        lhs[0].delete();
        lhs[1].delete();
        lhs[2].delete();
        lhs[0][1] = 10;
        lhs[0][2] = 20;
        lhs[1][7] = 70;
        lhs[2][8] = 80;

        result[0].delete();
        result[1].delete();
        result[2].delete();
        result[3].delete();
        int_aa_array_util_t::diff_into(lhs, rhs, result);
        check_true(result[0].size() == 1 && result[0][1] == 10,
                   "diff_into should keep lhs-only bank 0 content",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[1].size() == 1 && result[1][7] == 70,
                   "diff_into should keep lhs-only bank 1 content",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));
        check_true(result[2].size() == 0,
                   "diff_into should remove shared-only bank 2 content",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));

        exact_diff = int_aa_array_util_t::get_diff(lhs, rhs);
        check_true(exact_diff[0].size() == 1 && exact_diff[0][1] == 10,
                   "get_diff should return only lhs-only bank content",
                   $sformatf("exact_diff=%p", exact_diff));

        int_aa_array_util_t::diff_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0][1] == 10,
                   "diff_with should mutate lhs in place",
                   $sformatf("lhs=%p", lhs));
        check_true(lhs[2].size() == 0,
                   "diff_with should clear shared-only bank 2",
                   $sformatf("lhs=%p", lhs));
    endtask

    task automatic test_projection_and_print();
        int_aa_array_t banks;
        int_key_set_array_t key_sets;

        banks[0][1] = 10;
        banks[0][2] = 20;
        banks[2][8] = 80;

        key_sets = int_aa_array_util_t::get_keys(banks);
        check_true(key_sets[0].size() == 2 &&
                   key_set_contains(key_sets[0], 1) &&
                   key_set_contains(key_sets[0], 2),
                   "get_keys should return bank 0 key set",
                   $sformatf("key_sets=%p", key_sets));
        check_true(key_sets[2].size() == 1 &&
                   key_set_contains(key_sets[2], 8),
                   "get_keys should return bank 2 key set",
                   $sformatf("key_sets=%p", key_sets));
        check_true(key_sets[1].size() == 0,
                   "get_keys should return empty set for empty bank",
                   $sformatf("key_sets=%p", key_sets));

        $display("%s", int_aa_array_util_t::sprint(banks, "demo_array"));
        int_aa_array_util_t::print(banks, "demo_array");
    endtask

    initial begin
        test_equals_and_contains();
        test_merge_family();
        test_intersect_and_diff_family();
        test_projection_and_print();

        $display("aa_array_util_tb: PASS");
        $finish;
    end
endmodule
