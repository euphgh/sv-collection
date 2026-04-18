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

    // 返回格式化字符串，默认最多展开前 100 项，避免日志失控。
    static function string sprint(const ref aa_t aa, input string name = "aa");
        string s;
        int cnt = 0;

        if (aa.size() == 0)
            return $sformatf("%s = '{}  // empty, size=0", name);

        s = $sformatf("%s = '{  // size=%0d", name, aa.size());
        foreach (aa[k]) begin
            s = {s, $sformatf("\n  [%p]: %p", k, aa[k])};
            cnt++;
            if (cnt >= 100) begin
                s = {s, $sformatf("\n  ... (%0d more entries)", aa.size() - cnt)};
                break;
            end
        end

        s = {s, "\n}"};
        return s;
    endfunction : sprint

    // 直接打印格式化后的关联数组内容。
    static function void print(const ref aa_t aa, input string name = "aa");
        $display("%s", sprint(aa, name));
    endfunction : print

    // 严格比较 key 集和 value，value 使用 `!==` 以保留 X/Z 语义。
    static function bit equals(const ref aa_t a, const ref aa_t b);
        if (a.size() != b.size())
            return 0;

        foreach (a[k]) begin
            if (!b.exists(k))
                return 0;
            if (a[k] !== b[k])
                return 0;
        end

        return 1;
    endfunction : equals

    // 逐项收集差异信息，便于 testbench 或日志直接打印定位问题。
    static function bit equals_verbose(
        const ref aa_t a,
        const ref aa_t b,
        input string name_a = "a",
        input string name_b = "b",
        output string diff
    );
        int mismatch_cnt = 0;
        string s = "";

        diff = "";

        foreach (a[k]) begin
            if (!b.exists(k)) begin
                s = {s, $sformatf("\n  [%p]: only in %s = %p", k, name_a, a[k])};
                mismatch_cnt++;
            end
            else if (a[k] !== b[k]) begin
                s = {s, $sformatf("\n  [%p]: %s=%p, %s=%p", k, name_a, a[k], name_b, b[k])};
                mismatch_cnt++;
            end
        end

        foreach (b[k]) begin
            if (!a.exists(k)) begin
                s = {s, $sformatf("\n  [%p]: only in %s = %p", k, name_b, b[k])};
                mismatch_cnt++;
            end
        end

        if (mismatch_cnt > 0) begin
            diff = $sformatf("Found %0d difference(s):%s", mismatch_cnt, s);
            return 0;
        end

        return 1;
    endfunction : equals_verbose

    // 判断 b 是否为 a 的子映射，需要同时满足 key 存在且 value 相等。
    static function bit contains(const ref aa_t a, const ref aa_t b);
        foreach (b[k]) begin
            if (!a.exists(k))
                return 0;
            if (a[k] !== b[k])
                return 0;
        end

        return 1;
    endfunction : contains

    // 判断给定 key 集是否全部出现在关联数组中。
    static function bit contains_keys(const ref aa_t a, const ref key_set_t keys);
        foreach (keys[key]) begin
            if (!a.exists(key))
                return 0;
        end

        return 1;
    endfunction : contains_keys

    // 判断单个 key 是否存在。
    static function bit has_key(const ref aa_t a, input KEY_T key);
        return a.exists(key);
    endfunction : has_key

    // 遍历所有 value 做严格三值比较，保留 X/Z 语义。
    static function bit has_value(const ref aa_t a, input VAL_T value);
        foreach (a[k]) begin
            if (a[k] === value)
                return 1;
        end

        return 0;
    endfunction : has_value

    // 先拷贝 lhs，再用 rhs 覆盖同名 key，得到完整 merge 结果。
    static function void merge_into(const ref aa_t lhs, const ref aa_t rhs, ref aa_t result);
        aa_t tmp;

        foreach (lhs[k])
            tmp[k] = lhs[k];

        foreach (rhs[k])
            tmp[k] = rhs[k];

        result = tmp;
    endfunction : merge_into

    // 构造一个纯净的新关联数组并返回 merge 结果。
    static function aa_t get_merge(const ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    // 原地 merge，直接把 rhs 中的条目写回 lhs。
    static function void merge_with(ref aa_t lhs, const ref aa_t rhs);
        foreach (rhs[k])
            lhs[k] = rhs[k];
    endfunction : merge_with

    // 交集只按 key 判断，但结果 value 保留 lhs 原值。
    static function void intersect_into(const ref aa_t lhs, const ref aa_t rhs, ref aa_t result);
        aa_t tmp;

        foreach (lhs[k]) begin
            if (rhs.exists(k))
                tmp[k] = lhs[k];
        end

        result = tmp;
    endfunction : intersect_into

    // 构造一个纯净的新关联数组并返回交集结果。
    static function aa_t get_intersect(const ref aa_t lhs, const ref aa_t rhs);
        aa_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地交集采用“先收集待删 key，再删除”的方式，避免遍历时修改容器。
    static function void intersect_with(ref aa_t lhs, const ref aa_t rhs);
        KEY_T keys_to_delete[$];

        foreach (lhs[k]) begin
            if (!rhs.exists(k))
                keys_to_delete.push_back(k);
        end

        foreach (keys_to_delete[i])
            lhs.delete(keys_to_delete[i]);
    endfunction : intersect_with

    // 先记录会被 rhs 覆盖的 lhs 条目，再对 lhs 做原地 merge。
    static function aa_t get_intersect_merge_with(ref aa_t lhs, const ref aa_t rhs);
        aa_t overwritten;

        intersect_into(lhs, rhs, overwritten);
        merge_with(lhs, rhs);
        return overwritten;
    endfunction : get_intersect_merge_with

    // 差集只保留 a 独有的 key，value 同样来自 a。
    static function void diff_into(const ref aa_t a, const ref aa_t b, ref aa_t result);
        aa_t tmp;

        foreach (a[k]) begin
            if (!b.exists(k))
                tmp[k] = a[k];
        end

        result = tmp;
    endfunction : diff_into

    // 构造一个纯净的新关联数组并返回差集结果。
    static function aa_t get_diff(const ref aa_t a, const ref aa_t b);
        aa_t result;

        diff_into(a, b, result);
        return result;
    endfunction : get_diff

    // 原地差集同样采用“先收集、后删除”，避免 foreach 期间修改 lhs。
    static function void diff_with(ref aa_t lhs, const ref aa_t rhs);
        KEY_T keys_to_delete[$];

        foreach (lhs[k]) begin
            if (rhs.exists(k))
                keys_to_delete.push_back(k);
        end

        foreach (keys_to_delete[i])
            lhs.delete(keys_to_delete[i]);
    endfunction : diff_with

    // 提取所有 key，并用 set_util 保持返回类型与集合工具一致。
    static function key_set_t get_keys(const ref aa_t a);
        key_set_t keys;

        foreach (a[k])
            key_set_util::insert(keys, k);

        return keys;
    endfunction : get_keys

    // 提取所有 value，并自然完成去重。
    static function val_set_t get_values(const ref aa_t a);
        val_set_t values;

        foreach (a[k])
            val_set_util::insert(values, a[k]);

        return values;
    endfunction : get_values

endclass

`endif
