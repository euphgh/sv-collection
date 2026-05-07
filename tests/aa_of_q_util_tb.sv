`include "aa_of_q_util.svh"

// aa_of_q_util_tb test plan
// -------------------------
// Scope:
// 1. Validate the normalized-container contract for aa_of_q_t.
// 2. Validate observation APIs on normalized operands.
// 3. Validate mutation APIs and collection APIs on normalized operands.
// 4. Validate boundary cases that are called out by the API contract.
//
// Planned coverage:
// 1. clean
//    - removes keys mapped to empty queues
//    - preserves non-empty keys and their values
//    - leaves already-normalized containers unchanged
// 2. equals
//    - passes for same visible key domain and same per-key value sets
//    - ignores queue order when UNIQUE_ELEM == 1
//    - fails for different key domains
//    - fails for different per-key value sets
// 3. contains / contains_key_set / has_value
//    - accepts subset relationships
//    - rejects missing keys and missing values
//    - respects visible-key semantics
// 4. insert
//    - inserts into a new key
//    - inserts a new value into an existing key
//    - rejects duplicate values when UNIQUE_ELEM == 1
//    - preserves normalized representation
// 5. merge family
//    - key-level union
//    - shared-key value queues delegate to set_util union semantics
//    - *_into fully overwrites stale result contents
//    - returned / mutated containers remain normalized
// 6. intersect family
//    - only shared keys remain candidates
//    - shared-key value queues delegate to set_util intersect semantics
//    - keys whose intersected value queue is empty are removed
//    - *_into fully overwrites stale result contents
// 7. diff family
//    - lhs-only keys are retained
//    - shared-key value queues delegate to set_util diff semantics
//    - keys whose diffed value queue is empty are removed
//    - *_into fully overwrites stale result contents
// 8. projections
//    - get_keys returns all visible keys
//    - get_values flattens all visible values and delegates duplicate handling
//      to set_util
// 9. boundary cases
//    - empty lhs / rhs operands
//    - complete cancellation of a shared key in intersect / diff
//    - pre-populated result containers passed to *_into

module aa_of_q_util_tb;
    `include "tests_util.svh"

    typedef aa_of_q_util#(int unsigned, int unsigned) int_aa_of_q_util_t;
    typedef int_aa_of_q_util_t::aa_of_q_t int_aa_of_q_t;
    typedef int_aa_of_q_util_t::key_set_t int_key_set_t;
    typedef int_aa_of_q_util_t::val_set_t int_val_set_t;

    typedef set_util#(int unsigned) int_set_util_t;

    function automatic bit queue_equals(const ref int_val_set_t lhs,
                                        const ref int_val_set_t rhs);
        return int_set_util_t::equals(lhs, rhs);
    endfunction

    function automatic bit aa_equals(const ref int_aa_of_q_t lhs,
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

    task automatic check_aa_equals(const ref int_aa_of_q_t actual,
                                   const ref int_aa_of_q_t expected,
                                   input string msg);
        check_true(aa_equals(actual, expected), msg);
    endtask

    task automatic test_clean();
        int_aa_of_q_t dirty;
        int_aa_of_q_t expected;
        int_aa_of_q_t already_clean;
        int_aa_of_q_t before_clean;

        dirty[1] = {};
        dirty[2] = {20, 21};
        dirty[3] = {};
        dirty[4] = {40};

        expected[2] = {20, 21};
        expected[4] = {40};

        int_aa_of_q_util_t::clean(dirty);
        check_aa_equals(dirty, expected,
                        "clean should remove only empty-queue keys");

        already_clean = expected;
        before_clean = already_clean;
        int_aa_of_q_util_t::clean(already_clean);
        check_aa_equals(already_clean, before_clean,
                        "clean should leave normalized containers unchanged");
    endtask

    task automatic test_equals();
        int_aa_of_q_t lhs;
        int_aa_of_q_t same_values_different_order;
        int_aa_of_q_t different_key_domain;
        int_aa_of_q_t different_values;

        lhs[1] = {10, 20};
        lhs[4] = {40};

        same_values_different_order[1] = {20, 10};
        same_values_different_order[4] = {40};

        different_key_domain[1] = {10, 20};
        different_key_domain[5] = {40};

        different_values[1] = {10, 21};
        different_values[4] = {40};

        check_true(int_aa_of_q_util_t::equals(lhs, same_values_different_order),
                   "equals should ignore queue order for UNIQUE_ELEM == 1");
        check_true(!int_aa_of_q_util_t::equals(lhs, different_key_domain),
                   "equals should fail when visible key domains differ");
        check_true(!int_aa_of_q_util_t::equals(lhs, different_values),
                   "equals should fail when a shared key has different values");
    endtask

    task automatic test_contains_and_lookup_helpers();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs_subset;
        int_aa_of_q_t rhs_missing_key;
        int_aa_of_q_t rhs_missing_value;
        int_key_set_t required_keys;
        int_key_set_t missing_keys;

        lhs[1] = {10, 20, 30};
        lhs[4] = {40};
        rhs_subset[1] = {10, 30};
        rhs_subset[4] = {40};
        rhs_missing_key[1] = {10};
        rhs_missing_key[5] = {50};
        rhs_missing_value[1] = {10, 31};

        required_keys = {1, 4};
        missing_keys = {1, 5};

        check_true(int_aa_of_q_util_t::contains(lhs, rhs_subset),
                   "contains should accept per-key subsets");
        check_true(!int_aa_of_q_util_t::contains(lhs, rhs_missing_key),
                   "contains should reject missing rhs keys");
        check_true(!int_aa_of_q_util_t::contains(lhs, rhs_missing_value),
                   "contains should reject missing rhs values");

        check_true(int_aa_of_q_util_t::contains_key_set(lhs, required_keys),
                   "contains_key_set should accept visible key subsets");
        check_true(!int_aa_of_q_util_t::contains_key_set(lhs, missing_keys),
                   "contains_key_set should reject absent visible keys");

        check_true(int_aa_of_q_util_t::has_value(lhs, 20),
                   "has_value should find values under any visible key");
        check_true(!int_aa_of_q_util_t::has_value(lhs, 99),
                   "has_value should reject absent values");
    endtask

    task automatic test_insert();
        int_aa_of_q_t a;
        int_aa_of_q_t expected;
        bit inserted;

        a[1] = {10, 20};

        inserted = int_aa_of_q_util_t::insert(a, 4, 40);
        check_true(inserted,
                   "insert should create a new visible key when key is absent");
        expected[1] = {10, 20};
        expected[4] = {40};
        check_aa_equals(a, expected,
                        "insert should preserve existing content when adding a new key");

        inserted = int_aa_of_q_util_t::insert(a, 1, 30);
        check_true(inserted,
                   "insert should add a new value to an existing key");
        expected[1] = {10, 20, 30};
        check_aa_equals(a, expected,
                        "insert should append a new distinct value under an existing key");

        inserted = int_aa_of_q_util_t::insert(a, 1, 20);
        check_true(!inserted,
                   "insert should reject duplicates when UNIQUE_ELEM == 1");
        check_aa_equals(a, expected,
                        "insert should not change the container after duplicate insertion");
    endtask

    task automatic test_merge_family();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;
        int_aa_of_q_t merged;

        lhs[1] = {10};
        lhs[2] = {20, 21};
        rhs[2] = {21, 22};
        rhs[3] = {30};
        result[99] = {999};

        expected[1] = {10};
        expected[2] = {20, 21, 22};
        expected[3] = {30};

        int_aa_of_q_util_t::merge_into(lhs, rhs, result);
        check_aa_equals(result, expected,
                        "merge_into should overwrite result with key union and per-key union");
        check_true(!result.exists(99),
                   "merge_into should discard stale result keys");

        merged = int_aa_of_q_util_t::get_merge(lhs, rhs);
        check_aa_equals(merged, expected,
                        "get_merge should return the merged container");

        int_aa_of_q_util_t::merge_with(lhs, rhs);
        check_aa_equals(lhs, expected,
                        "merge_with should update lhs to the merged container");
    endtask

    task automatic test_intersect_family();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;
        int_aa_of_q_t intersected;

        lhs[1] = {10};
        lhs[2] = {20, 21};
        lhs[3] = {30};
        rhs[2] = {21, 22};
        rhs[3] = {31};
        rhs[4] = {40};
        result[99] = {999};

        expected[2] = {21};

        int_aa_of_q_util_t::intersect_into(lhs, rhs, result);
        check_aa_equals(result, expected,
                        "intersect_into should keep only shared keys with non-empty per-key intersection");
        check_true(!result.exists(3),
                   "intersect_into should drop shared keys whose intersected queue is empty");
        check_true(!result.exists(99),
                   "intersect_into should discard stale result keys");

        intersected = int_aa_of_q_util_t::get_intersect(lhs, rhs);
        check_aa_equals(intersected, expected,
                        "get_intersect should return the normalized intersection");

        int_aa_of_q_util_t::intersect_with(lhs, rhs);
        check_aa_equals(lhs, expected,
                        "intersect_with should update lhs to the normalized intersection");
    endtask

    task automatic test_diff_family();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;
        int_aa_of_q_t diffed;

        lhs[1] = {10};
        lhs[2] = {20, 21};
        lhs[3] = {30};
        rhs[2] = {21};
        rhs[3] = {30};
        rhs[4] = {40};
        result[99] = {999};

        expected[1] = {10};
        expected[2] = {20};

        int_aa_of_q_util_t::diff_into(lhs, rhs, result);
        check_aa_equals(result, expected,
                        "diff_into should keep lhs-only keys and per-key lhs minus rhs values");
        check_true(!result.exists(3),
                   "diff_into should drop keys whose diffed queue is empty");
        check_true(!result.exists(99),
                   "diff_into should discard stale result keys");

        diffed = int_aa_of_q_util_t::get_diff(lhs, rhs);
        check_aa_equals(diffed, expected,
                        "get_diff should return the normalized difference");

        int_aa_of_q_util_t::diff_with(lhs, rhs);
        check_aa_equals(lhs, expected,
                        "diff_with should update lhs to the normalized difference");
    endtask

    task automatic test_projection_helpers();
        int_aa_of_q_t a;
        int_key_set_t keys;
        int_key_set_t expected_keys;
        int_val_set_t values;
        int_val_set_t expected_values;

        a[1] = {10, 20};
        a[4] = {20, 40};

        expected_keys = {1, 4};
        expected_values = {10, 20, 40};

        keys = int_aa_of_q_util_t::get_keys(a);
        values = int_aa_of_q_util_t::get_values(a);

        check_true(queue_equals(keys, expected_keys),
                   "get_keys should return all visible keys");
        check_true(queue_equals(values, expected_values),
                   "get_values should flatten visible values and delegate duplicate handling to set_util");
    endtask

    task automatic test_boundary_cases();
        int_aa_of_q_t empty_lhs;
        int_aa_of_q_t empty_rhs;
        int_aa_of_q_t populated;
        int_aa_of_q_t result;
        int_aa_of_q_t expected;

        populated[7] = {70};
        result[99] = {999};

        int_aa_of_q_util_t::merge_into(empty_lhs, populated, result);
        check_aa_equals(result, populated,
                        "merge_into should handle an empty lhs operand");

        int_aa_of_q_util_t::intersect_into(populated, empty_rhs, result);
        check_aa_equals(result, expected,
                        "intersect_into should return empty when rhs is empty");

        int_aa_of_q_util_t::diff_into(empty_lhs, populated, result);
        check_aa_equals(result, expected,
                        "diff_into should return empty when lhs is empty");
    endtask

    initial begin
        test_clean();
        test_equals();
        test_contains_and_lookup_helpers();
        test_insert();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_projection_helpers();
        test_boundary_cases();

        $display("aa_of_q_util_tb: PASS");
        $finish;
    end
endmodule
