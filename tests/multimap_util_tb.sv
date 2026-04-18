module multimap_util_tb;
    import collection::*;

    typedef multimap_util#(int unsigned, int unsigned) int_mmap_util_t;
    typedef int_mmap_util_t::multimap_t int_mmap_t;
    typedef int_mmap_util_t::val_set_t int_val_set_t;
    typedef int_mmap_util_t::key_set_t int_key_set_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    task automatic test_insert_and_lookup();
        int_mmap_t mmap;
        int_val_set_t values;

        int_mmap_util_t::insert(mmap, 1, 10);
        int_mmap_util_t::insert(mmap, 1, 20);
        int_mmap_util_t::insert(mmap, 1, 20);
        int_mmap_util_t::insert(mmap, 3, 30);

        check_true(int_mmap_util_t::num_keys(mmap) == 2, "num_keys should count distinct keys");
        check_true(int_mmap_util_t::num_values(mmap, 1) == 2, "duplicate insert should not increase value-set size");
        check_true(int_mmap_util_t::num_values(mmap, 7) == 0, "num_values should return zero for missing key");
        check_true(int_mmap_util_t::has_key(mmap, 1), "has_key should find existing key");
        check_true(!int_mmap_util_t::has_key(mmap, 2), "has_key should reject absent key");
        check_true(int_mmap_util_t::contains_value(mmap, 1, 10), "contains_value should find inserted pair");
        check_true(!int_mmap_util_t::contains_value(mmap, 1, 99), "contains_value should reject absent value");

        values = int_mmap_util_t::get_values(mmap, 1);
        check_true(values.size() == 2, "get_values should return all values for existing key");
        check_true(values.exists(10) && values.exists(20), "get_values should preserve inserted values");

        values = int_mmap_util_t::get_values(mmap, 9);
        check_true(values.size() == 0, "get_values should return empty set for missing key");
    endtask

    task automatic test_add_values_and_key_projection();
        int_mmap_t mmap;
        int_val_set_t values;
        int_key_set_t keys;

        values[10] = 1'b1;
        values[11] = 1'b1;

        int_mmap_util_t::add_values(mmap, 2, values);
        int_mmap_util_t::insert(mmap, 4, 40);

        check_true(int_mmap_util_t::num_values(mmap, 2) == 2, "add_values should merge all values into key");

        keys = int_mmap_util_t::get_keys(mmap);
        check_true(keys.size() == 2, "get_keys should return all keys in multimap");
        check_true(keys.exists(2) && keys.exists(4), "get_keys should preserve exact key set");
    endtask

    task automatic test_contains_and_equals();
        int_mmap_t lhs;
        int_mmap_t rhs;
        int_mmap_t same_as_lhs;
        int_mmap_t different_values;
        int_mmap_t different_keys;

        int_mmap_util_t::insert(lhs, 1, 10);
        int_mmap_util_t::insert(lhs, 1, 11);
        int_mmap_util_t::insert(lhs, 3, 30);

        int_mmap_util_t::insert(rhs, 1, 10);
        int_mmap_util_t::insert(rhs, 3, 30);

        same_as_lhs = lhs;

        int_mmap_util_t::insert(different_values, 1, 10);
        int_mmap_util_t::insert(different_values, 1, 12);
        int_mmap_util_t::insert(different_values, 3, 30);

        int_mmap_util_t::insert(different_keys, 1, 10);
        int_mmap_util_t::insert(different_keys, 4, 30);

        check_true(int_mmap_util_t::contains(lhs, rhs), "contains should accept sub-multimap");
        check_true(!int_mmap_util_t::contains(rhs, lhs), "contains should fail for proper subset on lhs side");
        check_true(int_mmap_util_t::equals(lhs, same_as_lhs), "equals should pass for identical multimap");
        check_true(!int_mmap_util_t::equals(lhs, rhs), "equals should fail when value-set sizes differ");
        check_true(!int_mmap_util_t::equals(lhs, different_values), "equals should fail when shared key has different value-set");
        check_true(!int_mmap_util_t::equals(lhs, different_keys), "equals should fail when key sets differ");
    endtask

    task automatic test_merge_family();
        int_mmap_t lhs;
        int_mmap_t rhs;
        int_mmap_t result;
        int_mmap_t exact_merge;

        int_mmap_util_t::insert(lhs, 1, 10);
        int_mmap_util_t::insert(lhs, 1, 11);
        int_mmap_util_t::insert(lhs, 2, 20);

        int_mmap_util_t::insert(rhs, 1, 11);
        int_mmap_util_t::insert(rhs, 1, 12);
        int_mmap_util_t::insert(rhs, 3, 30);

        int_mmap_util_t::insert(result, 99, 999);

        int_mmap_util_t::merge_into(lhs, rhs, result);
        check_true(int_mmap_util_t::num_keys(result) == 3, "merge_into should fully overwrite old result keys");
        check_true(int_mmap_util_t::num_values(result, 1) == 3, "merge_into should union value-sets on shared key");
        check_true(int_mmap_util_t::contains_value(result, 1, 10) && int_mmap_util_t::contains_value(result, 1, 11) && int_mmap_util_t::contains_value(result, 1, 12), "merge_into should retain all distinct values");
        check_true(int_mmap_util_t::has_key(result, 2) && int_mmap_util_t::has_key(result, 3), "merge_into should include lhs-only and rhs-only keys");
        check_true(!result.exists(99), "merge_into should discard stale result keys");

        exact_merge = int_mmap_util_t::get_merge(lhs, rhs);
        check_true(int_mmap_util_t::num_keys(exact_merge) == 3, "get_merge should return pure merge result");

        int_mmap_util_t::merge_with(lhs, rhs);
        check_true(int_mmap_util_t::num_keys(lhs) == 3, "merge_with should mutate lhs into merged multimap");
        check_true(int_mmap_util_t::num_values(lhs, 1) == 3 && int_mmap_util_t::contains_value(lhs, 3, 30), "merge_with should union shared key and append new key");
    endtask

    task automatic test_intersect_family();
        int_mmap_t lhs;
        int_mmap_t rhs;
        int_mmap_t result;
        int_mmap_t exact_intersect;

        int_mmap_util_t::insert(lhs, 1, 10);
        int_mmap_util_t::insert(lhs, 1, 11);
        int_mmap_util_t::insert(lhs, 2, 20);
        int_mmap_util_t::insert(lhs, 4, 40);

        int_mmap_util_t::insert(rhs, 1, 11);
        int_mmap_util_t::insert(rhs, 1, 12);
        int_mmap_util_t::insert(rhs, 2, 21);
        int_mmap_util_t::insert(rhs, 3, 30);

        int_mmap_util_t::insert(result, 99, 999);

        int_mmap_util_t::intersect_into(lhs, rhs, result);
        check_true(int_mmap_util_t::num_keys(result) == 1, "intersect_into should keep only keys with non-empty value intersection");
        check_true(int_mmap_util_t::has_key(result, 1) && int_mmap_util_t::num_values(result, 1) == 1 && int_mmap_util_t::contains_value(result, 1, 11), "intersect_into should keep value-set intersection on shared key");
        check_true(!result.exists(99), "intersect_into should fully overwrite prior result");

        exact_intersect = int_mmap_util_t::get_intersect(lhs, rhs);
        check_true(int_mmap_util_t::num_keys(exact_intersect) == 1 && int_mmap_util_t::contains_value(exact_intersect, 1, 11), "get_intersect should return pure intersection result");

        int_mmap_util_t::intersect_with(lhs, rhs);
        check_true(int_mmap_util_t::num_keys(lhs) == 1 && int_mmap_util_t::has_key(lhs, 1), "intersect_with should shrink lhs to keys with non-empty intersection");
        check_true(int_mmap_util_t::num_values(lhs, 1) == 1 && int_mmap_util_t::contains_value(lhs, 1, 11), "intersect_with should preserve only intersected values");
    endtask

    task automatic test_diff_family();
        int_mmap_t lhs;
        int_mmap_t rhs;
        int_mmap_t result;
        int_mmap_t exact_diff;

        int_mmap_util_t::insert(lhs, 1, 10);
        int_mmap_util_t::insert(lhs, 1, 11);
        int_mmap_util_t::insert(lhs, 2, 20);
        int_mmap_util_t::insert(lhs, 3, 30);

        int_mmap_util_t::insert(rhs, 1, 11);
        int_mmap_util_t::insert(rhs, 2, 20);
        int_mmap_util_t::insert(rhs, 4, 40);

        int_mmap_util_t::insert(result, 99, 999);

        int_mmap_util_t::diff_into(lhs, rhs, result);
        check_true(int_mmap_util_t::num_keys(result) == 2, "diff_into should keep keys with non-empty remainder only");
        check_true(int_mmap_util_t::num_values(result, 1) == 1 && int_mmap_util_t::contains_value(result, 1, 10), "diff_into should subtract rhs values from shared key");
        check_true(int_mmap_util_t::num_values(result, 3) == 1 && int_mmap_util_t::contains_value(result, 3, 30), "diff_into should preserve lhs-only key");
        check_true(!int_mmap_util_t::has_key(result, 2), "diff_into should drop key whose value-set becomes empty");
        check_true(!result.exists(99), "diff_into should fully overwrite prior result");

        exact_diff = int_mmap_util_t::get_diff(lhs, rhs);
        check_true(int_mmap_util_t::num_keys(exact_diff) == 2 && int_mmap_util_t::contains_value(exact_diff, 1, 10) && int_mmap_util_t::contains_value(exact_diff, 3, 30), "get_diff should return expected multimap difference");

        int_mmap_util_t::diff_with(lhs, rhs);
        check_true(int_mmap_util_t::num_keys(lhs) == 2, "diff_with should mutate lhs to difference result");
        check_true(int_mmap_util_t::num_values(lhs, 1) == 1 && int_mmap_util_t::contains_value(lhs, 1, 10), "diff_with should preserve non-overlapping values");
        check_true(int_mmap_util_t::has_key(lhs, 3) && !int_mmap_util_t::has_key(lhs, 2), "diff_with should remove empty shared key result");
    endtask

    task automatic test_print_helpers();
        int_mmap_t mmap;
        string s;

        s = int_mmap_util_t::sprint(mmap, "empty_mmap");
        check_true(s.len() > 0, "sprint should return non-empty string for empty multimap");

        int_mmap_util_t::insert(mmap, 5, 55);
        s = int_mmap_util_t::sprint(mmap, "one_entry");
        check_true(s.len() > 0, "sprint should return non-empty string for populated multimap");

        int_mmap_util_t::print(mmap, "one_entry");
    endtask

    initial begin
        test_insert_and_lookup();
        test_add_values_and_key_projection();
        test_contains_and_equals();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_print_helpers();

        $display("multimap_util_tb: PASS");
        $finish;
    end
endmodule
