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
//    - *_into preserves unrelated result content
//    - touched keys replace the existing queue in result
//    - returned / mutated containers remain normalized
// 6. intersect family
//    - only shared keys remain candidates
//    - shared-key value queues delegate to set_util intersect semantics
//    - empty per-key intersections leave the existing result key unchanged
//    - non-empty per-key intersections replace the existing result queue
// 7. diff family
//    - lhs-only keys are retained
//    - shared-key value queues delegate to set_util diff semantics
//    - empty per-key differences leave the existing result key unchanged
//    - non-empty per-key differences replace the existing result queue
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
        check_true(aa_equals(actual, expected), msg,
                   $sformatf("actual=%p expected=%p", actual, expected));
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
                   "equals should ignore queue order for UNIQUE_ELEM == 1",
                   $sformatf("lhs=%p rhs=%p", lhs, same_values_different_order));
        check_true(!int_aa_of_q_util_t::equals(lhs, different_key_domain),
                   "equals should fail when visible key domains differ",
                   $sformatf("lhs=%p rhs=%p", lhs, different_key_domain));
        check_true(!int_aa_of_q_util_t::equals(lhs, different_values),
                   "equals should fail when a shared key has different values",
                   $sformatf("lhs=%p rhs=%p", lhs, different_values));
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
                   "contains should accept per-key subsets",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs_subset));
        check_true(!int_aa_of_q_util_t::contains(lhs, rhs_missing_key),
                   "contains should reject missing rhs keys",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs_missing_key));
        check_true(!int_aa_of_q_util_t::contains(lhs, rhs_missing_value),
                   "contains should reject missing rhs values",
                   $sformatf("lhs=%p rhs=%p", lhs, rhs_missing_value));

        check_true(int_aa_of_q_util_t::contains_key_set(lhs, required_keys),
                   "contains_key_set should accept visible key subsets",
                   $sformatf("a=%p keys=%p", lhs, required_keys));
        check_true(!int_aa_of_q_util_t::contains_key_set(lhs, missing_keys),
                   "contains_key_set should reject absent visible keys",
                   $sformatf("a=%p keys=%p", lhs, missing_keys));

        check_true(int_aa_of_q_util_t::has_value(lhs, 20),
                   "has_value should find values under any visible key",
                   $sformatf("a=%p value=%0d", lhs, 20));
        check_true(!int_aa_of_q_util_t::has_value(lhs, 99),
                   "has_value should reject absent values",
                   $sformatf("a=%p value=%0d", lhs, 99));
    endtask

    task automatic test_insert();
        int_aa_of_q_t a;
        int_aa_of_q_t expected;
        bit inserted;

        a[1] = {10, 20};

        inserted = int_aa_of_q_util_t::insert(a, 4, 40);
        check_true(inserted,
                   "insert should create a new visible key when key is absent",
                   $sformatf("a=%p key=%0d value=%0d", a, 4, 40));
        expected[1] = {10, 20};
        expected[4] = {40};
        check_aa_equals(a, expected,
                        "insert should preserve existing content when adding a new key");

        inserted = int_aa_of_q_util_t::insert(a, 1, 30);
        check_true(inserted,
                   "insert should add a new value to an existing key",
                   $sformatf("a=%p key=%0d value=%0d", a, 1, 30));
        expected[1] = {10, 20, 30};
        check_aa_equals(a, expected,
                        "insert should append a new distinct value under an existing key");

        inserted = int_aa_of_q_util_t::insert(a, 1, 20);
        check_true(!inserted,
                   "insert should reject duplicates when UNIQUE_ELEM == 1",
                   $sformatf("a=%p key=%0d value=%0d", a, 1, 20));
        check_aa_equals(a, expected,
                        "insert should not change the container after duplicate insertion");
    endtask

    task automatic test_merge_family();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected_into;
        int_aa_of_q_t expected_pure;
        int_aa_of_q_t merged;

        lhs[1] = {10};
        lhs[2] = {20, 21};
        rhs[2] = {21, 22};
        rhs[3] = {30};
        result[99] = {999};

        expected_into[1] = {10};
        expected_into[2] = {20, 21, 22};
        expected_into[3] = {30};
        expected_into[99] = {999};

        expected_pure[1] = {10};
        expected_pure[2] = {20, 21, 22};
        expected_pure[3] = {30};

        int_aa_of_q_util_t::merge_into(lhs, rhs, result);
        check_aa_equals(result, expected_into,
                        "merge_into should update touched keys and preserve unrelated result content");
        check_true(result[2].size() == 3,
                   "merge_into should replace the touched key with the merged queue",
                   $sformatf("result[2]=%p result=%p", result[2], result));

        merged = int_aa_of_q_util_t::get_merge(lhs, rhs);
        check_aa_equals(merged, expected_pure,
                        "get_merge should return the merged container");

        int_aa_of_q_util_t::merge_with(lhs, rhs);
        check_aa_equals(lhs, expected_pure,
                        "merge_with should update lhs to the merged container");
    endtask

    task automatic test_intersect_family();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected_into;
        int_aa_of_q_t expected_pure;
        int_aa_of_q_t intersected;

        lhs[1] = {10};
        lhs[2] = {20, 21};
        lhs[3] = {30};
        rhs[2] = {21, 22};
        rhs[3] = {31};
        rhs[4] = {40};
        result[1] = {111};
        result[2] = {222};
        result[3] = {333};
        result[99] = {999};

        expected_into[1] = {111};
        expected_into[2] = {21};
        expected_into[3] = {333};
        expected_into[99] = {999};

        expected_pure[2] = {21};

        int_aa_of_q_util_t::intersect_into(lhs, rhs, result);
        check_aa_equals(result, expected_into,
                        "intersect_into should update only non-empty per-key intersections");
        check_true(result[1].size() == 1 && result[1][0] == 111 &&
                   result[2].size() == 1 && result[2][0] == 21 &&
                   result[3].size() == 1 && result[3][0] == 333,
                   "intersect_into should preserve unrelated result content and update only shared non-empty keys",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));

        intersected = int_aa_of_q_util_t::get_intersect(lhs, rhs);
        check_aa_equals(intersected, expected_pure,
                        "get_intersect should return the normalized intersection");

        int_aa_of_q_util_t::intersect_with(lhs, rhs);
        check_aa_equals(lhs, expected_pure,
                        "intersect_with should update lhs to the normalized intersection");
    endtask

    task automatic test_diff_family();
        int_aa_of_q_t lhs;
        int_aa_of_q_t rhs;
        int_aa_of_q_t result;
        int_aa_of_q_t expected_into;
        int_aa_of_q_t expected_pure;
        int_aa_of_q_t diffed;

        lhs[1] = {10};
        lhs[2] = {20, 21};
        lhs[3] = {30};
        rhs[2] = {21};
        rhs[3] = {30};
        rhs[4] = {40};
        result[1] = {111};
        result[2] = {222};
        result[3] = {333};
        result[99] = {999};

        expected_into[1] = {10};
        expected_into[2] = {20};
        expected_into[3] = {333};
        expected_into[99] = {999};

        expected_pure[1] = {10};
        expected_pure[2] = {20};

        int_aa_of_q_util_t::diff_into(lhs, rhs, result);
        check_aa_equals(result, expected_into,
                        "diff_into should update non-empty differences and preserve untouched content");
        check_true(result[3].size() == 1 && result[3][0] == 333,
                   "diff_into should leave empty per-key differences unchanged in result",
                   $sformatf("result=%p lhs=%p rhs=%p", result, lhs, rhs));

        diffed = int_aa_of_q_util_t::get_diff(lhs, rhs);
        check_aa_equals(diffed, expected_pure,
                        "get_diff should return the normalized difference");

        int_aa_of_q_util_t::diff_with(lhs, rhs);
        check_aa_equals(lhs, expected_pure,
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
                   "get_keys should return all visible keys",
                   $sformatf("keys=%p expected=%p", keys, expected_keys));
        check_true(queue_equals(values, expected_values),
                   "get_values should flatten visible values and delegate duplicate handling to set_util",
                   $sformatf("values=%p expected=%p", values, expected_values));
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
        check_true(result[99].size() == 1 && result[99][0] == 999,
                   "merge_into should preserve unrelated result content when lhs is empty",
                   $sformatf("result=%p populated=%p", result, populated));
        check_true(result[7].size() == 1 && result[7][0] == 70,
                   "merge_into should update the touched rhs key when lhs is empty",
                   $sformatf("result=%p populated=%p", result, populated));

        int_aa_of_q_util_t::intersect_into(populated, empty_rhs, result);
        check_true(result[99].size() == 1 && result[99][0] == 999,
                   "intersect_into should preserve unrelated result content when rhs is empty",
                   $sformatf("result=%p populated=%p", result, populated));
        check_true(result[7].size() == 1 && result[7][0] == 70,
                   "intersect_into should keep the preexisting touched key when the intersection is empty",
                   $sformatf("result=%p populated=%p empty_rhs=%p", result, populated, empty_rhs));

        int_aa_of_q_util_t::diff_into(empty_lhs, populated, result);
        check_true(result[99].size() == 1 && result[99][0] == 999,
                   "diff_into should preserve unrelated result content when lhs is empty",
                   $sformatf("result=%p populated=%p", result, populated));
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
