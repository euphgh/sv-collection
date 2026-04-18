module aa_util_tb;
    import collection::*;

    typedef aa_util#(int unsigned, int unsigned) int_aa_util_t;
    typedef int_aa_util_t::aa_t int_aa_t;
    typedef int_aa_util_t::key_set_t int_key_set_t;
    typedef int_aa_util_t::val_set_t int_val_set_t;

    typedef aa_util#(int unsigned, logic [3:0]) logic_aa_util_t;
    typedef logic_aa_util_t::aa_t logic_aa_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    task automatic test_equals_and_verbose();
        logic_aa_t lhs;
        logic_aa_t rhs;
        logic_aa_t same_size_different_keys;
        string diff;

        lhs[1] = 4'b10xz;
        lhs[2] = 4'b0011;
        rhs[1] = 4'b10xz;
        rhs[2] = 4'b0011;
        same_size_different_keys[1] = 4'b10xz;
        same_size_different_keys[3] = 4'b0011;

        check_true(logic_aa_util_t::equals(lhs, rhs), "equals should treat identical X/Z values as equal");
        check_true(logic_aa_util_t::equals_verbose(lhs, rhs, "lhs", "rhs", diff), "equals_verbose should pass on equal maps");
        check_true(diff == "", "equals_verbose should clear diff on success");
        check_true(!logic_aa_util_t::equals(lhs, same_size_different_keys), "equals should fail when key sets differ");

        rhs[2] = 4'b0001;
        check_true(!logic_aa_util_t::equals(lhs, rhs), "equals should fail on mismatched value");
        check_true(!logic_aa_util_t::equals_verbose(lhs, rhs, "lhs", "rhs", diff), "equals_verbose should fail on mismatch");
        check_true(diff.len() > 0, "equals_verbose should emit non-empty diff message");
    endtask

    task automatic test_contains_and_lookup_helpers();
        logic_aa_t lhs;
        logic_aa_t rhs;
        int_key_set_t required_keys;

        lhs[1] = 4'b10xz;
        lhs[2] = 4'b0011;
        lhs[4] = 4'b1111;
        rhs[1] = 4'b10xz;
        rhs[2] = 4'b0011;

        required_keys[1] = 1'b1;
        required_keys[4] = 1'b1;

        check_true(logic_aa_util_t::contains(lhs, rhs), "contains should accept sub-map with identical values");
        check_true(logic_aa_util_t::contains_keys(lhs, required_keys), "contains_keys should accept subset of keys");
        check_true(logic_aa_util_t::has_key(lhs, 2), "has_key should find existing key");
        check_true(!logic_aa_util_t::has_key(lhs, 9), "has_key should reject absent key");
        check_true(logic_aa_util_t::has_value(lhs, 4'b10xz), "has_value should match X/Z payload with ===");
        check_true(!logic_aa_util_t::has_value(lhs, 4'b1010), "has_value should reject missing payload");

        rhs[2] = 4'b0000;
        check_true(!logic_aa_util_t::contains(lhs, rhs), "contains should fail if shared key has different value");
    endtask

    task automatic test_merge_family();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t result;
        int_aa_t exact_merge;
        int_aa_t overwritten;

        lhs[1] = 10;
        lhs[2] = 20;
        rhs[2] = 99;
        rhs[3] = 30;
        result[99] = 999;

        int_aa_util_t::merge_into(lhs, rhs, result);
        check_true(result.size() == 3, "merge_into should fully overwrite previous result contents");
        check_true(result[1] == 10, "merge_into should keep lhs-only entry");
        check_true(result[2] == 99, "merge_into should let rhs overwrite shared key");
        check_true(result[3] == 30, "merge_into should include rhs-only entry");
        check_true(!result.exists(99), "merge_into should discard stale result entries");

        exact_merge = int_aa_util_t::get_merge(lhs, rhs);
        check_true(exact_merge.size() == 3, "get_merge should return merged map");
        check_true(exact_merge[2] == 99, "get_merge should overwrite with rhs value");

        int_aa_util_t::merge_with(lhs, rhs);
        check_true(lhs.size() == 3, "merge_with should mutate lhs to merged size");
        check_true(lhs[2] == 99 && lhs[3] == 30, "merge_with should overwrite and append entries");

        lhs.delete();
        lhs[1] = 10;
        lhs[2] = 20;
        overwritten = int_aa_util_t::get_intersect_merge_with(lhs, rhs);
        check_true(overwritten.size() == 1, "get_intersect_merge_with should return only overwritten entries");
        check_true(overwritten[2] == 20, "get_intersect_merge_with should preserve old lhs value in return data");
        check_true(lhs[2] == 99 && lhs[3] == 30, "get_intersect_merge_with should mutate lhs to merge result");
    endtask

    task automatic test_intersect_family();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t result;
        int_aa_t exact_intersect;

        lhs[1] = 10;
        lhs[2] = 20;
        lhs[3] = 30;
        rhs[2] = 200;
        rhs[3] = 300;
        rhs[4] = 400;
        result[99] = 999;

        int_aa_util_t::intersect_into(lhs, rhs, result);
        check_true(result.size() == 2, "intersect_into should overwrite result with intersection only");
        check_true(result[2] == 20 && result[3] == 30, "intersect_into should preserve lhs payloads");
        check_true(!result.exists(99), "intersect_into should discard stale result content");

        exact_intersect = int_aa_util_t::get_intersect(lhs, rhs);
        check_true(exact_intersect.size() == 2, "get_intersect should return two shared keys");
        check_true(exact_intersect[2] == 20 && exact_intersect[3] == 30, "get_intersect should preserve lhs payloads");

        int_aa_util_t::intersect_with(lhs, rhs);
        check_true(lhs.size() == 2, "intersect_with should shrink lhs to shared keys");
        check_true(lhs.exists(2) && lhs.exists(3), "intersect_with should retain shared keys");
        check_true(!lhs.exists(1), "intersect_with should remove lhs-only keys");
    endtask

    task automatic test_diff_family();
        int_aa_t lhs;
        int_aa_t rhs;
        int_aa_t result;
        int_aa_t exact_diff;

        lhs[1] = 10;
        lhs[2] = 20;
        lhs[3] = 30;
        rhs[2] = 200;
        rhs[4] = 400;
        result[99] = 999;

        int_aa_util_t::diff_into(lhs, rhs, result);
        check_true(result.size() == 2, "diff_into should overwrite result with lhs-only entries");
        check_true(result[1] == 10 && result[3] == 30, "diff_into should keep lhs-only payloads");
        check_true(!result.exists(99), "diff_into should discard stale result content");

        exact_diff = int_aa_util_t::get_diff(lhs, rhs);
        check_true(exact_diff.size() == 2, "get_diff should return two lhs-only keys");
        check_true(exact_diff[1] == 10 && exact_diff[3] == 30, "get_diff should preserve lhs-only payloads");

        int_aa_util_t::diff_with(lhs, rhs);
        check_true(lhs.size() == 2, "diff_with should remove intersecting keys from lhs");
        check_true(lhs.exists(1) && lhs.exists(3), "diff_with should keep lhs-only keys");
        check_true(!lhs.exists(2), "diff_with should delete shared keys");
    endtask

    task automatic test_projection_helpers();
        int_aa_t a;
        int_key_set_t keys;
        int_val_set_t values;

        a[4] = 11;
        a[7] = 22;
        a[9] = 11;

        keys = int_aa_util_t::get_keys(a);
        values = int_aa_util_t::get_values(a);

        check_true(keys.size() == 3, "get_keys should return all keys without loss");
        check_true(keys.exists(4) && keys.exists(7) && keys.exists(9), "get_keys should include every key");

        check_true(values.size() == 2, "get_values should naturally deduplicate repeated payloads");
        check_true(values.exists(11) && values.exists(22), "get_values should contain distinct payloads");
    endtask

    task automatic test_print_helpers();
        int_aa_t a;
        string s;

        s = int_aa_util_t::sprint(a, "empty_map");
        check_true(s.len() > 0, "sprint should return non-empty string for empty map");

        a[5] = 55;
        s = int_aa_util_t::sprint(a, "one_entry");
        check_true(s.len() > 0, "sprint should return non-empty string for populated map");

        int_aa_util_t::print(a, "one_entry");
    endtask

    initial begin
        test_equals_and_verbose();
        test_contains_and_lookup_helpers();
        test_merge_family();
        test_intersect_family();
        test_diff_family();
        test_projection_helpers();
        test_print_helpers();

        $display("aa_util_tb: PASS");
        $finish;
    end
endmodule
