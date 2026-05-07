`include "aa_util.svh"

// aa_util_tb test plan
// --------------------
// Scope:
// 1. Validate the map-style container contract for aa_util.
// 2. Validate observation APIs on normal associative-array operands.
// 3. Validate mutation APIs and collection APIs on normal operands.
// 4. Validate the key-set helper that was kept as a user-facing API.
//
// Planned coverage:
// 1. equals
//    - passes for identical maps
//    - fails when key sets differ
//    - fails when a shared key has a different value
// 2. contains
//    - accepts proper sub-maps
//    - rejects missing keys
//    - rejects different values on shared keys
// 3. contains_keys
//    - accepts subsets of visible keys
//    - rejects missing keys
// 4. has_value
//    - finds present values
//    - rejects missing values
// 5. insert
//    - inserts new keys
//    - rejects duplicate keys
// 6. merge family
//    - rhs overrides lhs on shared keys
//    - *_into preserves pre-existing result content
//    - get_merge returns a pure merged map
//    - merge_with mutates lhs in place
// 7. intersect family
//    - keeps only shared keys
//    - preserves lhs payload on shared keys
//    - *_into preserves pre-existing result content
// 8. diff family
//    - keeps lhs-only keys
//    - *_into preserves pre-existing result content
// 9. projections
//    - get_keys returns the visible key set
//    - get_values returns a queue view that preserves repeated values
// 10. boundary cases
//    - empty associative arrays
//    - pre-populated result containers passed to *_into

module aa_util_tb;
    `include "tests_util.svh"

    typedef aa_util#(int unsigned, int unsigned) int_aa_util_t;
    typedef int_aa_util_t::aa_t int_aa_t;
    typedef int_aa_util_t::key_set_t int_key_set_t;
    typedef int_aa_util_t::val_q_t int_val_q_t;
    typedef set_util#(int unsigned) int_key_set_util_t;

    function automatic bit queue_equals(const ref int_val_q_t lhs,
                                        const ref int_val_q_t rhs);
        if (lhs.size() != rhs.size())
            return 0;

        foreach (lhs[i])
            if (lhs[i] != rhs[i])
                return 0;

        return 1;
    endfunction

    function automatic bit aa_equals(const ref int_aa_t lhs,
                                     const ref int_aa_t rhs);
        if (lhs.num() != rhs.num())
            return 0;

        foreach (lhs[k]) begin
            if (!rhs.exists(k))
                return 0;
            if (lhs[k] != rhs[k])
                return 0;
        end

        return 1;
    endfunction

    task automatic check_aa_equals(const ref int_aa_t actual,
                                   const ref int_aa_t expected,
                                   input string msg);
        check_true(aa_equals(actual, expected), msg);
    endtask

    task automatic test_equals();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t different_keys;
        int_aa_t different_values;

        lhs[1] = 10;
        lhs[2] = 20;
        rhs[1] = 10;
        rhs[2] = 20;
        different_keys[1] = 10;
        different_keys[3] = 20;
        different_values[1] = 10;
        different_values[2] = 21;

        check_true(int_aa_util_t::equals(lhs, rhs),
                   "equals should pass for identical maps");
        check_true(!int_aa_util_t::equals(lhs, different_keys),
                   "equals should fail when key sets differ");
        check_true(!int_aa_util_t::equals(lhs, different_values),
                   "equals should fail when a shared key has a different value");
    endtask

    task automatic test_contains_and_key_helpers();
        int_aa_t lhs;
        int_aa_t rhs_subset;
        int_aa_t rhs_missing_key;
        int_aa_t rhs_missing_value;
        int_key_set_t required_keys;
        int_key_set_t missing_keys;

        lhs[1] = 10;
        lhs[2] = 20;
        lhs[4] = 40;
        rhs_subset[1] = 10;
        rhs_subset[2] = 20;
        rhs_missing_key[1] = 10;
        rhs_missing_key[5] = 50;
        rhs_missing_value[1] = 10;
        rhs_missing_value[2] = 21;

        required_keys = {1, 4};
        missing_keys = {1, 5};

        check_true(int_aa_util_t::contains(lhs, rhs_subset),
                   "contains should accept proper sub-maps");
        check_true(!int_aa_util_t::contains(lhs, rhs_missing_key),
                   "contains should reject missing rhs keys");
        check_true(!int_aa_util_t::contains(lhs, rhs_missing_value),
                   "contains should reject different shared values");

        check_true(int_aa_util_t::contains_keys(lhs, required_keys),
                   "contains_keys should accept visible key subsets");
        check_true(!int_aa_util_t::contains_keys(lhs, missing_keys),
                   "contains_keys should reject missing keys");

        check_true(int_aa_util_t::has_value(lhs, 20),
                   "has_value should find present values");
        check_true(!int_aa_util_t::has_value(lhs, 99),
                   "has_value should reject missing values");
    endtask

    task automatic test_insert();
        int_aa_t a;
        int_aa_t expected;
        bit inserted;

        inserted = int_aa_util_t::insert(a, 1, 10);
        check_true(inserted, "insert should accept a new key");
        expected[1] = 10;
        check_aa_equals(a, expected,
                        "insert should create the requested mapping");

        inserted = int_aa_util_t::insert(a, 2, 20);
        check_true(inserted, "insert should accept another new key");
        expected[2] = 20;
        check_aa_equals(a, expected,
                        "insert should preserve existing mappings when adding new keys");

        inserted = int_aa_util_t::insert(a, 1, 99);
        check_true(!inserted, "insert should reject duplicate keys");
        check_aa_equals(a, expected,
                        "insert should not mutate on duplicate key insertion");
    endtask

    task automatic test_merge_family();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t result;
        int_aa_t expected_into;
        int_aa_t expected_pure;
        int_aa_t merged;

        lhs[1] = 10;
        lhs[2] = 20;
        rhs[2] = 99;
        rhs[3] = 30;
        result[99] = 999;

        expected_into[1] = 10;
        expected_into[2] = 99;
        expected_into[3] = 30;
        expected_into[99] = 999;

        expected_pure[1] = 10;
        expected_pure[2] = 99;
        expected_pure[3] = 30;

        int_aa_util_t::merge_into(lhs, rhs, result);
        check_aa_equals(result, expected_into,
                        "merge_into should insert merge result into result");
        check_true(result.exists(99),
                   "merge_into should preserve pre-existing result content");

        merged = int_aa_util_t::get_merge(lhs, rhs);
        check_aa_equals(merged, expected_pure,
                        "get_merge should return the pure merged map");

        int_aa_util_t::merge_with(lhs, rhs);
        check_aa_equals(lhs, expected_pure,
                        "merge_with should mutate lhs to the merge result");
    endtask

    task automatic test_intersect_family();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t result;
        int_aa_t expected_into;
        int_aa_t expected_pure;
        int_aa_t intersected;

        lhs[1] = 10;
        lhs[2] = 20;
        lhs[3] = 30;
        rhs[2] = 200;
        rhs[3] = 300;
        rhs[4] = 400;
        result[99] = 999;

        expected_into[2] = 20;
        expected_into[3] = 30;
        expected_into[99] = 999;

        expected_pure[2] = 20;
        expected_pure[3] = 30;

        int_aa_util_t::intersect_into(lhs, rhs, result);
        check_aa_equals(result, expected_into,
                        "intersect_into should insert only shared keys");
        check_true(result.exists(99),
                   "intersect_into should preserve pre-existing result content");

        intersected = int_aa_util_t::get_intersect(lhs, rhs);
        check_aa_equals(intersected, expected_pure,
                        "get_intersect should return the pure intersection");

        int_aa_util_t::intersect_with(lhs, rhs);
        check_aa_equals(lhs, expected_pure,
                        "intersect_with should mutate lhs to the intersection result");
    endtask

    task automatic test_diff_family();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t result;
        int_aa_t expected_into;
        int_aa_t expected_pure;
        int_aa_t diffed;

        lhs[1] = 10;
        lhs[2] = 20;
        lhs[3] = 30;
        rhs[2] = 200;
        rhs[4] = 400;
        result[99] = 999;

        expected_into[1] = 10;
        expected_into[3] = 30;
        expected_into[99] = 999;

        expected_pure[1] = 10;
        expected_pure[3] = 30;

        int_aa_util_t::diff_into(lhs, rhs, result);
        check_aa_equals(result, expected_into,
                        "diff_into should insert lhs-only keys into result");
        check_true(result.exists(99),
                   "diff_into should preserve pre-existing result content");

        diffed = int_aa_util_t::get_diff(lhs, rhs);
        check_aa_equals(diffed, expected_pure,
                        "get_diff should return the pure difference");

        int_aa_util_t::diff_with(lhs, rhs);
        check_aa_equals(lhs, expected_pure,
                        "diff_with should mutate lhs to the difference result");
    endtask

    task automatic test_projection_helpers();
        int_aa_t a;
        int_key_set_t keys;
        int_val_q_t values;
        int_val_q_t expected_values;

        a[4] = 11;
        a[7] = 22;
        a[9] = 11;

        expected_values = {11, 22, 11};

        keys = int_aa_util_t::get_keys(a);
        values = int_aa_util_t::get_values(a);

        check_true(keys.size() == 3 &&
                   int_key_set_util_t::count(keys, 4) == 1 &&
                   int_key_set_util_t::count(keys, 7) == 1 &&
                   int_key_set_util_t::count(keys, 9) == 1,
                   "get_keys should return the visible key set");
        check_true(queue_equals(values, expected_values),
                   "get_values should preserve repeated values");
    endtask

    task automatic test_empty_map_operations();
        int_aa_t empty;
        int_aa_t populated;
        int_aa_t result;

        populated[1] = 10;

        check_true(int_aa_util_t::equals(empty, empty),
                   "two empty maps should be equal");
        check_true(int_aa_util_t::contains(populated, empty),
                   "any map should contain the empty map");
        check_true(!int_aa_util_t::contains(empty, populated),
                   "empty map should not contain a non-empty map");

        result = int_aa_util_t::get_merge(empty, populated);
        check_true(result.size() == 1 && result[1] == 10,
                   "merge with empty lhs should return rhs content");

        result = int_aa_util_t::get_intersect(empty, populated);
        check_true(result.size() == 0,
                   "intersection with empty should be empty");

        result = int_aa_util_t::get_diff(empty, populated);
        check_true(result.size() == 0,
                   "empty minus non-empty should be empty");
    endtask

    initial begin
        test_equals();
        test_contains_and_key_helpers();
        test_insert();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_projection_helpers();
        test_empty_map_operations();

        $display("aa_util_tb: PASS");
        $finish;
    end
endmodule
