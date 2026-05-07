module set_util_tb;
    `include "set_util.svh"

    typedef set_util#(int unsigned) int_set_util_t;
    typedef int unsigned int_set_t[$];

    task automatic check_true(input bit cond, input string msg);
        if (!cond) begin
            $error("CHECK FAILED: %s", msg);
            $fatal(1);
        end
    endtask

    task automatic test_insert_delete_count();
        int_set_t s;

        int_set_util_t::insert(s, 10);
        int_set_util_t::insert(s, 20);
        int_set_util_t::insert(s, 20);
        int_set_util_t::insert(s, 30);

        check_true(s.size() == 3, "insert should deduplicate");
        check_true(int_set_util_t::count(s, 10) == 1, "count should find inserted element");
        check_true(int_set_util_t::count(s, 20) == 1, "count should find inserted element after duplicate insert");
        check_true(int_set_util_t::count(s, 99) == 0, "count should return zero for absent element");

        int_set_util_t::delete(s, 20);
        check_true(s.size() == 2, "delete should reduce size");
        check_true(int_set_util_t::count(s, 20) == 0, "delete should remove element");

        int_set_util_t::delete(s, 99);
        check_true(s.size() == 2, "delete absent element should not change size");
    endtask

    task automatic test_contains_and_equals();
        int_set_t a;
        int_set_t b;
        int_set_t c;
        int_set_t d;

        int_set_util_t::insert(a, 1);
        int_set_util_t::insert(a, 2);
        int_set_util_t::insert(a, 3);

        int_set_util_t::insert(b, 1);
        int_set_util_t::insert(b, 3);

        int_set_util_t::insert(c, 1);
        int_set_util_t::insert(c, 2);
        int_set_util_t::insert(c, 3);

        int_set_util_t::insert(d, 1);
        int_set_util_t::insert(d, 2);
        int_set_util_t::insert(d, 4);

        check_true(int_set_util_t::contains(a, b), "contains should accept subset");
        check_true(!int_set_util_t::contains(b, a), "contains should reject proper superset");
        check_true(int_set_util_t::equals(a, c), "equals should pass for identical sets");
        check_true(!int_set_util_t::equals(a, b), "equals should fail for different sizes");
        check_true(!int_set_util_t::equals(a, d), "equals should fail for same-size different elements");
    endtask

    task automatic test_union_family();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t pure_union;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 2);

        int_set_util_t::insert(rhs, 2);
        int_set_util_t::insert(rhs, 3);

        int_set_util_t::insert(result, 99);

        int_set_util_t::union_into(lhs, rhs, result);
        check_true(result.size() == 4, "union_into should merge lhs and rhs into result");
        check_true(int_set_util_t::count(result, 1) == 1, "union_into should contain lhs-only element");
        check_true(int_set_util_t::count(result, 2) == 1, "union_into should contain shared element");
        check_true(int_set_util_t::count(result, 3) == 1, "union_into should contain rhs-only element");
        check_true(int_set_util_t::count(result, 99) == 1, "union_into should preserve pre-existing result content");

        pure_union = int_set_util_t::get_union(lhs, rhs);
        check_true(pure_union.size() == 3, "get_union should return pure union result");
        check_true(int_set_util_t::count(pure_union, 99) == 0, "get_union should not contain stale elements");

        int_set_util_t::union_with(lhs, rhs);
        check_true(lhs.size() == 3, "union_with should mutate lhs in place");
        check_true(int_set_util_t::count(lhs, 3) == 1, "union_with should add rhs-only element to lhs");
    endtask

    task automatic test_intersect_family();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t pure_intersect;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 2);
        int_set_util_t::insert(lhs, 3);
        int_set_util_t::insert(lhs, 4);

        int_set_util_t::insert(rhs, 2);
        int_set_util_t::insert(rhs, 3);
        int_set_util_t::insert(rhs, 5);

        int_set_util_t::insert(result, 99);

        int_set_util_t::intersect_into(lhs, rhs, result);
        check_true(result.size() == 3, "intersect_into should insert shared elements and preserve pre-existing");
        check_true(int_set_util_t::count(result, 2) == 1, "intersect_into should include shared element 2");
        check_true(int_set_util_t::count(result, 3) == 1, "intersect_into should include shared element 3");
        check_true(int_set_util_t::count(result, 99) == 1, "intersect_into should preserve pre-existing result content");

        pure_intersect = int_set_util_t::get_intersect(lhs, rhs);
        check_true(pure_intersect.size() == 2, "get_intersect should return pure intersection");

        int_set_util_t::intersect_with(lhs, rhs);
        check_true(lhs.size() == 2, "intersect_with should shrink lhs to intersection");
        check_true(int_set_util_t::count(lhs, 2) == 1 && int_set_util_t::count(lhs, 3) == 1, "intersect_with should keep only shared elements");
    endtask

    task automatic test_diff_family();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t pure_diff;

        int_set_util_t::insert(lhs, 1);
        int_set_util_t::insert(lhs, 2);
        int_set_util_t::insert(lhs, 3);

        int_set_util_t::insert(rhs, 2);
        int_set_util_t::insert(rhs, 4);

        int_set_util_t::insert(result, 99);

        int_set_util_t::diff_into(lhs, rhs, result);
        check_true(result.size() == 3, "diff_into should insert lhs-only elements and preserve pre-existing");
        check_true(int_set_util_t::count(result, 1) == 1, "diff_into should include lhs-only element 1");
        check_true(int_set_util_t::count(result, 3) == 1, "diff_into should include lhs-only element 3");
        check_true(int_set_util_t::count(result, 99) == 1, "diff_into should preserve pre-existing result content");

        pure_diff = int_set_util_t::get_diff(lhs, rhs);
        check_true(pure_diff.size() == 2, "get_diff should return pure difference");

        int_set_util_t::diff_with(lhs, rhs);
        check_true(lhs.size() == 2, "diff_with should shrink lhs to difference");
        check_true(int_set_util_t::count(lhs, 1) == 1 && int_set_util_t::count(lhs, 3) == 1, "diff_with should keep only lhs-only elements");
    endtask

    task automatic test_empty_set_operations();
        int_set_t empty;
        int_set_t s;
        int_set_t result;

        int_set_util_t::insert(s, 1);
        int_set_util_t::insert(s, 2);

        check_true(int_set_util_t::count(empty, 1) == 0, "count on empty set should return 0");
        check_true(int_set_util_t::contains(s, empty), "any set should contain the empty set");
        check_true(!int_set_util_t::contains(empty, s), "empty set should not contain a non-empty set");
        check_true(int_set_util_t::equals(empty, empty), "two empty sets should be equal");

        result = int_set_util_t::get_union(empty, s);
        check_true(int_set_util_t::equals(result, s), "union with empty should equal the other set");

        result = int_set_util_t::get_intersect(empty, s);
        check_true(result.size() == 0, "intersect with empty should be empty");

        result = int_set_util_t::get_diff(empty, s);
        check_true(result.size() == 0, "diff of empty minus non-empty should be empty");

        result = int_set_util_t::get_diff(s, empty);
        check_true(int_set_util_t::equals(result, s), "diff of non-empty minus empty should equal original");
    endtask

    initial begin
        test_insert_delete_count();
        test_contains_and_equals();
        test_union_family();
        test_intersect_family();
        test_diff_family();
        test_empty_set_operations();

        $display("set_util_tb: PASS");
        $finish;
    end
endmodule
