`ifndef __SET_UTIL_SVH__
`define __SET_UTIL_SVH__

// set_util
// --------
// 基于原生关联数组表示的集合工具类。
//
// 设计目标：
// 1. `set_t` 对外仍然是一个普通的 SystemVerilog 关联数组，可以直接使用
//    `foreach`、`exists`、`delete`、`size` 等原生语法。
// 2. 用户通过 `set_util::set_t` 获取集合类型，而不需要关心底层实现细节。
// 3. `*_into()` 采用“插入到 result”语义，不会清空 `result` 既有内容。
//
// 提供的接口：
//   insert / delete / contains_key / contains_set
//   to_queue / to_aa
//   union_into / get_union / union_with
//   intersect_into / get_intersect / intersect_with
//   diff_into / get_diff / diff_with
class set_util #(type KEY_T = logic [31:0]);
    typedef bit set_t[KEY_T];
    typedef KEY_T q_of_data[$];
    typedef bit aa_of_data[KEY_T];

`include "set_util_impl.svh"

endclass

`endif
