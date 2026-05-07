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
//    - preserves unrelated result content for *_into
//    - replaces the touched key's queue when the result is non-empty
// 3. intersect family
//    - keeps only shared keys whose scalar values are present in the queue
//    - leaves existing result content unchanged when the intersection is empty
// 4. diff family
//    - removes one matching occurrence per shared key
//    - leaves existing result content unchanged when the difference is empty
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
        check_true(aa_of_q_equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
    endtask

    task automatic test_contains();
        int_aa_of_q_t lhs;
        int_aa_t rhs;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        rhs[1] = 20;
        rhs[2] = 30;

        check_true(int_value_adapter_util_t::contains(lhs, rhs),
                   "contains should accept scalar values present in queue view",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));

        rhs[2] = 99;
        check_true(!int_value_adapter_util_t::contains(lhs, rhs),
                   "contains should reject absent values",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs));
    endtask

    task automatic test_merge_family();
        int_aa_of_q_t lhs;
        int_aa_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected_into;
        int_aa_of_q_t expected_pure;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        rhs[2] = 40;
        rhs[3] = 50;
        result[99] = {999};

        expected_into[1] = {10, 20};
        expected_into[2] = {30, 40};
        expected_into[3] = {50};
        expected_into[99] = {999};

        expected_pure[1] = {10, 20};
        expected_pure[2] = {30, 40};
        expected_pure[3] = {50};

        int_value_adapter_util_t::merge_into(lhs, rhs, result);
        check_aa_of_q_equals(result, expected_into,
                              "merge_into should preserve unrelated result content and update touched keys");
        check_true(result[2].size() == 2 && result[2][0] == 30 && result[2][1] == 40,
                   "merge_into should replace the touched key with the merged queue",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));

        result = int_value_adapter_util_t::get_merge(lhs, rhs);
        check_aa_of_q_equals(result, expected_pure,
                              "get_merge should return the merged queue view");

        int_value_adapter_util_t::merge_with(lhs, rhs);
        check_aa_of_q_equals(lhs, expected_pure,
                              "merge_with should update lhs in place");
    endtask

    task automatic test_intersect_family();
        int_aa_of_q_t lhs;
        int_aa_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected_into;
        int_aa_of_q_t expected_pure;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        lhs[3] = {40};
        rhs[1] = 20;
        rhs[2] = 99;
        rhs[4] = 40;
        result[1] = {111};
        result[2] = {222};
        result[3] = {333};
        result[99] = {999};

        expected_into[1] = {20};
        expected_into[2] = {222};
        expected_into[3] = {333};
        expected_into[99] = {999};

        expected_pure[1] = {20};

        int_value_adapter_util_t::intersect_into(lhs, rhs, result);
        check_aa_of_q_equals(result, expected_into,
                              "intersect_into should update only non-empty intersections and preserve unrelated content");

        result = int_value_adapter_util_t::get_intersect(lhs, rhs);
        check_aa_of_q_equals(result, expected_pure,
                              "get_intersect should return the intersected queue view");

        int_value_adapter_util_t::intersect_with(lhs, rhs);
        check_aa_of_q_equals(lhs, expected_pure,
                              "intersect_with should update lhs in place");
    endtask

    task automatic test_diff_family();
        int_aa_of_q_t lhs;
        int_aa_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected_into;
        int_aa_of_q_t expected_pure;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        lhs[3] = {40};
        rhs[1] = 20;
        rhs[2] = 30;
        rhs[4] = 99;
        result[1] = {111};
        result[2] = {222};
        result[3] = {333};
        result[99] = {999};

        expected_into[1] = {10};
        expected_into[2] = {222};
        expected_into[3] = {40};
        expected_into[99] = {999};

        expected_pure[1] = {10};
        expected_pure[3] = {40};

        int_value_adapter_util_t::diff_into(lhs, rhs, result);
        check_aa_of_q_equals(result, expected_into,
                              "diff_into should update only non-empty differences and preserve unrelated content");

        result = int_value_adapter_util_t::get_diff(lhs, rhs);
        check_aa_of_q_equals(result, expected_pure,
                              "get_diff should return the differenced queue view");

        int_value_adapter_util_t::diff_with(lhs, rhs);
        check_aa_of_q_equals(lhs, expected_pure,
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
                   "to_aa should extract singleton queue values",
                   $sformatf("aa=%p expected=%p", aa, expected_aa));

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
