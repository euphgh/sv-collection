module multimap_array_util_tb;
    import collection::*;

    typedef multimap_array_util#(4, int unsigned, int unsigned) int_mmap_array_util_t;
    typedef int_mmap_array_util_t::multimap_t int_mmap_t;
    typedef int_mmap_array_util_t::multimap_array_t int_mmap_array_t;
    typedef int_mmap_array_util_t::val_set_t int_val_set_t;
    typedef int_mmap_array_util_t::key_set_t int_key_set_t;
    typedef int_mmap_array_util_t::key_set_array_t int_key_set_array_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    task automatic test_bank_helpers();
        int_mmap_array_t banks;
        int_mmap_t subset;
        int_val_set_t values;
        int_key_set_t keys;
        int_mmap_array_t rhs_array;

        int_mmap_array_util_t::insert(banks, 0, 1, 10);
        int_mmap_array_util_t::insert(banks, 0, 1, 11);
        int_mmap_array_util_t::insert(banks, 1, 7, 70);

        values[12] = 1'b1;
        values[13] = 1'b1;
        int_mmap_array_util_t::add_values(banks, 0, 1, values);

`ifdef COLLECTION_USE_NESTED_AA_MULTIMAP
        subset[1][10] = 1'b1;
        subset[1][11] = 1'b1;
`else
        subset[1] = new();
        subset[1].values[10] = 1'b1;
        subset[1].values[11] = 1'b1;
