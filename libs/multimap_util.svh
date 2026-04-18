`ifndef __MULTIMAP_UTIL_SVH__
`define __MULTIMAP_UTIL_SVH__

`include "set_util.svh"

// multimap_util
// -------------
// 基于 `aa of set` 的多值映射工具类。
//
// 设计约定：
// 1. `multimap_t[key]` 逻辑上是一个去重后的 value 集合，因此天然不保存重复 value。
//    默认实现为 XSim 兼容的 bucket-handle 版本。
//    如果定义 `COLLECTION_USE_NESTED_AA_MULTIMAP`，则切换到原生 nested-AA 版本。
// 2. `merge` 对相同 key 做 value-set 的并集。
// 3. `intersect` / `diff` 对相同 key 下的 value-set 做集合运算；若结果为空集合，则删除该 key。
// 4. `*_into()` 会完整覆写 `result`，与 `aa_util` 的风格保持一致。
class multimap_util #(type KEY_T = logic [7:0],
                      type VAL_T = logic [31:0]);

    typedef set_util#(KEY_T) key_set_util;
    typedef key_set_util::set_t key_set_t;

    typedef set_util#(VAL_T) val_set_util;
    typedef val_set_util::set_t val_set_t;

`ifdef COLLECTION_USE_NESTED_AA_MULTIMAP
    typedef val_set_t multimap_t[KEY_T];
`else
    class bucket_t;
        val_set_t values;
    endclass

    typedef bucket_t multimap_t[KEY_T];
`endif

    // 返回格式化字符串，展示每个 key 对应的 value 集合。
    static function string sprint(const ref multimap_t mmap, input string name = "mmap");
        string s;
        int cnt = 0;
        int unsigned key_count;

        key_count = num_keys(mmap);

        if (key_count == 0)
            return $sformatf("%s = '{}  // empty, size=0", name);

        s = $sformatf("%s = '{  // size=%0d", name, key_count);
        foreach (mmap[key]) begin
`ifdef COLLECTION_USE_NESTED_AA_MULTIMAP
            s = {s, $sformatf("\n  [%p]: %p", key, mmap[key])};
`else
            s = {s, $sformatf("\n  [%p]: %p", key, mmap[key].values)};
`endif
            cnt++;
            if (cnt >= 100) begin
                int remaining;
                remaining = int'(key_count) - cnt;
                s = {s, $sformatf("\n  ... (%0d more entries)", remaining)};
                break;
            end
        end

        s = {s, "\n}"};
        return s;
    endfunction : sprint

    // 直接打印格式化后的 multimap 内容。
    static function void print(const ref multimap_t mmap, input string name = "mmap");
        $display("%s", sprint(mmap, name));
    endfunction : print

    // 插入一个 `<key, value>` 对；底层使用 set，因此重复 value 会被自动去重。
    static function void insert(ref multimap_t mmap, input KEY_T key, input VAL_T value);
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        if (!mmap.exists(key) || (mmap[key] == null))
            mmap[key] = new();
        val_set_util::insert(mmap[key].values, value);
`else
        val_set_util::insert(mmap[key], value);
`endif
    endfunction : insert

    // 将一组 value 合并到指定 key 上。
    static function void add_values(ref multimap_t mmap, input KEY_T key, const ref val_set_t values);
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        if (!mmap.exists(key) || (mmap[key] == null))
            mmap[key] = new();
        val_set_util::union_with(mmap[key].values, values);
`else
        val_set_util::union_with(mmap[key], values);
`endif
    endfunction : add_values

    // 返回 key 的个数，而不是所有 value 的总数。
    static function int unsigned num_keys(const ref multimap_t mmap);
        int unsigned count = 0;

        foreach (mmap[key]) begin
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
            if (mmap[key] != null)
                count++;
`else
            count++;
`endif
        end

        return count;
    endfunction : num_keys

    // 返回指定 key 下的 value 数量；不存在的 key 视为空集合。
    static function int unsigned num_values(const ref multimap_t mmap, input KEY_T key);
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        if (!mmap.exists(key) || (mmap[key] == null))
            return 0;
        return $unsigned(mmap[key].values.size());
`else
        if (!mmap.exists(key))
            return 0;
        return $unsigned(mmap[key].size());
`endif
    endfunction : num_values

    // 判断是否存在指定 key。
    static function bit has_key(const ref multimap_t mmap, input KEY_T key);
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        return mmap.exists(key) && (mmap[key] != null);
`else
        return mmap.exists(key);
`endif
    endfunction : has_key

    // 判断 `<key, value>` 对是否存在。
    static function bit contains_value(const ref multimap_t mmap, input KEY_T key, input VAL_T value);
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        if (!mmap.exists(key) || (mmap[key] == null))
            return 0;
        return val_set_util::contains_key(mmap[key].values, value);
`else
        if (!mmap.exists(key))
            return 0;
        return val_set_util::contains_key(mmap[key], value);
`endif
    endfunction : contains_value

    // 判断 rhs 是否为 lhs 的子 multimap：每个 key 和对应的 value-set 都必须被包含。
    static function bit contains(const ref multimap_t lhs, const ref multimap_t rhs);
        foreach (rhs[key]) begin
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
            if (!lhs.exists(key) || (lhs[key] == null) || (rhs[key] == null))
                return 0;
            if (!val_set_util::contains_set(lhs[key].values, rhs[key].values))
                return 0;
`else
            if (!lhs.exists(key))
                return 0;
            if (!val_set_util::contains_set(lhs[key], rhs[key]))
                return 0;
