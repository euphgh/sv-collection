`include "set_util.svh"

// set_util_tb test plan
// ---------------------
// Scope:
// 1. Validate set-style behavior when UNIQUE_ELEM == 1.
// 2. Validate the currently supported queue-style behavior when UNIQUE_ELEM == 0.
// 3. Validate boundary cases called out by the set_util contract.
//
// Planned coverage:
// 1. UNIQUE_ELEM == 1 basic APIs
//    - insert deduplicates
//    - count reports membership counts in normalized sets
//    - delete removes the matching element and leaves absent keys unchanged
// 2. UNIQUE_ELEM == 1 observation APIs
//    - contains accepts subsets and rejects missing elements
//    - equals ignores queue order for normalized sets
//    - empty-set relationships follow set semantics
// 3. UNIQUE_ELEM == 1 collection APIs
//    - union_* keeps unique union elements
//    - intersect_* keeps only shared elements
//    - diff_* keeps lhs-only elements
//    - *_into preserves pre-existing result content
//    - get_* returns a pure result without stale caller-owned elements
//    - *_with mutates lhs into the pure result
// 4. unique_into
//    - converts an arbitrary queue into a unique-element queue
//    - can be used to normalize caller-owned data before set-style APIs
// 5. UNIQUE_ELEM == 0 supported APIs
//    - insert behaves as push_back
//    - count reports duplicate occurrences
//    - delete removes one occurrence only
//    - unique_into can normalize a general queue into a set-shaped queue
// 6. Explicitly out of scope for now
//    - UNIQUE_ELEM == 0 semantics for equals, contains, union, intersect, and
//      diff are intentionally not tested because the contract is not yet
//      supported.

module set_util_tb;
    `include "tests_util.svh"

    typedef set_util#(int unsigned) int_set_util_t;
    typedef int_set_util_t::set_t int_set_t;

    typedef set_util#(int unsigned, 0) int_queue_util_t;
    typedef int_queue_util_t::set_t int_queue_t;

    function automatic bit queue_equals_exact(const ref int_queue_t lhs,
                                              const ref int_queue_t rhs);
        if (lhs.size() != rhs.size())
            return 0;

        foreach (lhs[i])
            if (lhs[i] != rhs[i])
                return 0;

        return 1;
    endfunction

    task automatic test_insert_delete_count();
        int_set_t s;
        bit inserted;

        inserted = int_set_util_t::insert(s, 10);
        check_true(inserted, "insert should accept a new element");

        void'(int_set_util_t::insert(s, 20));
        inserted = int_set_util_t::insert(s, 20);
        void'(int_set_util_t::insert(s, 30));

        check_true(!inserted,
                   "insert should reject duplicates when UNIQUE_ELEM == 1");
        check_true(s.size() == 3, "insert should preserve normalized set size");
        check_true(int_set_util_t::count(s, 10) == 1,
                   "count should find inserted element");
        check_true(int_set_util_t::count(s, 20) == 1,
                   "count should report one occurrence in a normalized set");
        check_true(int_set_util_t::count(s, 99) == 0,
                   "count should return zero for absent element");

        int_set_util_t::delete(s, 20);
        check_true(s.size() == 2, "delete should reduce size for present element");
        check_true(int_set_util_t::count(s, 20) == 0,
                   "delete should remove the matching element");

        int_set_util_t::delete(s, 99);
        check_true(s.size() == 2,
                   "delete of an absent element should not change size");
    endtask

    task automatic test_contains_and_equals();
        int_set_t a;
        int_set_t b;
        int_set_t c;
        int_set_t d;

        a = {1, 2, 3};
        b = {1, 3};
        c = {3, 2, 1};
        d = {1, 2, 4};

        check_true(int_set_util_t::contains(a, b),
                   "contains should accept a normalized subset");
        check_true(!int_set_util_t::contains(b, a),
                   "contains should reject a proper superset as subset");
        check_true(int_set_util_t::equals(a, c),
                   "equals should ignore queue order for normalized sets");
        check_true(!int_set_util_t::equals(a, b),
                   "equals should fail for different set sizes");
        check_true(!int_set_util_t::equals(a, d),
                   "equals should fail for same-size different elements");
    endtask

    task automatic test_union_family();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t pure_union;

        lhs = {1, 2};
        rhs = {2, 3};
        result = {99};

        int_set_util_t::union_into(lhs, rhs, result);
        check_true(result.size() == 4,
                   "union_into should preserve pre-existing result content");
        check_true(int_set_util_t::count(result, 1) == 1,
                   "union_into should contain lhs-only element");
        check_true(int_set_util_t::count(result, 2) == 1,
                   "union_into should contain shared element once");
        check_true(int_set_util_t::count(result, 3) == 1,
                   "union_into should contain rhs-only element");
        check_true(int_set_util_t::count(result, 99) == 1,
                   "union_into should preserve existing result content");

        pure_union = int_set_util_t::get_union(lhs, rhs);
        check_true(pure_union.size() == 3,
                   "get_union should return a pure union result");
        check_true(int_set_util_t::count(pure_union, 99) == 0,
                   "get_union should not contain stale result content");

        int_set_util_t::union_with(lhs, rhs);
        check_true(lhs.size() == 3,
                   "union_with should mutate lhs into the pure union");
        check_true(int_set_util_t::count(lhs, 3) == 1,
                   "union_with should add rhs-only element to lhs");
    endtask

    task automatic test_intersect_family();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t pure_intersect;
        int_set_t expected_intersect;

        lhs = {1, 2, 3, 4};
        rhs = {2, 3, 5};
        result = {99};
        expected_intersect = {2, 3};

        int_set_util_t::intersect_into(lhs, rhs, result);
        check_true(result.size() == 3,
                   "intersect_into should preserve pre-existing result content");
        check_true(int_set_util_t::count(result, 2) == 1,
                   "intersect_into should include shared element 2");
        check_true(int_set_util_t::count(result, 3) == 1,
                   "intersect_into should include shared element 3");
        check_true(int_set_util_t::count(result, 99) == 1,
                   "intersect_into should preserve existing result content");

        pure_intersect = int_set_util_t::get_intersect(lhs, rhs);
        check_true(pure_intersect.size() == 2,
                   "get_intersect should return the pure intersection");
        check_true(int_set_util_t::contains(pure_intersect, expected_intersect),
                   "get_intersect should contain the shared elements");

        int_set_util_t::intersect_with(lhs, rhs);
        check_true(lhs.size() == 2,
                   "intersect_with should shrink lhs to the pure intersection");
        check_true(int_set_util_t::count(lhs, 2) == 1 &&
                   int_set_util_t::count(lhs, 3) == 1,
                   "intersect_with should keep only shared elements");
    endtask

    task automatic test_diff_family();
        int_set_t lhs;
        int_set_t rhs;
        int_set_t result;
        int_set_t pure_diff;

        lhs = {1, 2, 3};
        rhs = {2, 4};
        result = {99};

        int_set_util_t::diff_into(lhs, rhs, result);
        check_true(result.size() == 3,
                   "diff_into should preserve pre-existing result content");
        check_true(int_set_util_t::count(result, 1) == 1,
                   "diff_into should include lhs-only element 1");
        check_true(int_set_util_t::count(result, 3) == 1,
                   "diff_into should include lhs-only element 3");
        check_true(int_set_util_t::count(result, 99) == 1,
                   "diff_into should preserve existing result content");

        pure_diff = int_set_util_t::get_diff(lhs, rhs);
        check_true(pure_diff.size() == 2,
                   "get_diff should return the pure difference");
        check_true(int_set_util_t::count(pure_diff, 99) == 0,
                   "get_diff should not contain stale result content");

        int_set_util_t::diff_with(lhs, rhs);
        check_true(lhs.size() == 2,
                   "diff_with should shrink lhs to the pure difference");
        check_true(int_set_util_t::count(lhs, 1) == 1 &&
                   int_set_util_t::count(lhs, 3) == 1,
                   "diff_with should keep only lhs-only elements");
    endtask

    task automatic test_empty_set_operations();
        int_set_t empty = {};
        int_set_t s;
        int_set_t result;

        s = {1, 2};

        check_true(int_set_util_t::count(empty, 1) == 0,
                   "count on empty set should return zero");
        check_true(int_set_util_t::contains(s, empty),
                   "any normalized set should contain the empty set");
        check_true(!int_set_util_t::contains(empty, s),
                   "empty set should not contain a non-empty set");
        check_true(int_set_util_t::equals(empty, empty),
                   "two empty sets should be equal");

        result = int_set_util_t::get_union(empty, s);
        check_true(int_set_util_t::equals(result, s),
                   "union with empty should return the other set");

        result = int_set_util_t::get_intersect(empty, s);
        check_true(result.size() == 0,
                   "intersection with empty should be empty");

        result = int_set_util_t::get_diff(empty, s);
        check_true(result.size() == 0,
                   "empty minus non-empty should be empty");

        result = int_set_util_t::get_diff(s, empty);
        check_true(int_set_util_t::equals(result, s),
                   "non-empty minus empty should equal the original set");
    endtask

    task automatic test_unique_into();
        int_queue_t q;

        q = {4, 2, 4, 1, 2, 1};

        int_queue_util_t::unique_into(q);

        check_true(q.size() == 3,
                   "unique_into should remove duplicate occurrences");
        check_true(int_queue_util_t::count(q, 1) == 1 &&
                   int_queue_util_t::count(q, 2) == 1 &&
                   int_queue_util_t::count(q, 4) == 1,
                   "unique_into should keep one occurrence of each element");
    endtask

    task automatic test_non_unique_mode_supported_apis();
        int_queue_t q;
        bit inserted;

        inserted = int_queue_util_t::insert(q, 10);
        void'(int_queue_util_t::insert(q, 20));
        void'(int_queue_util_t::insert(q, 20));
        void'(int_queue_util_t::insert(q, 30));

        check_true(inserted,
                   "insert should accept push_back behavior when UNIQUE_ELEM == 0");
        check_true(q.size() == 4,
                   "insert should preserve duplicate entries when UNIQUE_ELEM == 0");
        check_true(int_queue_util_t::count(q, 20) == 2,
                   "count should report duplicate occurrences when UNIQUE_ELEM == 0");

        int_queue_util_t::delete(q, 20);
        check_true(q.size() == 3,
                   "delete should remove one occurrence when UNIQUE_ELEM == 0");
        check_true(int_queue_util_t::count(q, 20) == 1,
                   "delete should leave one matching occurrence behind");

        int_queue_util_t::unique_into(q);
        check_true(q.size() == 3,
                   "unique_into should normalize a general queue in UNIQUE_ELEM == 0 mode");
        check_true(int_queue_util_t::count(q, 10) == 1 &&
                   int_queue_util_t::count(q, 20) == 1 &&
                   int_queue_util_t::count(q, 30) == 1,
                   "unique_into should produce a set-shaped queue from a general queue");
    endtask

    initial begin
        test_insert_delete_count();
        test_contains_and_equals();
        test_union_family();
        test_intersect_family();
        test_diff_family();
        test_empty_set_operations();
        test_unique_into();
        test_non_unique_mode_supported_apis();

        $display("set_util_tb: PASS");
        $finish;
    end
endmodule
