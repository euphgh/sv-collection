`include "aa_value_adapter_array_util.svh"

// aa_value_adapter_array_util_tb test plan
// ----------------------------------------
// Scope:
// 1. Validate array-level cross-type containment across banks.
// 2. Validate bank-wise merge, intersection, difference adapter semantics.
// 3. Validate that *_into preserves pre-existing content in each touched bank.
// 4. Validate get_* and *_with return or mutate to the pure array-level result.
// 5. Validate bank-wise projection helpers between the two container shapes.
//
// Planned coverage:
// 1. contains
//    - accepts scalar values that appear in the queue view per bank
//    - rejects absent keys and absent values
// 2. merge family
//    - merge_into preserves pre-existing result content per bank
//    - get_merge returns a pure merged result
//    - merge_with mutates lhs in place
// 3. intersect family
//    - intersect_into preserves untouched result banks
//    - empty per-key intersections leave the existing result bank unchanged
//    - get_intersect returns the normalized intersection
//    - intersect_with mutates lhs in place
// 4. diff family
//    - diff_into preserves untouched result banks
//    - empty per-key differences leave the existing result bank unchanged
//    - get_diff returns the normalized difference
//    - diff_with mutates lhs in place
// 5. projections
//    - to_aa extracts singleton queues into scalar values per bank
//    - to_aa_of_q lifts scalar values into singleton queues per bank

module aa_value_adapter_array_util_tb;
    `include "tests_util.svh"

    typedef aa_value_adapter_array_util#(4, int unsigned, int unsigned) int_adapter_array_util_t;
    typedef int_adapter_array_util_t::aa_of_q_t int_aa_of_q_t;
    typedef int_adapter_array_util_t::aa_of_q_array_t int_aa_of_q_array_t;
    typedef int_adapter_array_util_t::aa_t int_aa_t;
    typedef int_adapter_array_util_t::aa_array_t int_aa_array_t;
    typedef set_util#(int unsigned) int_set_util_t;

    task automatic check_aa_of_q_equals(const ref int_aa_of_q_t actual,
                                        const ref int_aa_of_q_t expected,
                                        input string msg);
        check_true(int_adapter_array_util_t::elem_util::aa_of_q_util_t::equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
    endtask

    function automatic bit array_equals(const ref int_aa_of_q_array_t lhs,
                                        const ref int_aa_of_q_array_t rhs);
        foreach (lhs[i])
            if (!int_adapter_array_util_t::elem_util::aa_of_q_util_t::equals(lhs[i], rhs[i]))
                return 0;
        foreach (rhs[i])
            if (!lhs[i].num() && rhs[i].num())
                return 0;
        return 1;
    endfunction

    task automatic check_array_equals(const ref int_aa_of_q_array_t actual,
                                      const ref int_aa_of_q_array_t expected,
                                      input string msg);
        check_true(array_equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
    endtask

    task automatic test_contains();
        int_aa_of_q_array_t lhs;
        int_aa_array_t rhs;
        int_aa_array_t rhs_bad;

        lhs[0][1] = {10, 20};
        lhs[0][2] = {30};
        lhs[1][4] = {40};

        rhs[0][1] = 20;
        rhs[0][2] = 30;
        rhs[1][4] = 40;

        rhs_bad = rhs;
        rhs_bad[1][4] = 99;

        check_true(int_adapter_array_util_t::contains(lhs, rhs),
                   "contains should accept per-bank scalar values present in queue view",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));
        check_true(!int_adapter_array_util_t::contains(lhs, rhs_bad),
                   "contains should reject absent values in any bank",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs_bad));
    endtask

    task automatic test_merge_family();
        int_aa_of_q_array_t lhs;
        int_aa_array_t rhs;
        int_aa_of_q_array_t result;
        int_aa_of_q_array_t expected_into;
        int_aa_of_q_array_t expected_pure;
        int_aa_of_q_array_t merged;

        lhs[0][1] = {10, 20};
        lhs[1][2] = {30};
        rhs[0][2] = 40;
        rhs[1][3] = 50;
        result[2][99] = {999};

        expected_into[0][1] = {10, 20};
        expected_into[0][2] = {40};
        expected_into[1][2] = {30};
        expected_into[1][3] = {50};
        expected_into[2][99] = {999};

        expected_pure[0][1] = {10, 20};
        expected_pure[0][2] = {40};
        expected_pure[1][2] = {30};
        expected_pure[1][3] = {50};

        int_adapter_array_util_t::merge_into(lhs, rhs, result);
        check_array_equals(result, expected_into,
                           "merge_into should update touched banks and preserve unrelated content");

        merged = int_adapter_array_util_t::get_merge(lhs, rhs);
        check_array_equals(merged, expected_pure,
                           "get_merge should return the merged array");

        int_adapter_array_util_t::merge_with(lhs, rhs);
        check_array_equals(lhs, expected_pure,
                           "merge_with should update lhs to the merged array");
    endtask

    task automatic test_intersect_family();
        int_aa_of_q_array_t lhs;
        int_aa_array_t rhs;
        int_aa_of_q_array_t result;
        int_aa_of_q_array_t expected_into;
        int_aa_of_q_array_t expected_pure;
        int_aa_of_q_array_t intersected;

        lhs[0][1] = {10, 20};
        lhs[0][2] = {30};
        lhs[1][3] = {40};
        rhs[0][1] = 20;
        rhs[0][2] = 99;
        rhs[1][4] = 50;
        result[0][7] = {111};
        result[1][8] = {222};
        result[2][9] = {333};

        expected_into[0][1] = {20};
        expected_into[0][7] = {111};
        expected_into[1][8] = {222};
        expected_into[2][9] = {333};

        expected_pure[0][1] = {20};

        int_adapter_array_util_t::intersect_into(lhs, rhs, result);
        check_array_equals(result, expected_into,
                           "intersect_into should update only non-empty intersections and preserve unrelated content");

        intersected = int_adapter_array_util_t::get_intersect(lhs, rhs);
        check_array_equals(intersected, expected_pure,
                           "get_intersect should return the normalized intersection");

        int_adapter_array_util_t::intersect_with(lhs, rhs);
        check_array_equals(lhs, expected_pure,
                           "intersect_with should update lhs to the normalized intersection");
    endtask

    task automatic test_diff_family();
        int_aa_of_q_array_t lhs;
        int_aa_array_t rhs;
        int_aa_of_q_array_t result;
        int_aa_of_q_array_t expected_into;
        int_aa_of_q_array_t expected_pure;
        int_aa_of_q_array_t diffed;

        lhs[0][1] = {10, 20};
        lhs[0][2] = {30};
        lhs[1][3] = {40};
        rhs[0][1] = 20;
        rhs[1][3] = 40;
        result[0][7] = {111};
        result[1][8] = {222};
        result[2][9] = {333};

        expected_into[0][1] = {10};
        expected_into[0][2] = {30};
        expected_into[0][7] = {111};
        expected_into[1][8] = {222};
        expected_into[2][9] = {333};

        expected_pure[0][1] = {10};
        expected_pure[0][2] = {30};

        int_adapter_array_util_t::diff_into(lhs, rhs, result);
        check_array_equals(result, expected_into,
                           "diff_into should update only non-empty differences and preserve unrelated content");

        diffed = int_adapter_array_util_t::get_diff(lhs, rhs);
        check_array_equals(diffed, expected_pure,
                           "get_diff should return the normalized difference");

        int_adapter_array_util_t::diff_with(lhs, rhs);
        check_array_equals(lhs, expected_pure,
                           "diff_with should update lhs to the normalized difference");
    endtask

    task automatic test_projections();
        int_aa_of_q_array_t aa_of_q_arr;
        int_aa_array_t aa_arr;
        int_aa_array_t expected_aa;
        int_aa_of_q_array_t lifted;
        int_aa_t expected_bank;
        int_aa_t actual_bank;

        aa_of_q_arr[0][1] = {10};
        aa_of_q_arr[0][2] = {20};
        aa_of_q_arr[1][3] = {30};

        expected_aa[0][1] = 10;
        expected_aa[0][2] = 20;
        expected_aa[1][3] = 30;

        aa_arr = int_adapter_array_util_t::to_aa(aa_of_q_arr);

        expected_bank = expected_aa[0];
        actual_bank = aa_arr[0];
        check_true(int_adapter_array_util_t::elem_util::aa_util_t::equals(actual_bank, expected_bank),
                   "to_aa should extract singleton queue values per bank",
                   $sformatf("actual=%p expected=%p", aa_arr, expected_aa));

        lifted = int_adapter_array_util_t::to_aa_of_q(aa_arr);
        check_array_equals(lifted, aa_of_q_arr,
                           "to_aa_of_q should lift scalar values into singleton queues per bank");
    endtask

    initial begin
        test_contains();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_projections();

        $display("aa_value_adapter_array_util_tb: PASS");
        $finish;
    end
endmodule
