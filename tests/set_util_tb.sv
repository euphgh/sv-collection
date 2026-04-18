module set_util_tb;
    import collection::*;

    typedef set_util#(int unsigned) int_set_util_t;
    typedef int_set_util_t::set_t int_set_t;
    typedef int_set_util_t::q_of_data int_set_q_t;
    typedef int_set_util_t::aa_of_data int_set_aa_t;

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    function automatic bit queue_contains(input int_set_q_t q, input int unsigned key);
        foreach (q[i]) begin
            if (q[i] == key)
                return 1;
        end
        return 0;
    endfunction

    task automatic test_basic_membership();
        int_set_t s;

        int_set_util_t::insert(s, 2);
        int_set_util_t::insert(s, 5);
        int_set_util_t::insert(s, 5);

        check_true(s.size() == 2, "duplicate insert should not increase size");
        check_true(int_set_util_t::contains_key(s, 2), "contains_key should find inserted key");
        check_true(!int_set_util_t::contains_key(s, 7), "contains_key should reject absent key");

        int_set_util_t::delete(s, 2);
        check_true(!s.exists(2), "delete should remove existing key");

        int_set_util_t::delete(s, 9);
        check_true(s.size() == 1, "delete on absent key should be no-op");
    endtask

    task automatic test_subset_and_empty_cases();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t empty_set;
        int_set_t same_as_lhs;
        int_set_t same_size_different_keys;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 3);
        int_set_util_t::insert(lhs, 5);
        int_set_util_t::insert(rhs, 1);
        int_set_util_t::insert(rhs, 5);
        int_set_util_t::insert(same_as_lhs, 1);
        int_set_util_t::insert(same_as_lhs, 3);
        int_set_util_t::insert(same_as_lhs, 5);
        int_set_util_t::insert(same_size_different_keys, 1);
        int_set_util_t::insert(same_size_different_keys, 3);
        int_set_util_t::insert(same_size_different_keys, 7);
        empty_set = rhs;
        empty_set.delete();

        check_true(int_set_util_t::contains_set(lhs, rhs), "lhs should contain rhs subset");
        check_true(!int_set_util_t::contains_set(rhs, lhs), "rhs should not contain larger lhs");
        check_true(int_set_util_t::contains_set(lhs, empty_set), "every set should contain empty subset");
        check_true(int_set_util_t::contains_set(empty_set, empty_set), "empty set should contain empty set");
        check_true(int_set_util_t::equals(lhs, same_as_lhs), "equals should pass when key sets match exactly");
        check_true(!int_set_util_t::equals(lhs, rhs), "equals should fail when one side is proper subset");
        check_true(!int_set_util_t::equals(lhs, same_size_different_keys), "equals should fail when sizes match but keys differ");
    endtask

    task automatic test_export_helpers();
        int_set_t s;
        int_set_q_t q;
        int_set_aa_t aa_copy;

        int_set_util_t::insert(s, 8);
        int_set_util_t::insert(s, 13);

        q = int_set_util_t::to_queue(s);
        check_true(q.size() == 2, "to_queue should preserve element count");
        check_true(queue_contains(q, 8), "to_queue should contain key 8");
        check_true(queue_contains(q, 13), "to_queue should contain key 13");

        aa_copy = int_set_util_t::to_aa(s);
        check_true(aa_copy.exists(8) && aa_copy.exists(13), "to_aa should copy all keys");

        aa_copy[21] = 1'b1;
        check_true(!s.exists(21), "to_aa result should be a copy, not alias original set");
    endtask

    task automatic test_union_apis();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t exact_union;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 2);
        int_set_util_t::insert(rhs, 2);
        int_set_util_t::insert(rhs, 4);
        int_set_util_t::insert(result, 99);

        int_set_util_t::union_into(lhs, rhs, result);
        check_true(result.size() == 4, "union_into should preserve existing result entries and add union keys");
        check_true(result.exists(1) && result.exists(2) && result.exists(4), "union_into should add lhs and rhs keys");
        check_true(result.exists(99), "union_into should preserve preexisting result key");

        exact_union = int_set_util_t::get_union(lhs, rhs);
        check_true(exact_union.size() == 3, "get_union should return pure union result");
        check_true(exact_union.exists(1) && exact_union.exists(2) && exact_union.exists(4), "get_union should contain expected keys");

        int_set_util_t::union_with(lhs, rhs);
        check_true(lhs.size() == 3, "union_with should mutate lhs to union result");
        check_true(lhs.exists(1) && lhs.exists(2) && lhs.exists(4), "union_with should retain and add keys");
    endtask

    task automatic test_intersect_apis();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t exact_intersect;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 2);
        int_set_util_t::insert(lhs, 3);
        int_set_util_t::insert(rhs, 2);
        int_set_util_t::insert(rhs, 3);
        int_set_util_t::insert(rhs, 4);
        int_set_util_t::insert(result, 99);

        int_set_util_t::intersect_into(lhs, rhs, result);
        check_true(result.size() == 3, "intersect_into should preserve existing result entries and add intersection keys");
        check_true(result.exists(2) && result.exists(3), "intersect_into should insert shared keys");
        check_true(result.exists(99), "intersect_into should preserve preexisting result content");

        exact_intersect = int_set_util_t::get_intersect(lhs, rhs);
        check_true(exact_intersect.size() == 2, "get_intersect should return only shared keys");
        check_true(exact_intersect.exists(2) && exact_intersect.exists(3), "get_intersect should contain expected shared keys");

        int_set_util_t::intersect_with(lhs, rhs);
        check_true(lhs.size() == 2, "intersect_with should shrink lhs to shared keys");
        check_true(lhs.exists(2) && lhs.exists(3), "intersect_with should keep only shared keys");
        check_true(!lhs.exists(1), "intersect_with should delete lhs-only keys");
    endtask

    task automatic test_diff_apis();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t exact_diff;
        int_set_t empty_set;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 2);
        int_set_util_t::insert(lhs, 3);
        int_set_util_t::insert(rhs, 2);
        int_set_util_t::insert(rhs, 5);
        int_set_util_t::insert(result, 99);
        empty_set = rhs;
        empty_set.delete();

        int_set_util_t::diff_into(lhs, rhs, result);
        check_true(result.size() == 3, "diff_into should preserve existing result entries and add lhs-only keys");
        check_true(result.exists(1) && result.exists(3), "diff_into should insert lhs-only keys");
        check_true(result.exists(99), "diff_into should preserve preexisting result content");

        exact_diff = int_set_util_t::get_diff(lhs, rhs);
        check_true(exact_diff.size() == 2, "get_diff should return only lhs-only keys");
        check_true(exact_diff.exists(1) && exact_diff.exists(3), "get_diff should contain expected lhs-only keys");

        int_set_util_t::diff_with(lhs, rhs);
        check_true(lhs.size() == 2, "diff_with should remove shared keys from lhs");
        check_true(lhs.exists(1) && lhs.exists(3), "diff_with should keep lhs-only keys");
        check_true(!lhs.exists(2), "diff_with should remove intersecting keys");

        exact_diff = int_set_util_t::get_diff(empty_set, rhs);
        check_true(exact_diff.size() == 0, "empty minus rhs should remain empty");
    endtask

    initial begin
        test_basic_membership();
        test_subset_and_empty_cases();
        test_export_helpers();
        test_union_apis();
        test_intersect_apis();
        test_diff_apis();

        $display("set_util_tb: PASS");
        $finish;
    end
endmodule
