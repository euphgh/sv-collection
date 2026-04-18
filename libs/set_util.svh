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

    // 插入一个元素。集合底层是关联数组，因此重复插入天然是 no-op。
    static function void insert(ref set_t set, input KEY_T key);
        set[key] = 1'b1;
    endfunction : insert

    // 删除一个元素。若 key 不存在，关联数组的 delete 也会安静返回。
    static function void delete(ref set_t set, input KEY_T key);
        set.delete(key);
    endfunction : delete

    // 判断单个元素是否存在于集合中。
    static function bit contains_key(const ref set_t set, input KEY_T key);
        return set.exists(key);
    endfunction : contains_key

    // 判断 rhs 是否为 lhs 的子集，只需要逐个检查 rhs 中的 key。
    static function bit contains_set(const ref set_t lhs, const ref set_t rhs);
        foreach (rhs[key]) begin
            if (!lhs.exists(key))
                return 0;
        end

        return 1;
    endfunction : contains_set

    // 将集合拷贝成 queue，顺序遵循关联数组的遍历顺序。
    static function q_of_data to_queue(const ref set_t lhs);
        q_of_data result;

        result.delete();
        foreach (lhs[key])
            result.push_back(key);

        return result;
    endfunction : to_queue

    // 返回底层关联数组视图的副本，便于与原生 SV 代码交互。
    static function aa_of_data to_aa(const ref set_t lhs);
        return lhs;
    endfunction : to_aa

    // 将 lhs 和 rhs 的全部元素插入 result，不覆盖 result 先前已有的其他元素。
    static function void union_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
        foreach (lhs[key])
            result[key] = 1'b1;

        foreach (rhs[key])
            result[key] = 1'b1;
    endfunction : union_into

    // 构造一个纯净的新集合并返回并集结果。
    static function set_t get_union(const ref set_t lhs, const ref set_t rhs);
        set_t result;

        union_into(lhs, rhs, result);
        return result;
    endfunction : get_union

    // 原地并集，本质上就是把 rhs 的 key 全部写回 lhs。
    static function void union_with(ref set_t lhs, const ref set_t rhs);
        foreach (rhs[key])
            lhs[key] = 1'b1;
    endfunction : union_with

    // 只把同时出现在 lhs 和 rhs 中的 key 插入 result。
    static function void intersect_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
        foreach (lhs[key]) begin
            if (rhs.exists(key))
                result[key] = 1'b1;
        end
    endfunction : intersect_into

    // 构造一个纯净的新集合并返回交集结果。
    static function set_t get_intersect(const ref set_t lhs, const ref set_t rhs);
        set_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地交集不能边遍历边删，所以先收集待删 key，再统一删除。
    static function void intersect_with(ref set_t lhs, const ref set_t rhs);
        q_of_data keys_to_delete;

        foreach (lhs[key]) begin
            if (!rhs.exists(key))
                keys_to_delete.push_back(key);
        end

        foreach (keys_to_delete[i])
            lhs.delete(keys_to_delete[i]);
    endfunction : intersect_with

    // 只把 lhs 独有的 key 插入 result。
    static function void diff_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
        foreach (lhs[key]) begin
            if (!rhs.exists(key))
                result[key] = 1'b1;
        end
    endfunction : diff_into

    // 构造一个纯净的新集合并返回差集结果。
    static function set_t get_diff(const ref set_t lhs, const ref set_t rhs);
        set_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    // 原地差集同样采用“先收集、后删除”，避免遍历时修改容器。
    static function void diff_with(ref set_t lhs, const ref set_t rhs);
        q_of_data keys_to_delete;

        foreach (lhs[key]) begin
            if (rhs.exists(key))
                keys_to_delete.push_back(key);
        end

        foreach (keys_to_delete[i])
            lhs.delete(keys_to_delete[i]);
    endfunction : diff_with

endclass

`endif
