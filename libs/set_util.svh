`ifndef __SET_UTIL_SVH__
`define __SET_UTIL_SVH__

// set_util
// --------
// 基于 queue 的集合工具类，使用 SystemVerilog 内建数组操作方法。
//
// 设计目标：
// 1. `set_t` 是 `KEY_T[$]`，即普通的 SystemVerilog queue。
//    所有集合语义（去重、查找、删除）由本工具类保证，
//    用户不应直接操作底层 queue 的索引。
// 2. `*_into()` 采用"插入到 result"语义，不会清空 `result` 既有内容。
//
// 提供的接口：
//   insert / delete / count / contains / equals
//   union_into / get_union / union_with
//   intersect_into / get_intersect / intersect_with
//   diff_into / get_diff / diff_with
// 
// 参数要求：
// 1. KEY_T 是可以使用==比较的二态数据类型
class set_util #(type KEY_T = real, bit UNIQUE_ELEM = 1);
    typedef KEY_T set_t[$];

    static function int count(const ref set_t set, input KEY_T key);
        set_t found;
        found = set.find(item) with (item == key);
        return found.size();
    endfunction : count

    static function bit contains(const ref set_t lhs, const ref set_t rhs);
        foreach (rhs[i])
            if (count(lhs, rhs[i]) == 0)
                return 0;
        return 1;
    endfunction : contains

    static function bit _has(const ref set_t set, input KEY_T key);
        return count(set, key) != 0;
    endfunction : _has

    /**
     * insert key into set, return 1 if insertion is successful, otherwise return 0;
     * if UNIQUE_ELEM is 1, only insert when key not exist in set, otherwise push_back key to set directly.
     * @param set the set to insert into
     * @param key the key to insert
     * @return 1 if insertion is successful, otherwise return 0
     */
    static function bit insert(ref set_t set, input KEY_T key);

        if (UNIQUE_ELEM) begin
            if (count(set, key) == 0) begin
                set.push_back(key);
                return 1;
            end
            return 0; // Key already exists, insertion failed
        end
        else begin
            set.push_back(key);
            return 1;
        end
    endfunction : insert

    static function void delete(ref set_t set, input KEY_T key);
        int found_idx[$];
        found_idx = set.find_index(item) with (item == key);
        foreach(found_idx[i]) begin
            set.delete(found_idx[i]);
        end
    endfunction : delete

    static function bit equals(const ref set_t lhs, const ref set_t rhs);
        set_t l_tmp;
        set_t r_tmp;
        if (lhs.size() != rhs.size())
            return 0;
        l_tmp = lhs;
        r_tmp = rhs;
        l_tmp.sort();
        r_tmp.sort();
        foreach (l_tmp[i])
            if (l_tmp[i] != r_tmp[i])
                return 0;
        return 1;
    endfunction : equals

    static function void union_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
        foreach (lhs[i])
            if (!_has(result, lhs[i]))
                result.push_back(lhs[i]);
        foreach (rhs[i])
            if (!_has(result, rhs[i]))
                result.push_back(rhs[i]);
    endfunction : union_into

    static function set_t get_union(const ref set_t lhs, const ref set_t rhs);
        set_t result;
        union_into(lhs, rhs, result);
        return result;
    endfunction : get_union

    static function void union_with(ref set_t lhs, const ref set_t rhs);
        foreach (rhs[i])
            if (!_has(lhs, rhs[i]))
                lhs.push_back(rhs[i]);
    endfunction : union_with

    static function void intersect_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
        foreach (lhs[i])
            if (_has(rhs, lhs[i]) && !_has(result, lhs[i]))
                result.push_back(lhs[i]);
    endfunction : intersect_into

    static function set_t get_intersect(const ref set_t lhs, const ref set_t rhs);
        set_t result;
        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    static function void intersect_with(ref set_t lhs, const ref set_t rhs);
        set_t tmp;
        intersect_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : intersect_with

    static function void diff_into(const ref set_t lhs, const ref set_t rhs, ref set_t result);
        foreach (lhs[i])
            if (!_has(rhs, lhs[i]) && !_has(result, lhs[i]))
                result.push_back(lhs[i]);
    endfunction : diff_into

    static function set_t get_diff(const ref set_t lhs, const ref set_t rhs);
        set_t result;
        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    static function void diff_with(ref set_t lhs, const ref set_t rhs);
        set_t tmp;
        diff_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : diff_with

endclass

`endif
