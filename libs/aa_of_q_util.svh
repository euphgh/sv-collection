`ifndef __AA_OF_Q_UTIL_SVH__
`define __AA_OF_Q_UTIL_SVH__

`include "aa_util.svh"

// aa_of_q_util
// -------
// 关联数组嵌套queue的工具类，面向 multimap 容器场景。
//
// 设计约定：
// 1. 与aa_util类似，所有集合运算都以 key 为集合元素，value是一个queue of VAL_T。
// 2. queue of VAL_T可以看做一个set_t，使用set_util中的函数，对queue的修改统一调用set_util函数，不要直接修改底层容器
// 3. `merge` 语义为 key 并集；当 key 都存在时，value 为`rhs` union `lhs`。
// 4. `intersect` / `diff` 语义都基于 key；返回结果 value 为 `rhs` intersect/diff `lhs`
// 5. `*_into()` 会完整覆写 `result`。
// 6. 只读入参统一使用 `const ref`，避免大关联数组的隐式拷贝。
// 7. 在向aa中插入一个新的<key, queue>的时候，注意，如果key不存在，aa[key]的读操作不会自动插入一个queue，而是返回一个空的queue。
//
// 提供接口：
// 1. mutate:
//    insert：仅插入一个元素，调用set的insert操作
//    merge: merge_into / get_merge / merge_with
//    intersect: intersect_into / get_intersect / intersect_with
//    diff: diff_into / get_diff / diff_with
//    clean: 清除value是空队列的key，处理diff和intersect的特殊情况。
// 2. observe:
//   equals / contains / contains_key_set / has_value
//   get_keys / get_values
// 
// 参数要求： 同aa_util
class aa_of_q_util #(type KEY_T = logic [7:0], type VAL_T = logic [31:0], bit UNIQUE_ELEM = 1);
    typedef VAL_T val_q_t[$];
    typedef set_util#(VAL_T, UNIQUE_ELEM) val_set_util;
    typedef val_q_t aa_of_q_t[KEY_T];

    static function bit equals(const ref aa_of_q_t a, const ref aa_of_q_t b);
        if (a.num() != b.num())
            return 0;

        foreach (a[k]) begin
            if (!b.exists(k))
                return 0;
            if (!val_set_util::equals(a[k], b[k]))
                return 0;
        end

        return 1;
    endfunction

    static function bit contains(const ref aa_of_q_t lhs, const ref aa_of_q_t rhs);
        foreach (rhs[key]) begin
            if (!lhs.exists(key))
                return 0;
            foreach (rhs[key][i]) begin
                 if (val_set_util::count(lhs[key], rhs[key][i]) == 0)
                    return 0;
            end
        end
        return 1;
    endfunction : contains
endclass

`endif

