// collection_smoke_tb test plan
// ----------------------------
// Scope:
// 1. Validate that all utilities are accessible through `import collection::*`.
// 2. Validate core API behavior for each utility class.
// 3. Validate that array utilities delegate correctly to their element utilities.
// 4. Validate that adapter utilities bridge correctly between container shapes.
//
// Planned coverage:
// 1. set_util
//    - insert, equals, contains, union_into, get_intersect, get_diff
// 2. set_array_util
//    - equals, contains, union_into, get_intersect, diff_with
// 3. aa_util
//    - equals, contains, merge_into, get_intersect, get_diff, contains_keys
// 4. aa_array_util
//    - equals, contains, merge_into, get_intersect, diff_with, get_keys
// 5. aa_of_q_util
//    - insert, equals, contains, merge_into, intersect_into, diff_into,
//      clean, get_keys, get_values
// 6. aa_of_q_array_util
//    - equals, contains, merge_into, intersect_into, diff_into,
//      clean, get_keys, get_value_sets
// 7. aa_value_adapter_util
//    - contains, merge_into, intersect_into, diff_into,
//      to_aa, to_aa_of_q
// 8. aa_value_adapter_array_util
//    - contains, merge_into, intersect_into, diff_into,
//      to_aa, to_aa_of_q

module collection_smoke_tb;
    import collection::*;

    `include "tests_util.svh"

    // -----------------------------------------------------------------------
    // 1. set_util
    // -----------------------------------------------------------------------
    task automatic test_set_util();
        typedef set_util#(int unsigned) int_set_util_t;
        typedef int_set_util_t::set_t int_set_t;
        int_set_t lhs, rhs, result, exact;

        void'(int_set_util_t::insert(lhs, 1));
        void'(int_set_util_t::insert(lhs, 2));
        void'(int_set_util_t::insert(rhs, 2));
        void'(int_set_util_t::insert(rhs, 3));

        check_true(int_set_util_t::equals(lhs, lhs),
                   "set_util::equals should pass for identical sets");
        check_true(!int_set_util_t::equals(lhs, rhs),
                   "set_util::equals should fail for different sets");
        check_true(!int_set_util_t::contains(lhs, rhs),
                   "set_util::contains should reject superset rhs");

        int_set_util_t::union_into(lhs, rhs, result);
        check_true(int_set_util_t::count(result, 1) == 1 &&
                   int_set_util_t::count(result, 2) == 1 &&
                   int_set_util_t::count(result, 3) == 1,
                   "set_util::union_into should produce the union");

        exact = int_set_util_t::get_intersect(lhs, rhs);
        check_true(exact.size() == 1 && int_set_util_t::count(exact, 2) == 1,
                   "set_util::get_intersect should return shared elements");

        exact = int_set_util_t::get_diff(lhs, rhs);
        check_true(exact.size() == 1 && int_set_util_t::count(exact, 1) == 1,
                   "set_util::get_diff should return lhs-only elements");
    endtask

    // -----------------------------------------------------------------------
    // 2. set_array_util
    // -----------------------------------------------------------------------
    task automatic test_set_array_util();
        typedef set_array_util#(int unsigned, 4) int_set_array_util_t;
        typedef int_set_array_util_t::set_array_t int_set_array_t;
        int_set_array_t lhs, rhs, result, exact;

        void'(int_set_array_util_t::elem_util::insert(lhs[0], 1));
        void'(int_set_array_util_t::elem_util::insert(lhs[0], 2));
        void'(int_set_array_util_t::elem_util::insert(lhs[1], 10));
        void'(int_set_array_util_t::elem_util::insert(rhs[0], 2));
        void'(int_set_array_util_t::elem_util::insert(rhs[0], 3));
        void'(int_set_array_util_t::elem_util::insert(rhs[2], 20));

        check_true(int_set_array_util_t::equals(lhs, lhs),
                   "set_array_util::equals should pass for identical arrays");
        check_true(!int_set_array_util_t::equals(lhs, rhs),
                   "set_array_util::equals should fail for different arrays");

        int_set_array_util_t::union_into(lhs, rhs, result);
        check_true(int_set_array_util_t::elem_util::count(result[0], 1) == 1 &&
                   int_set_array_util_t::elem_util::count(result[0], 3) == 1,
                   "set_array_util::union_into should merge per slot");

        exact = int_set_array_util_t::get_intersect(lhs, rhs);
        check_true(int_set_array_util_t::elem_util::count(exact[0], 2) == 1,
                   "set_array_util::get_intersect should keep shared slot content");

        int_set_array_util_t::diff_with(lhs, rhs);
        check_true(int_set_array_util_t::elem_util::count(lhs[0], 1) == 1,
                   "set_array_util::diff_with should keep lhs-only slot content");
    endtask

    // -----------------------------------------------------------------------
    // 3. aa_util
    // -----------------------------------------------------------------------
    task automatic test_aa_util();
        typedef aa_util#(int unsigned, int unsigned) int_aa_util_t;
        typedef int_aa_util_t::aa_t int_aa_t;
        typedef int_aa_util_t::key_set_t int_key_set_t;
        int_aa_t lhs, rhs, result, merged;
        int_key_set_t required;

        lhs[1] = 10;
        lhs[2] = 20;
        rhs[2] = 99;
        rhs[3] = 30;

        check_true(int_aa_util_t::equals(lhs, lhs),
                   "aa_util::equals should pass for identical maps");
        check_true(!int_aa_util_t::contains(lhs, rhs),
                   "aa_util::contains should reject rhs with different shared-key value");

        int_aa_util_t::merge_into(lhs, rhs, result);
        check_true(result[1] == 10 && result[2] == 99 && result[3] == 30,
                   "aa_util::merge_into should union keys and let rhs overwrite shared");

        result = int_aa_util_t::get_intersect(lhs, rhs);
        check_true(result.size() == 1 && result[2] == 20,
                   "aa_util::get_intersect should keep shared keys with lhs value");

        result = int_aa_util_t::get_diff(lhs, rhs);
        check_true(result.size() == 1 && result[1] == 10,
                   "aa_util::get_diff should keep lhs-only keys");

        merged = int_aa_util_t::get_merge(lhs, rhs);
        required[1] = 1'b1;
        required[3] = 1'b1;
        check_true(int_aa_util_t::contains_keys(merged, required),
                   "aa_util::contains_keys should accept key subsets");
    endtask

    // -----------------------------------------------------------------------
    // 4. aa_array_util
    // -----------------------------------------------------------------------
    task automatic test_aa_array_util();
        typedef aa_array_util#(4, int unsigned, int unsigned) int_aa_array_util_t;
        typedef int_aa_array_util_t::aa_array_t int_aa_array_t;
        typedef int_aa_array_util_t::key_set_array_t int_key_set_array_t;
        int_aa_array_t lhs, rhs, result;
        int_key_set_array_t key_sets;

        lhs[0][1] = 10;
        lhs[0][2] = 20;
        lhs[1][4] = 40;
        rhs[0][2] = 99;
        rhs[1][5] = 50;

        check_true(int_aa_array_util_t::equals(lhs, lhs),
                   "aa_array_util::equals should pass for identical arrays");

        int_aa_array_util_t::merge_into(lhs, rhs, result);
        check_true(result[0][1] == 10 && result[0][2] == 99 && result[1][5] == 50,
                   "aa_array_util::merge_into should merge per bank");

        result = int_aa_array_util_t::get_intersect(lhs, rhs);
        check_true(result[0].size() == 1 && result[0][2] == 20,
                   "aa_array_util::get_intersect should keep shared bank keys");

        int_aa_array_util_t::diff_with(lhs, rhs);
        check_true(lhs[0].size() == 1 && lhs[0][1] == 10,
                   "aa_array_util::diff_with should keep lhs-only bank keys");

        key_sets = int_aa_array_util_t::get_keys(lhs);
        check_true(int_aa_array_util_t::elem_util::key_set_util::count(key_sets[0], 1) == 1,
                   "aa_array_util::get_keys should return per-bank key sets");
    endtask

    // -----------------------------------------------------------------------
    // 5. aa_of_q_util
    // -----------------------------------------------------------------------
    task automatic test_aa_of_q_util();
        typedef aa_of_q_util#(int unsigned, int unsigned) int_aa_of_q_util_t;
        typedef int_aa_of_q_util_t::aa_of_q_t int_aa_of_q_t;
        typedef int_aa_of_q_util_t::key_set_t int_key_set_t;
        typedef int_aa_of_q_util_t::val_set_t int_val_set_t;
        int_aa_of_q_t lhs, rhs, result;
        int_key_set_t keys;
        int_val_set_t values;
        bit inserted;

        void'(int_aa_of_q_util_t::insert(lhs, 1, 10));
        void'(int_aa_of_q_util_t::insert(lhs, 1, 20));
        void'(int_aa_of_q_util_t::insert(lhs, 2, 30));
        void'(int_aa_of_q_util_t::insert(rhs, 2, 31));
        void'(int_aa_of_q_util_t::insert(rhs, 3, 40));

        check_true(int_aa_of_q_util_t::equals(lhs, lhs),
                   "aa_of_q_util::equals should pass for identical multimaps");

        inserted = int_aa_of_q_util_t::insert(lhs, 1, 20);
        check_true(!inserted,
                   "aa_of_q_util::insert should reject duplicate when UNIQUE_ELEM==1");

        int_aa_of_q_util_t::merge_into(lhs, rhs, result);
        check_true(result.exists(1) && result.exists(2) && result.exists(3),
                   "aa_of_q_util::merge_into should union visible keys");

        int_aa_of_q_util_t::intersect_into(lhs, rhs, result);
        check_true(result.exists(2),
                   "aa_of_q_util::intersect_into should keep shared keys");

        int_aa_of_q_util_t::diff_into(lhs, rhs, result);
        check_true(result.exists(1),
                   "aa_of_q_util::diff_into should keep lhs-only keys");

        lhs[5] = {};
        int_aa_of_q_util_t::clean(lhs);
        check_true(!lhs.exists(5),
                   "aa_of_q_util::clean should remove empty-queue keys");

        keys = int_aa_of_q_util_t::get_keys(lhs);
        check_true(int_aa_of_q_util_t::key_set_util::count(keys, 1) == 1,
                   "aa_of_q_util::get_keys should return visible keys");

        values = int_aa_of_q_util_t::get_values(lhs);
        check_true(values.size() > 0,
                   "aa_of_q_util::get_values should return flattened visible values");
    endtask

    // -----------------------------------------------------------------------
    // 6. aa_of_q_array_util
    // -----------------------------------------------------------------------
    task automatic test_aa_of_q_array_util();
        typedef aa_of_q_array_util#(4, int unsigned, int unsigned) int_aa_of_q_array_util_t;
        typedef int_aa_of_q_array_util_t::aa_of_q_array_t int_aa_of_q_array_t;
        typedef int_aa_of_q_array_util_t::key_set_array_t int_key_set_array_t;
        typedef int_aa_of_q_array_util_t::val_set_array_t int_val_set_array_t;
        int_aa_of_q_array_t lhs, rhs, result;
        int_key_set_array_t key_sets;
        int_val_set_array_t val_sets;

        lhs[0][1] = {10, 20};
        lhs[1][2] = {30};
        rhs[1][2] = {31};
        rhs[2][3] = {40};

        check_true(int_aa_of_q_array_util_t::equals(lhs, lhs),
                   "aa_of_q_array_util::equals should pass for identical arrays");

        int_aa_of_q_array_util_t::merge_into(lhs, rhs, result);
        check_true(result[0].exists(1) && result[1].exists(2) && result[2].exists(3),
                   "aa_of_q_array_util::merge_into should merge per bank");

        int_aa_of_q_array_util_t::intersect_into(lhs, rhs, result);
        check_true(result[1].exists(2),
                   "aa_of_q_array_util::intersect_into should keep shared bank keys");

        int_aa_of_q_array_util_t::diff_into(lhs, rhs, result);
        check_true(result[0].exists(1),
                   "aa_of_q_array_util::diff_into should keep lhs-only bank keys");

        lhs[3][7] = {};
        int_aa_of_q_array_util_t::clean(lhs);
        check_true(!lhs[3].exists(7),
                   "aa_of_q_array_util::clean should remove empty-queue keys per bank");

        key_sets = int_aa_of_q_array_util_t::get_keys(lhs);
        check_true(int_aa_of_q_array_util_t::elem_util::key_set_util::count(key_sets[0], 1) == 1,
                   "aa_of_q_array_util::get_keys should return per-bank key sets");

        val_sets = int_aa_of_q_array_util_t::get_value_sets(lhs);
        check_true(val_sets[0].size() > 0,
                   "aa_of_q_array_util::get_value_sets should return per-bank value sets");
    endtask

    // -----------------------------------------------------------------------
    // 7. aa_value_adapter_util
    // -----------------------------------------------------------------------
    task automatic test_aa_value_adapter_util();
        typedef aa_value_adapter_util#(int unsigned, int unsigned) int_adapter_util_t;
        typedef int_adapter_util_t::aa_of_q_t int_aa_of_q_t;
        typedef int_adapter_util_t::aa_t int_aa_t;
        int_aa_of_q_t lhs, result;
        int_aa_t rhs, projected;
        int_aa_of_q_t lifted;

        lhs[1] = {10, 20};
        lhs[2] = {30};
        lhs[3] = {50};
        rhs[1] = 20;
        rhs[3] = 50;

        check_true(int_adapter_util_t::contains(lhs, rhs),
                   "aa_value_adapter_util::contains should accept scalar values in queue view");

        rhs[2] = 99;
        check_true(!int_adapter_util_t::contains(lhs, rhs),
                   "aa_value_adapter_util::contains should reject absent values");

        int_adapter_util_t::merge_into(lhs, rhs, result);
        check_true(result.exists(1) && result.exists(2) && result.exists(3),
                   "aa_value_adapter_util::merge_into should union keys across shapes");

        int_adapter_util_t::intersect_into(lhs, rhs, result);
        check_true(result.exists(1),
                   "aa_value_adapter_util::intersect_into should keep shared keys");

        int_adapter_util_t::diff_into(lhs, rhs, result);
        check_true(result.exists(2),
                   "aa_value_adapter_util::diff_into should keep lhs-only keys");

        lhs[1] = {10};
        lhs[2] = {20};
        projected = int_adapter_util_t::to_aa(lhs);
        check_true(projected[1] == 10 && projected[2] == 20,
                   "aa_value_adapter_util::to_aa should extract singleton values");

        lifted = int_adapter_util_t::to_aa_of_q(projected);
        check_true(lifted[1].size() == 1 && lifted[1][0] == 10,
                   "aa_value_adapter_util::to_aa_of_q should lift into singleton queues");
    endtask

    // -----------------------------------------------------------------------
    // 8. aa_value_adapter_array_util
    // -----------------------------------------------------------------------
    task automatic test_aa_value_adapter_array_util();
        typedef aa_value_adapter_array_util#(4, int unsigned, int unsigned) int_adapter_array_util_t;
        typedef int_adapter_array_util_t::aa_of_q_array_t int_aa_of_q_array_t;
        typedef int_adapter_array_util_t::aa_array_t int_aa_array_t;
        int_aa_of_q_array_t lhs, result;
        int_aa_array_t rhs, projected;
        int_aa_of_q_array_t lifted;

        lhs[0][1] = {10, 20};
        lhs[1][2] = {30};
        lhs[1][3] = {50};
        rhs[0][1] = 20;
        rhs[1][3] = 50;

        check_true(int_adapter_array_util_t::contains(lhs, rhs),
                   "aa_value_adapter_array_util::contains should accept per-bank scalar values");

        int_adapter_array_util_t::merge_into(lhs, rhs, result);
        check_true(result[0].exists(1) && result[1].exists(2) && result[1].exists(3),
                   "aa_value_adapter_array_util::merge_into should merge per bank");

        int_adapter_array_util_t::intersect_into(lhs, rhs, result);
        check_true(result[0].exists(1),
                   "aa_value_adapter_array_util::intersect_into should keep shared bank keys");

        int_adapter_array_util_t::diff_into(lhs, rhs, result);
        check_true(result[1].exists(2),
                   "aa_value_adapter_array_util::diff_into should keep lhs-only bank keys");

        lhs[0][1] = {10};
        lhs[1][2] = {20};
        projected = int_adapter_array_util_t::to_aa(lhs);
        check_true(projected[0][1] == 10 && projected[1][2] == 20,
                   "aa_value_adapter_array_util::to_aa should extract per-bank singleton values");

        lifted = int_adapter_array_util_t::to_aa_of_q(projected);
        check_true(lifted[0][1].size() == 1 && lifted[0][1][0] == 10,
                   "aa_value_adapter_array_util::to_aa_of_q should lift per-bank into singleton queues");
    endtask

    initial begin
        test_set_util();
        test_set_array_util();
        test_aa_util();
        test_aa_array_util();
        test_aa_of_q_util();
        test_aa_of_q_array_util();
        test_aa_value_adapter_util();
        test_aa_value_adapter_array_util();

        $display("collection_smoke_tb: PASS");
        $finish;
    end
endmodule
