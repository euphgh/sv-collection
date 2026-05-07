`include "aa_value_adapter_util.svh"

// aa_value_adapter_util_tb test plan
// ---------------------------------
// Scope:
// 1. Validate cross-type containment between aa_of_q_t and aa_t.
// 2. Validate merge / intersect / diff adapter behavior.
// 3. Validate scalar projection and lifting helpers.
// 4. Validate normalized overwrite behavior for *_into and *_with APIs.
//
// Planned coverage:
// 1. contains
//    - accepts scalar values that appear in the queue view
//    - rejects absent keys and absent values
// 2. merge family
//    - inserts scalar values into queue view
//    - preserves existing queue values
//    - overwrites stale result content for *_into
// 3. intersect family
//    - keeps only shared keys whose scalar values are present in the queue
//    - drops keys whose value is absent in the queue
// 4. diff family
//    - removes one matching occurrence per shared key
//    - drops keys whose queues become empty
// 5. projections
//    - to_aa extracts singleton queues into scalar values
//    - to_aa_of_q lifts scalar values into singleton queues

module aa_value_adapter_util_tb;
    `include "tests_util.svh"

    typedef aa_value_adapter_util#(int unsigned, int unsigned) int_value_adapter_util_t;
    typedef int_value_adapter_util_t::aa_t int_aa_t;
    typedef int_value_adapter_util_t::aa_of_q_t int_aa_of_q_t;
    typedef set_util#(int unsigned) int_set_util_t;

    function automatic bit queue_equals(const ref int_value_adapter_util_t::val_q_t lhs,
                                        const ref int_value_adapter_util_t::val_q_t rhs);
        return int_set_util_t::equals(lhs, rhs);
    endfunction

    function automatic bit aa_of_q_equals(const ref int_aa_of_q_t lhs,
                                          const ref int_aa_of_q_t rhs);
        if (lhs.num() != rhs.num())
            return 0;

        foreach (lhs[key]) begin
            if (!rhs.exists(key))
                return 0;
            if (!queue_equals(lhs[key], rhs[key]))
                return 0;
        end

        return 1;
    endfunction

    function automatic bit aa_equals(const ref int_aa_t lhs,
                                     const ref int_aa_t rhs);
        if (lhs.num() != rhs.num())
            return 0;

        foreach (lhs[key]) begin
            if (!rhs.exists(key))
                return 0;
            if (lhs[key] != rhs[key])
                return 0;
        end

        return 1;
    endfunction

    task automatic check_aa_of_q_equals(const ref int_aa_of_q_t actual,
                                        const ref int_aa_of_q_t expected,
                                        input string msg);
        check_true(aa_of_q_equals(actual, expected), msg);
    endtask

    task automatic test_contains();
        int_aa_of_q_t lhs;
        int_aa_t rhs;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        rhs[1] = 20;
        rhs[2] = 30;

        check_true(int_value_adapter_util_t::contains(lhs, rhs),
                   "contains should accept scalar values present in queue view");

        rhs[2] = 99;
        check_true(!int_value_adapter_util_t::contains(lhs, rhs),
                   "contains should reject absent values");
    endtask

    task automatic test_merge_family();
        int_aa_of_q_t lhs;
        int_aa_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        rhs[2] = 40;
        rhs[3] = 50;
        result[99] = {999};

        expected[1] = {10, 20};
        expected[2] = {30, 40};
        expected[3] = {50};

        int_value_adapter_util_t::merge_into(lhs, rhs, result);
        check_aa_of_q_equals(result, expected,
                             "merge_into should overwrite result with merged queue view");

        result = int_value_adapter_util_t::get_merge(lhs, rhs);
        check_aa_of_q_equals(result, expected,
                             "get_merge should return the merged queue view");

        int_value_adapter_util_t::merge_with(lhs, rhs);
        check_aa_of_q_equals(lhs, expected,
                             "merge_with should update lhs in place");
    endtask

    task automatic test_intersect_family();
        int_aa_of_q_t lhs;
        int_aa_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        lhs[3] = {40};
        rhs[1] = 20;
        rhs[2] = 99;
        rhs[4] = 40;
        result[99] = {999};

        expected[1] = {20};

        int_value_adapter_util_t::intersect_into(lhs, rhs, result);
        check_aa_of_q_equals(result, expected,
                             "intersect_into should keep only shared keys with present values");

        result = int_value_adapter_util_t::get_intersect(lhs, rhs);
        check_aa_of_q_equals(result, expected,
                             "get_intersect should return the intersected queue view");

        int_value_adapter_util_t::intersect_with(lhs, rhs);
        check_aa_of_q_equals(lhs, expected,
                             "intersect_with should update lhs in place");
    endtask

    task automatic test_diff_family();
        int_aa_of_q_t lhs;
        int_aa_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        lhs[3] = {40};
        rhs[1] = 20;
        rhs[2] = 30;
        rhs[4] = 99;
        result[99] = {999};

        expected[1] = {10};
        expected[3] = {40};

        int_value_adapter_util_t::diff_into(lhs, rhs, result);
        check_aa_of_q_equals(result, expected,
                             "diff_into should remove matching scalar values from queues");

        result = int_value_adapter_util_t::get_diff(lhs, rhs);
        check_aa_of_q_equals(result, expected,
                             "get_diff should return the differenced queue view");

        int_value_adapter_util_t::diff_with(lhs, rhs);
        check_aa_of_q_equals(lhs, expected,
                             "diff_with should update lhs in place");
    endtask

    task automatic test_projection_helpers();
        int_aa_of_q_t aa_of_q;
        int_aa_t aa;
        int_aa_t expected_aa;
        int_aa_of_q_t lifted;

        aa_of_q[1] = {10};
        aa_of_q[2] = {20};
        aa_of_q[3] = {30};

        expected_aa[1] = 10;
        expected_aa[2] = 20;
        expected_aa[3] = 30;

        aa = int_value_adapter_util_t::to_aa(aa_of_q);
        check_true(aa_equals(aa, expected_aa),
                   "to_aa should extract singleton queue values");

        lifted = int_value_adapter_util_t::to_aa_of_q(aa);
        check_aa_of_q_equals(lifted, aa_of_q,
                             "to_aa_of_q should lift scalar values into singleton queues");
    endtask

    initial begin
        test_contains();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_projection_helpers();

        $display("aa_value_adapter_util_tb: PASS");
        $finish;
    end
endmodule