`endif
        keys[1] = 1'b1;
        int_mmap_array_util_t::insert(rhs_array, 0, 1, 10);

        check_true(int_mmap_array_util_t::num_values(banks) == 5, "num_values should sum all bank values");
        check_true(int_mmap_array_util_t::num_values_at_bank(banks, 0) == 4, "num_values_at_bank should count selected bank values");
        check_true(int_mmap_array_util_t::num_values_at_key(banks, 0, 1) == 4, "num_values_at_key should count selected key values");
        check_true(int_mmap_array_util_t::contains_key(banks, 0, 1), "contains_key should find key in selected bank");
        check_true(int_mmap_array_util_t::contains_value(banks, 0, 1, 12), "contains_value should find inserted value in selected bank");
        check_true(int_mmap_array_util_t::contains(banks, 0, subset), "contains should accept sub-multimap in selected bank");
        check_true(int_mmap_array_util_t::contains_multimap_array(banks, 0, rhs_array), "contains_multimap_array should require selected bank to contain each rhs bank");

        keys = int_mmap_array_util_t::get_keys(banks, 0);
        check_true(keys.size() == 1 && keys.exists(1), "get_keys should return selected bank key set");

        values = int_mmap_array_util_t::get_values(banks, 0, 1);
        check_true(values.size() == 4 && values.exists(10) && values.exists(13), "get_values should return selected bank key values");
    endtask

    task automatic test_equals_and_merge();
        int_mmap_array_t lhs;
        int_mmap_array_t rhs;
        int_mmap_array_t same_as_lhs;
        int_mmap_array_t result;
        int_mmap_array_t exact_merge;

        int_mmap_array_util_t::insert(lhs, 0, 1, 10);
        int_mmap_array_util_t::insert(lhs, 0, 1, 11);
        int_mmap_array_util_t::insert(lhs, 1, 7, 70);

        int_mmap_array_util_t::insert(rhs, 0, 1, 11);
        int_mmap_array_util_t::insert(rhs, 0, 1, 12);
        int_mmap_array_util_t::insert(rhs, 2, 8, 80);

        same_as_lhs = lhs;
        int_mmap_array_util_t::insert(result, 3, 99, 999);

        check_true(int_mmap_array_util_t::equals(lhs, same_as_lhs), "equals should pass for elementwise equal multimap-array");
        check_true(!int_mmap_array_util_t::equals(lhs, rhs), "equals should fail when any bank differs");

        int_mmap_array_util_t::merge_into(lhs, rhs, result);
        check_true(int_mmap_array_util_t::num_values_at_key(result, 0, 1) == 3, "merge_into should union values on shared bank key");
        check_true(int_mmap_array_util_t::contains_value(result, 2, 8, 80), "merge_into should add rhs-only bank content");
        check_true(int_mmap_array_util_t::num_values_at_bank(result, 3) == 0, "merge_into should overwrite stale result bank content");

        exact_merge = int_mmap_array_util_t::get_merge(lhs, rhs);
        check_true(int_mmap_array_util_t::num_values(exact_merge) == 5, "get_merge should return merged total value count");

        int_mmap_array_util_t::merge_with(lhs, rhs);
        check_true(int_mmap_array_util_t::num_values_at_key(lhs, 0, 1) == 3, "merge_with should mutate shared bank key to unioned values");
        check_true(int_mmap_array_util_t::contains_value(lhs, 2, 8, 80), "merge_with should append rhs-only bank content");
    endtask

    task automatic test_intersect_and_diff();
        int_mmap_array_t lhs;
        int_mmap_array_t rhs;
        int_mmap_array_t result;
        int_mmap_array_t exact_intersect;
        int_mmap_array_t exact_diff;
        int_mmap_array_t lhs_for_diff;
        int_key_set_array_t key_sets;

        int_mmap_array_util_t::insert(lhs, 0, 1, 10);
        int_mmap_array_util_t::insert(lhs, 0, 1, 11);
        int_mmap_array_util_t::insert(lhs, 1, 7, 70);
        int_mmap_array_util_t::insert(lhs, 2, 8, 80);

        int_mmap_array_util_t::insert(rhs, 0, 1, 11);
        int_mmap_array_util_t::insert(rhs, 1, 7, 71);
        int_mmap_array_util_t::insert(rhs, 2, 8, 80);

        int_mmap_array_util_t::insert(result, 3, 99, 999);

        int_mmap_array_util_t::intersect_into(lhs, rhs, result);
        check_true(int_mmap_array_util_t::num_values_at_key(result, 0, 1) == 1 && int_mmap_array_util_t::contains_value(result, 0, 1, 11), "intersect_into should keep shared value-set intersection in bank 0");
        check_true(int_mmap_array_util_t::num_values_at_bank(result, 1) == 0, "intersect_into should drop empty bank intersection");
        check_true(int_mmap_array_util_t::contains_value(result, 2, 8, 80), "intersect_into should preserve non-empty bank 2 intersection");
        check_true(int_mmap_array_util_t::num_values_at_bank(result, 3) == 0, "intersect_into should overwrite stale result content");

        exact_intersect = int_mmap_array_util_t::get_intersect(lhs, rhs);
        check_true(int_mmap_array_util_t::num_values(exact_intersect) == 2, "get_intersect should return expected total intersection count");

        int_mmap_array_util_t::intersect_with(lhs, rhs);
        check_true(int_mmap_array_util_t::num_values_at_key(lhs, 0, 1) == 1 && int_mmap_array_util_t::contains_value(lhs, 0, 1, 11), "intersect_with should mutate bank 0 to intersection");
        check_true(int_mmap_array_util_t::num_values_at_bank(lhs, 1) == 0, "intersect_with should clear empty bank 1");

        int_mmap_array_util_t::insert(lhs_for_diff, 0, 1, 10);
        int_mmap_array_util_t::insert(lhs_for_diff, 0, 1, 11);
        int_mmap_array_util_t::insert(lhs_for_diff, 1, 7, 70);
        int_mmap_array_util_t::insert(lhs_for_diff, 2, 8, 80);

        int_mmap_array_util_t::diff_into(lhs_for_diff, rhs, result);
        check_true(int_mmap_array_util_t::num_values_at_key(result, 0, 1) == 1 && int_mmap_array_util_t::contains_value(result, 0, 1, 10), "diff_into should keep lhs-only values in bank 0");
        check_true(int_mmap_array_util_t::contains_value(result, 1, 7, 70), "diff_into should preserve lhs-only bank 1 value");
        check_true(int_mmap_array_util_t::num_values_at_bank(result, 2) == 0, "diff_into should drop fully shared bank 2 content");

        exact_diff = int_mmap_array_util_t::get_diff(lhs_for_diff, rhs);
        check_true(int_mmap_array_util_t::num_values(exact_diff) == 2, "get_diff should return expected total diff count");

        int_mmap_array_util_t::diff_with(lhs_for_diff, rhs);
        check_true(int_mmap_array_util_t::num_values_at_key(lhs_for_diff, 0, 1) == 1 && int_mmap_array_util_t::contains_value(lhs_for_diff, 0, 1, 10), "diff_with should mutate bank 0 to lhs-only values");
        check_true(int_mmap_array_util_t::contains_value(lhs_for_diff, 1, 7, 70), "diff_with should preserve lhs-only bank 1 value");
        check_true(int_mmap_array_util_t::num_values_at_bank(lhs_for_diff, 2) == 0, "diff_with should clear fully shared bank 2");

        key_sets = int_mmap_array_util_t::get_key_sets(lhs_for_diff);
        check_true(key_sets[0].size() == 1 && key_sets[0].exists(1), "get_key_sets should return bank 0 key set");
        check_true(key_sets[1].size() == 1 && key_sets[1].exists(7), "get_key_sets should return bank 1 key set");
        check_true(key_sets[2].size() == 0, "get_key_sets should return empty set for cleared bank 2");
    endtask

    initial begin
        test_bank_helpers();
        test_equals_and_merge();
        test_intersect_and_diff();

        $display("multimap_array_util_tb: PASS");
        $finish;
    end
endmodule
