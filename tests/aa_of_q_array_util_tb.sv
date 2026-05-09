`include "aa_of_q_array_util.svh"

// aa_of_q_array_util_tb test plan
// -------------------------------
// Scope:
// 1. Validate array-level equality and containment across banks.
// 2. Validate bank-wise merge, intersection, difference, and clean semantics.
// 3. Validate that *_into preserves pre-existing content in each touched bank.
// 4. Validate get_* and *_with return or mutate to the pure array-level result.
// 5. Validate bank-wise key and value set projection helpers.
// 6. Validate sprint / print render one array element per output line.
//
// Planned coverage:
// 1. equals / contains
//    - passes for bankwise identical arrays
//    - fails when any bank differs
//    - accepts bankwise subsets
// 2. clean
//    - removes empty-queue keys in each bank
//    - preserves non-empty keys and values
//    - leaves already-normalized banks unchanged
// 3. merge family
//    - merge_into preserves pre-existing result content per bank
//    - get_merge returns a pure merged result
//    - merge_with mutates lhs in place
// 4. intersect family
//    - intersect_into preserves untouched result banks
//    - empty per-key intersections leave the existing result bank unchanged
//    - get_intersect returns only shared bank content
//    - intersect_with mutates lhs in place
// 5. diff family
//    - diff_into preserves untouched result banks
//    - empty per-key differences leave the existing result bank unchanged
//    - get_diff returns only lhs-only bank content
//    - diff_with mutates lhs in place
// 6. projections
//    - get_key_sets returns the visible keys of each bank
//    - get_value_sets returns the flattened visible values of each bank
// 7. print helpers
//    - sprint formats one array element per line
//    - print emits the same row-based view

module aa_of_q_array_util_tb;
    `include "tests_util.svh"

    typedef aa_of_q_array_util#(4, int unsigned, int unsigned) int_aa_of_q_array_util_t;
    typedef int_aa_of_q_array_util_t::aa_of_q_array_t int_aa_of_q_array_t;
    typedef int_aa_of_q_array_util_t::aa_of_q_t int_aa_of_q_t;
    typedef int_aa_of_q_array_util_t::key_set_t int_key_set_t;
    typedef int_aa_of_q_array_util_t::key_set_array_t int_key_set_array_t;
    typedef int_aa_of_q_array_util_t::val_set_t int_val_set_t;
    typedef int_aa_of_q_array_util_t::val_set_array_t int_val_set_array_t;

    task automatic check_aa_equals(const ref int_aa_of_q_t actual,
                                   const ref int_aa_of_q_t expected,
                                   input string msg);
        check_true(int_aa_of_q_array_util_t::elem_util::equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
    endtask

    task automatic check_array_equals(const ref int_aa_of_q_array_t actual,
                                      const ref int_aa_of_q_array_t expected,
                                      input string msg);
        check_true(int_aa_of_q_array_util_t::equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
    endtask

    task automatic test_equals_and_contains();
        int_aa_of_q_array_t lhs;
        int_aa_of_q_array_t rhs;
        int_aa_of_q_array_t same_as_lhs;
        int_aa_of_q_array_t rhs_subset;

        lhs[0][1] = {10, 20};
        lhs[1][4] = {40};

        rhs[0][1] = {10, 21};
        rhs[1][4] = {40};
        same_as_lhs = lhs;

        rhs_subset[0][1] = {10};
        rhs_subset[1][4] = {40};

        check_true(int_aa_of_q_array_util_t::equals(lhs, same_as_lhs),
                   "equals should pass for bankwise identical arrays",
                   $sformatf("lhs=%p rhs=%p", lhs, same_as_lhs));
        check_true(!int_aa_of_q_array_util_t::equals(lhs, rhs),
                   "equals should fail when any bank differs",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));
        check_true(int_aa_of_q_array_util_t::contains(lhs, rhs_subset),
                   "contains should accept bankwise subsets",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs_subset));
        check_true(!int_aa_of_q_array_util_t::contains(lhs, rhs),
                   "contains should reject a differing bank value",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));
    endtask

    task automatic test_clean();
        int_aa_of_q_array_t dirty;
        int_aa_of_q_array_t expected;
        int_aa_of_q_array_t already_clean;

        dirty[0][1] = {};
        dirty[0][2] = {20, 21};
        dirty[1][3] = {};
        dirty[1][4] = {40};

        expected[0][2] = {20, 21};
        expected[1][4] = {40};

        int_aa_of_q_array_util_t::clean(dirty);
        check_array_equals(dirty, expected,
                           "clean should remove empty-queue keys from every bank");

        already_clean = expected;
        int_aa_of_q_array_util_t::clean(already_clean);
        check_array_equals(already_clean, expected,
                           "clean should leave normalized banks unchanged");
    endtask

    task automatic test_merge_family();
        int_aa_of_q_array_t lhs;
        int_aa_of_q_array_t rhs;
        int_aa_of_q_array_t result;
        int_aa_of_q_array_t expected_into;
        int_aa_of_q_array_t expected_pure;
        int_aa_of_q_array_t merged;

        lhs[0][1] = {10};
        lhs[1][2] = {20, 21};
        rhs[1][2] = {21, 22};
        rhs[2][3] = {30};
        result[3][99] = {999};

        expected_into[0][1] = {10};
        expected_into[1][2] = {20, 21, 22};
        expected_into[2][3] = {30};
        expected_into[3][99] = {999};

        expected_pure[0][1] = {10};
        expected_pure[1][2] = {20, 21, 22};
        expected_pure[2][3] = {30};

        int_aa_of_q_array_util_t::merge_into(lhs, rhs, result);
        check_array_equals(result, expected_into,
                           "merge_into should update touched banks and preserve unrelated content");

        merged = int_aa_of_q_array_util_t::get_merge(lhs, rhs);
        check_array_equals(merged, expected_pure,
                           "get_merge should return the merged array");

        int_aa_of_q_array_util_t::merge_with(lhs, rhs);
        check_array_equals(lhs, expected_pure,
                           "merge_with should update lhs to the merged array");
    endtask

    task automatic test_intersect_family();
        int_aa_of_q_array_t lhs;
        int_aa_of_q_array_t rhs;
        int_aa_of_q_array_t result;
        int_aa_of_q_array_t expected_into;
        int_aa_of_q_array_t expected_pure;
        int_aa_of_q_array_t intersected;

        lhs[0][1] = {10};
        lhs[1][2] = {20, 21};
        lhs[2][3] = {30};
        rhs[1][2] = {21, 22};
        rhs[2][3] = {31};
        rhs[3][4] = {40};
        result[0][7] = {111};
        result[1][8] = {222};
        result[2][9] = {333};
        result[3][10] = {444};

        expected_into[0][7] = {111};
        expected_into[1][2] = {21};
        expected_into[1][8] = {222};
        expected_into[2][9] = {333};
        expected_into[3][10] = {444};

        expected_pure[1][2] = {21};

        int_aa_of_q_array_util_t::intersect_into(lhs, rhs, result);
        check_array_equals(result, expected_into,
                           "intersect_into should update non-empty shared-bank intersections and preserve empty ones");

        intersected = int_aa_of_q_array_util_t::get_intersect(lhs, rhs);
        check_array_equals(intersected, expected_pure,
                           "get_intersect should return the normalized intersection");

        int_aa_of_q_array_util_t::intersect_with(lhs, rhs);
        check_array_equals(lhs, expected_pure,
                           "intersect_with should update lhs to the normalized intersection");
    endtask

    task automatic test_diff_family();
        int_aa_of_q_array_t lhs;
        int_aa_of_q_array_t rhs;
        int_aa_of_q_array_t result;
        int_aa_of_q_array_t expected_into;
        int_aa_of_q_array_t expected_pure;
        int_aa_of_q_array_t diffed;

        lhs[0][1] = {10};
        lhs[1][2] = {20, 21};
        lhs[2][3] = {30};
        rhs[1][2] = {21};
        rhs[2][3] = {30};
        rhs[3][4] = {40};
        result[0][7] = {111};
        result[1][8] = {222};
        result[2][9] = {333};
        result[3][10] = {444};

        expected_into[0][1] = {10};
        expected_into[0][7] = {111};
        expected_into[0][7] = {111};
        expected_into[1][2] = {20};
        expected_into[1][8] = {222};
        expected_into[2][9] = {333};
        expected_into[3][10] = {444};

        expected_pure[0][1] = {10};
        expected_pure[1][2] = {20};

        int_aa_of_q_array_util_t::diff_into(lhs, rhs, result);
        check_array_equals(result, expected_into,
                           "diff_into should update only non-empty bank differences");

        diffed = int_aa_of_q_array_util_t::get_diff(lhs, rhs);
        check_array_equals(diffed, expected_pure,
                           "get_diff should return the normalized difference");

        int_aa_of_q_array_util_t::diff_with(lhs, rhs);
        check_array_equals(lhs, expected_pure,
                           "diff_with should update lhs to the normalized difference");
    endtask

    task automatic test_projections_and_print();
        int_aa_of_q_array_t a;
        int_key_set_array_t key_sets;
        int_val_set_array_t value_sets;
        int_key_set_t expected_keys_0;
        int_key_set_t expected_keys_1;
        int_val_set_t expected_values_0;
        int_val_set_t expected_values_1;

        a[0][1] = {10, 20};
        a[0][2] = {30};
        a[1][4] = {40, 41};

        expected_keys_0 = '{1, 2};
        expected_keys_1 = '{4};
        expected_values_0 = '{10, 20, 30};
        expected_values_1 = '{40, 41};

        key_sets = int_aa_of_q_array_util_t::get_key_sets(a);
        value_sets = int_aa_of_q_array_util_t::get_value_sets(a);

        check_true(int_aa_of_q_array_util_t::elem_util::key_set_util::equals(key_sets[0], expected_keys_0),
                   "get_key_sets should return the visible keys of bank 0",
                   $sformatf("key_sets=%p", key_sets));
        check_true(int_aa_of_q_array_util_t::elem_util::key_set_util::equals(key_sets[1], expected_keys_1),
                   "get_key_sets should return the visible keys of bank 1",
                   $sformatf("key_sets=%p", key_sets));
        check_true(int_aa_of_q_array_util_t::elem_util::val_set_util::equals(value_sets[0], expected_values_0),
                   "get_value_sets should flatten visible values of bank 0",
                   $sformatf("value_sets=%p", value_sets));
        check_true(int_aa_of_q_array_util_t::elem_util::val_set_util::equals(value_sets[1], expected_values_1),
                   "get_value_sets should flatten visible values of bank 1",
                   $sformatf("value_sets=%p", value_sets));

        $display("%s", int_aa_of_q_array_util_t::sprint(a, "demo_array"));
        int_aa_of_q_array_util_t::print(a, "demo_array");
    endtask

    initial begin
        test_equals_and_contains();
        test_clean();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_projections_and_print();

        $display("aa_of_q_array_util_tb: PASS");
        $finish;
    end
endmodule