`endif
        end

        return 1;
    endfunction : contains

    // 严格相等：key 集必须一致，且每个 key 下的 value-set 也必须一致。
    static function bit equals(const ref multimap_t lhs, const ref multimap_t rhs);
        if (num_keys(lhs) != num_keys(rhs))
            return 0;

        foreach (lhs[key]) begin
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
            if (!rhs.exists(key) || (lhs[key] == null) || (rhs[key] == null))
                return 0;
            if (!val_set_util::equals(lhs[key].values, rhs[key].values))
                return 0;
`else
            if (!rhs.exists(key))
                return 0;
            if (!val_set_util::equals(lhs[key], rhs[key]))
                return 0;
`endif
        end

        return 1;
    endfunction : equals

    // 合并两个 multimap；相同 key 下的 value-set 做并集。
    static function void merge_into(const ref multimap_t lhs, const ref multimap_t rhs, ref multimap_t result);
        multimap_t tmp;

`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        foreach (lhs[key]) begin
            tmp[key] = new();
            tmp[key].values = lhs[key].values;
        end

        foreach (rhs[key]) begin
            if (!tmp.exists(key) || (tmp[key] == null))
                tmp[key] = new();
            val_set_util::union_with(tmp[key].values, rhs[key].values);
        end
`else
        foreach (lhs[key])
            tmp[key] = lhs[key];

        foreach (rhs[key])
            val_set_util::union_with(tmp[key], rhs[key]);
`endif

        result = tmp;
    endfunction : merge_into

    // 返回一个新的 merge 结果。
    static function multimap_t get_merge(const ref multimap_t lhs, const ref multimap_t rhs);
        multimap_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    // 原地 merge，把 rhs 的所有 value-set 合并回 lhs。
    static function void merge_with(ref multimap_t lhs, const ref multimap_t rhs);
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        foreach (rhs[key])
            begin
                if (!lhs.exists(key) || (lhs[key] == null))
                    lhs[key] = new();
                val_set_util::union_with(lhs[key].values, rhs[key].values);
            end
`else
        foreach (rhs[key])
            val_set_util::union_with(lhs[key], rhs[key]);
`endif
    endfunction : merge_with

    // 对共享 key 做 value-set 交集；交集为空的 key 不保留。
    static function void intersect_into(const ref multimap_t lhs, const ref multimap_t rhs, ref multimap_t result);
        multimap_t tmp;
        val_set_t values;

        foreach (lhs[key]) begin
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
            if (lhs[key] == null)
                continue;
            if (!rhs.exists(key))
                continue;
            if (rhs[key] == null)
                continue;

            values = val_set_util::get_intersect(lhs[key].values, rhs[key].values);
            if (values.size() != 0)
                begin
                    tmp[key] = new();
                    tmp[key].values = values;
                end
`else
            if (!rhs.exists(key))
                continue;

            values = val_set_util::get_intersect(lhs[key], rhs[key]);
            if (values.size() != 0)
                tmp[key] = values;
`endif
        end

        result = tmp;
    endfunction : intersect_into

    // 返回新的交集结果。
    static function multimap_t get_intersect(const ref multimap_t lhs, const ref multimap_t rhs);
        multimap_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地交集：先计算结果，再整体回写，避免遍历时修改关联数组。
    static function void intersect_with(ref multimap_t lhs, const ref multimap_t rhs);
        multimap_t tmp;

        intersect_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : intersect_with

    // 对每个 key 的 value-set 做差集；差集为空的 key 不保留。
    static function void diff_into(const ref multimap_t lhs, const ref multimap_t rhs, ref multimap_t result);
        multimap_t tmp;
        val_set_t values;

        foreach (lhs[key]) begin
`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
            if (lhs[key] == null)
                continue;
            if (!rhs.exists(key)) begin
                tmp[key] = new();
                tmp[key].values = lhs[key].values;
                continue;
            end
            if (rhs[key] == null) begin
                tmp[key] = new();
                tmp[key].values = lhs[key].values;
                continue;
            end

            values = val_set_util::get_diff(lhs[key].values, rhs[key].values);
            if (values.size() != 0)
                begin
                    tmp[key] = new();
                    tmp[key].values = values;
                end
`else
            if (!rhs.exists(key)) begin
                tmp[key] = lhs[key];
                continue;
            end

            values = val_set_util::get_diff(lhs[key], rhs[key]);
            if (values.size() != 0)
                tmp[key] = values;
`endif
        end

        result = tmp;
    endfunction : diff_into

    // 返回新的差集结果。
    static function multimap_t get_diff(const ref multimap_t lhs, const ref multimap_t rhs);
        multimap_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    // 原地差集：先算出结果，再整体回写。
    static function void diff_with(ref multimap_t lhs, const ref multimap_t rhs);
        multimap_t tmp;

        diff_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : diff_with

    // 提取所有 key。
    static function key_set_t get_keys(const ref multimap_t mmap);
        key_set_t keys;

        foreach (mmap[key])
            key_set_util::insert(keys, key);

        return keys;
    endfunction : get_keys

    // 返回指定 key 对应的 value-set 副本；不存在时返回空集合。
    static function val_set_t get_values(const ref multimap_t mmap, input KEY_T key);
        val_set_t values;

`ifndef COLLECTION_USE_NESTED_AA_MULTIMAP
        if (mmap.exists(key) && (mmap[key] != null))
            values = mmap[key].values;
`else
        if (mmap.exists(key))
            values = mmap[key];
`endif

        return values;
    endfunction : get_values
endclass

`endif
