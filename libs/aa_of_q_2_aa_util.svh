`ifndef __AA_OF_Q_2_AA_UTIL_SVH__
`define __AA_OF_Q_2_AA_UTIL_SVH__

`include "aa_of_q_util.svh"

// aa_of_q_2_aa_util
// -------
// 关联数组嵌套queue的工具类，面向 multimap 和 map 混合容器场景。
// 面向的场景是 aa_of_q_t 和 aa_t 的集合操作和逻辑操作。
// 所有函数的第一个参数都是 aa_of_q_util 类型，表示操作的另一个集合，函数语义与 aa_of_q_util 中同名函数类似，但 rhs 类型不同，rhs 是 aa_t 而不是 aa_of_q_t。
//
// 设计约定：
// 1. queue of VAL_T可以看做一个set_t，使用set_util中的函数，对queue的修改统一调用set_util函数，不要直接修改底层容器
// 2. `*_into()` 会完整覆写 `result`。
// 3. 只读入参统一使用 `const ref`，避免大关联数组的隐式拷贝。
// 4. 在向aa_of_q中插入一个新的<key, queue>的时候，注意如果key不存在，aa[key]的读操作不会自动插入一个queue，而是返回一个空的queue。
class aa_of_q_2_aa_util #(type KEY_T = int, type VAL_T = real, bit UNIQUE_ELEM = 1);
    typedef VAL_T val_t;
    typedef set_util#(VAL_T, UNIQUE_ELEM) val_set_util;
    typedef val_set_util::set_t val_set_t[$];

    typedef aa_util#(KEY_T, val_t) this_aa_util;
    typedef this_aa_util::aa_t aa_t;

    typedef aa_of_q_util#(KEY_T, val_t) this_aa_of_q_util;
    typedef this_aa_of_q_util::aa_of_q_t aa_of_q_t;

    static function bit contains(const ref aa_of_q_t a, const ref aa_t b);
        foreach (b[key]) begin
            if (!a.exists(key))
                return 0;
            if (!val_set_util::contains(a[key], b[key]))
                return 0;
        end
        return 1;
    endfunction : contains

    // `merge` 语义为 key 并集；当 key 都存在时，value 为`set_util::insert(lhs[key], rhs[key])`
    static function void merge_with(ref aa_of_q_t aa_of_q, const ref aa_t aa);
    endfunction
    static function aa_of_q_t get_merge(ref aa_of_q_t aa_of_q, const ref aa_t aa);
    endfunction
    static function void merge_into(ref aa_of_q_t aa_of_q, const ref aa_t aa, ref aa_of_q_t res);
    endfunction

    // intersect_with / get_intersect / intersect_into 的语义：以 aa_of_q 的 key 为基准，如果 aa 中存在相同的 key，则比较 value 是否存在交集，如果存在交集，则结果中的 value 为 {aa[key]}，否则是一个空的 queue。
    static function void intersect_with(ref aa_of_q_t aa_of_q, const ref aa_t aa);
    endfunction
    static function aa_of_q_t get_intersect(ref aa_of_q_t aa_of_q, const ref aa_t aa);
    endfunction
    static function void intersect_into(ref aa_of_q_t aa_of_q, const ref aa_t aa, ref aa_of_q_t res);
    endfunction

    // `diff` 语义都基于 key；返回结果 value 为 set_util::delete(lhs[key], rhs[key])
    static function void diff_with(ref aa_of_q_t aa_of_q, const ref aa_t aa);
    endfunction
    static function aa_of_q_t get_diff(ref aa_of_q_t aa_of_q, const ref aa_t aa);
    endfunction
    static function void diff_into(ref aa_of_q_t aa_of_q, const ref aa_t aa, ref aa_of_q_t res);
    endfunction

    // 用户需要自己保证 aa_of_q 中的 queue 中只有一个元素
    static function aa_t to_aa(const ref aa_of_q_t aa_of_q);
        aa_t res;
        foreach (aa_of_q[key]) begin
            if (aa_of_q[key].num() > 0)
                res[key] = aa_of_q[key][0];
        end
        return res;
    endfunction

    static function aa_of_q_t to_aa_of_q(const ref aa_t aa);
        aa_of_q_t res;
        foreach (aa[key]) begin
            res[key] = {aa[key]};
        end
        return res;
    endfunction
endclass

`endif