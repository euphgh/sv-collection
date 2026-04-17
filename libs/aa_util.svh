`ifndef __AA_UTIL_SVH__
`define __AA_UTIL_SVH__

`include "set_util.svh"

// aa_util
// -------
// 关联数组工具类，面向 map-like 容器场景。
//
// 设计约定：
// 1. 所有集合运算都以 key 为集合元素，value 视为附带 payload。
// 2. `merge` 语义为 key 并集；当 key 冲突时，`rhs` 覆盖 `lhs`。
// 3. `intersect` / `diff` 语义都基于 key；返回结果中的 value 一律来自 `lhs`。
// 4. `*_into()` 会完整覆写 `result`。
// 5. 只读入参统一使用 `const ref`，避免大关联数组的隐式拷贝。
//
// 提供的接口：
//   sprint / print
//   equals / equals_verbose
//   contains / contains_keys / has_key / has_value
//   merge_into / get_merge / merge_with
//   intersect_into / get_intersect / intersect_with / get_intersect_merge_with
//   diff_into / get_diff / diff_with
//   get_keys / get_values
class aa_util #(type KEY_T = logic [7:0], type VAL_T = logic [7:0]);
    typedef VAL_T aa_t[KEY_T];

    typedef set_util#(KEY_T) key_set_util;
    typedef set_util#(VAL_T) val_set_util;
    typedef key_set_util::set_t key_set_t;
    typedef val_set_util::set_t val_set_t;

`include "aa_util_impl.svh"

endclass

`endif
