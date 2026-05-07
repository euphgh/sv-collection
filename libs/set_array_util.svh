`ifndef __SET_ARRAY_UTIL_SVH__
`define __SET_ARRAY_UTIL_SVH__

`include "set_util.svh"

// set_array_util
// --------------
// 固定大小的 array-of-set 工具类。
//
// 设计约定：
// 1. `set_array_t[index]` 是一个普通 `set_t`，每个槽位彼此独立。
// 2. 整体集合运算按索引逐项执行，对应槽位调用 `set_util` 的同名操作。
// 3. `*_into()` 语义与 `set_util` 保持一致：逐项把结果插入到 `result[index]`，
//    不会清空该槽位原有内容。
class set_array_util #(type DATA_T = int, int SIZE = 32, bit UNIQUE_ELEM = 1);
    typedef set_util#(DATA_T, UNIQUE_ELEM) set_elem_util_t;
    typedef set_elem_util_t::set_t set_t;
    typedef set_t set_array_t[SIZE];

    // 在指定槽位插入一个元素。
    static function void insert(ref set_array_t set_aa, input int index, input DATA_T key);
        set_elem_util_t::insert(set_aa[index], key);
    endfunction : insert

    // 在指定槽位删除一个元素。
    static function void delete(ref set_array_t set_aa, input int index, input DATA_T key);
        set_elem_util_t::delete(set_aa[index], key);
    endfunction : delete

    // 判断指定槽位是否包含某个 key。
    static function bit count(const ref set_array_t set_aa, input int index, input DATA_T key);
        return set_elem_util_t::count(set_aa[index], key);
    endfunction : count

    // 判断指定槽位是否包含一个子集。
    static function bit contains_at(const ref set_array_t set_aa, input int index, const ref set_t subset);
        return set_elem_util_t::contains(set_aa[index], subset);
    endfunction : contains_at

    // 判断 lhs 是否包含 rhs 数组中对应每个槽位的集合。
    static function bit contains(const ref set_array_t set_aa, const ref set_array_t rhs);
        foreach (rhs[i]) begin
            if (!set_elem_util_t::contains_set(set_aa[i], rhs[i]))
                return 0;
        end
        return 1;
    endfunction : contains

    // 判断两个 set-array 是否逐槽位完全相等。
    static function bit equals(const ref set_array_t a, const ref set_array_t b);
        for (int i = 0; i < SIZE; i++) begin
            if (!set_elem_util_t::equals(a[i], b[i]))
                return 0;
        end
        return 1;
    endfunction : equals

    // 逐槽位把 lhs 和 rhs 的并集插入 result。
    static function void union_into(const ref set_array_t lhs, const ref set_array_t rhs, ref set_array_t result);
        for (int i = 0; i < SIZE; i++)
            set_elem_util_t::union_into(lhs[i], rhs[i], result[i]);
    endfunction : union_into

    // 返回一个新的逐槽位并集结果。
    static function set_array_t get_union(const ref set_array_t lhs, const ref set_array_t rhs);
        set_array_t result;

        union_into(lhs, rhs, result);
        return result;
    endfunction : get_union

    // 原地逐槽位并集。
    static function void union_with(ref set_array_t lhs, const ref set_array_t rhs);
        for (int i = 0; i < SIZE; i++)
            set_elem_util_t::union_with(lhs[i], rhs[i]);
    endfunction : union_with

    // 逐槽位把交集插入 result。
    static function void intersect_into(const ref set_array_t lhs, const ref set_array_t rhs, ref set_array_t result);
        for (int i = 0; i < SIZE; i++)
            set_elem_util_t::intersect_into(lhs[i], rhs[i], result[i]);
    endfunction : intersect_into

    // 返回一个新的逐槽位交集结果。
    static function set_array_t get_intersect(const ref set_array_t lhs, const ref set_array_t rhs);
        set_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地逐槽位交集。
    static function void intersect_with(ref set_array_t lhs, const ref set_array_t rhs);
        for (int i = 0; i < SIZE; i++)
            set_elem_util_t::intersect_with(lhs[i], rhs[i]);
    endfunction : intersect_with

    // 逐槽位把差集插入 result。
    static function void diff_into(const ref set_array_t lhs, const ref set_array_t rhs, ref set_array_t result);
        for (int i = 0; i < SIZE; i++)
            set_elem_util_t::diff_into(lhs[i], rhs[i], result[i]);
    endfunction : diff_into

    // 返回一个新的逐槽位差集结果。
    static function set_array_t get_diff(const ref set_array_t lhs, const ref set_array_t rhs);
        set_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    // 原地逐槽位差集。
    static function void diff_with(ref set_array_t lhs, const ref set_array_t rhs);
        for (int i = 0; i < SIZE; i++)
            set_elem_util_t::diff_with(lhs[i], rhs[i]);
    endfunction : diff_with

    // 返回格式化字符串，便于观察每个槽位的集合内容。
    static function string sprint(const ref set_array_t set_aa, input string name = "set_array");
        string s;

        s = $sformatf("%s = '{", name);
        for (int i = 0; i < SIZE; i++)
            s = {s, $sformatf("\n  [%0d]: %p", i, set_aa[i])};
        s = {s, "\n}"};

        return s;
    endfunction : sprint

    // 直接打印格式化后的 array-of-set 内容。
    static function void print(const ref set_array_t set_aa, input string name = "set_array");
        $display("%s", sprint(set_aa, name));
    endfunction : print
endclass

`endif
