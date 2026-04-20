`ifndef __MULTIMAP_ARRAY_UTIL_SVH__
`define __MULTIMAP_ARRAY_UTIL_SVH__

`include "multimap_util.svh"

// multimap_array_util
// -------------------
// 固定大小的 array-of-multimap 工具类。
//
// 设计约定：
// 1. `multimap_array_t[bank]` 逻辑上是一个普通 multimap，每个 bank 彼此独立。
// 2. 默认使用直接数组 `multimap_t multimap_array_t[N_BANKS]`。
//    当编译器定义了 `COLLECTION_NESTED_AA_WORKAROUND` 时，
//    切换到 bank-bucket-handle 兼容版本（在 `collection_pkg.sv` 中根据编译器自动设置）。
// 3. 整体运算按 bank 逐项执行，对应 bank 调用 `multimap_util` 的同名操作。
// 4. `*_into()` 语义与 `multimap_util` 保持一致：逐 bank 完整覆写 `result[bank]`。
// 5. 打印采用简单逐行输出：每个 `<bank, key, values>` 占一行。
class multimap_array_util #(int unsigned N_BANKS = 4,
                            type KEY_T = logic [7:0],
                            type VAL_T = logic [31:0]);

    typedef multimap_util#(KEY_T, VAL_T) mmap_elem_util_t;
    typedef mmap_elem_util_t::multimap_t multimap_t;
    typedef mmap_elem_util_t::val_set_t val_set_t;
    typedef mmap_elem_util_t::key_set_t key_set_t;

`ifdef COLLECTION_NESTED_AA_WORKAROUND
    class bank_bucket_t;
        multimap_t mmap;
    endclass

    typedef bank_bucket_t multimap_array_t[N_BANKS];
`else
    typedef multimap_t multimap_array_t[N_BANKS];
`endif

    typedef key_set_t key_set_array_t[N_BANKS];

    // 返回指定 bank 的 multimap 视图；空 bank 视为空 multimap。
    static function multimap_t get_bank_mmap(const ref multimap_array_t mmap_array, input int unsigned bank);
        multimap_t result;

`ifdef COLLECTION_NESTED_AA_WORKAROUND
        if (mmap_array[bank] != null)
            result = mmap_array[bank].mmap;
`else
        result = mmap_array[bank];
`endif

        return result;
    endfunction : get_bank_mmap

    // 用新的 multimap 结果覆写指定 bank；空 multimap 直接清空该 bank。
    static function void set_bank_mmap(ref multimap_array_t mmap_array, input int unsigned bank, const ref multimap_t mmap);
`ifdef COLLECTION_NESTED_AA_WORKAROUND
        if (mmap.size() == 0)
            mmap_array[bank] = null;
        else begin
            if (mmap_array[bank] == null)
                mmap_array[bank] = new();
            mmap_array[bank].mmap = mmap;
        end
`else
        mmap_array[bank] = mmap;
`endif
    endfunction : set_bank_mmap

    // 在指定 bank 插入一个 `<key, value>` 对。
    static function void insert(ref multimap_array_t mmap_array, input int unsigned bank, input KEY_T key, input VAL_T value);
        multimap_t mmap;

        mmap = get_bank_mmap(mmap_array, bank);
        mmap_elem_util_t::insert(mmap, key, value);
        set_bank_mmap(mmap_array, bank, mmap);
    endfunction : insert

    // 在指定 bank 的指定 key 下批量加入 values。
    static function void add_values(ref multimap_array_t mmap_array, input int unsigned bank, input KEY_T key, const ref val_set_t values);
        multimap_t mmap;

        mmap = get_bank_mmap(mmap_array, bank);
        mmap_elem_util_t::add_values(mmap, key, values);
        set_bank_mmap(mmap_array, bank, mmap);
    endfunction : add_values

    // 返回所有 bank 下 value 的总数。
    static function int unsigned num_values(const ref multimap_array_t mmap_array);
        int unsigned count = 0;
        multimap_t bank_mmap;

        for (int unsigned i = 0; i < N_BANKS; i++) begin
            bank_mmap = get_bank_mmap(mmap_array, i);
            count += mmap_elem_util_t::num_values(bank_mmap);
        end

        return count;
    endfunction : num_values

    // 返回指定 bank 下 value 的总数。
    static function int unsigned num_values_at_bank(const ref multimap_array_t mmap_array, input int unsigned bank);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::num_values(bank_mmap);
    endfunction : num_values_at_bank

    // 返回指定 bank、指定 key 下的 value 数量。
    static function int unsigned num_values_at_key(const ref multimap_array_t mmap_array, input int unsigned bank, input KEY_T key);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::num_values_at_key(bank_mmap, key);
    endfunction : num_values_at_key

    // 判断指定 bank 是否存在 key。
    static function bit contains_key(const ref multimap_array_t mmap_array, input int unsigned bank, input KEY_T key);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::has_key(bank_mmap, key);
    endfunction : contains_key

    // 判断指定 bank 是否存在 `<key, value>` 对。
    static function bit contains_value(const ref multimap_array_t mmap_array, input int unsigned bank, input KEY_T key, input VAL_T value);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::contains_value(bank_mmap, key, value);
    endfunction : contains_value

    // 判断指定 bank 是否包含一个子 multimap。
    static function bit contains(const ref multimap_array_t mmap_array, input int unsigned bank, const ref multimap_t subset);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::contains(bank_mmap, subset);
    endfunction : contains

    // 判断 `mmap_array[bank]` 是否同时包含 rhs 数组中每个 bank 的子 multimap。
    static function bit contains_multimap_array(const ref multimap_array_t mmap_array, input int unsigned bank, const ref multimap_array_t rhs);
        multimap_t lhs_mmap;
        multimap_t rhs_mmap;

        lhs_mmap = get_bank_mmap(mmap_array, bank);
        for (int unsigned i = 0; i < N_BANKS; i++) begin
            rhs_mmap = get_bank_mmap(rhs, i);
            if (!mmap_elem_util_t::contains(lhs_mmap, rhs_mmap))
                return 0;
        end
        return 1;
    endfunction : contains_multimap_array

    // 判断两个 multimap-array 是否逐 bank 完全相等。
    static function bit equals(const ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_t lhs_mmap;
        multimap_t rhs_mmap;

        for (int unsigned i = 0; i < N_BANKS; i++) begin
            lhs_mmap = get_bank_mmap(lhs, i);
            rhs_mmap = get_bank_mmap(rhs, i);
            if (!mmap_elem_util_t::equals(lhs_mmap, rhs_mmap))
                return 0;
        end
        return 1;
    endfunction : equals

    // 逐 bank 计算 merge 结果并写入 result。
    static function void merge_into(const ref multimap_array_t lhs, const ref multimap_array_t rhs, ref multimap_array_t result);
        multimap_t lhs_mmap;
        multimap_t rhs_mmap;
        multimap_t merged;

        for (int unsigned i = 0; i < N_BANKS; i++) begin
            lhs_mmap = get_bank_mmap(lhs, i);
            rhs_mmap = get_bank_mmap(rhs, i);
            merged = mmap_elem_util_t::get_merge(lhs_mmap, rhs_mmap);
            set_bank_mmap(result, i, merged);
        end
    endfunction : merge_into

    // 返回新的逐 bank merge 结果。
    static function multimap_array_t get_merge(const ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_array_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    // 原地逐 bank merge。
    static function void merge_with(ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_array_t tmp;

        merge_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : merge_with

    // 逐 bank 计算交集结果并写入 result。
    static function void intersect_into(const ref multimap_array_t lhs, const ref multimap_array_t rhs, ref multimap_array_t result);
        multimap_t lhs_mmap;
        multimap_t rhs_mmap;
        multimap_t intersected;

        for (int unsigned i = 0; i < N_BANKS; i++) begin
            lhs_mmap = get_bank_mmap(lhs, i);
            rhs_mmap = get_bank_mmap(rhs, i);
            intersected = mmap_elem_util_t::get_intersect(lhs_mmap, rhs_mmap);
            set_bank_mmap(result, i, intersected);
        end
    endfunction : intersect_into

    // 返回新的逐 bank 交集结果。
    static function multimap_array_t get_intersect(const ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地逐 bank 交集。
    static function void intersect_with(ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_array_t tmp;

        intersect_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : intersect_with

    // 逐 bank 计算差集结果并写入 result。
    static function void diff_into(const ref multimap_array_t lhs, const ref multimap_array_t rhs, ref multimap_array_t result);
        multimap_t lhs_mmap;
        multimap_t rhs_mmap;
        multimap_t diffed;

        for (int unsigned i = 0; i < N_BANKS; i++) begin
            lhs_mmap = get_bank_mmap(lhs, i);
            rhs_mmap = get_bank_mmap(rhs, i);
            diffed = mmap_elem_util_t::get_diff(lhs_mmap, rhs_mmap);
            set_bank_mmap(result, i, diffed);
        end
    endfunction : diff_into

    // 返回新的逐 bank 差集结果。
    static function multimap_array_t get_diff(const ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    // 原地逐 bank 差集。
    static function void diff_with(ref multimap_array_t lhs, const ref multimap_array_t rhs);
        multimap_array_t tmp;

        diff_into(lhs, rhs, tmp);
        lhs = tmp;
    endfunction : diff_with

    // 提取指定 bank 的 key 集。
    static function key_set_t get_keys(const ref multimap_array_t mmap_array, input int unsigned bank);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::get_keys(bank_mmap);
    endfunction : get_keys

    // 提取所有 bank 的 key 集。
    static function key_set_array_t get_key_sets(const ref multimap_array_t mmap_array);
        key_set_array_t result;

        for (int unsigned i = 0; i < N_BANKS; i++)
            result[i] = get_keys(mmap_array, i);

        return result;
    endfunction : get_key_sets

    // 返回指定 bank、指定 key 的 value-set 副本。
    static function val_set_t get_values(const ref multimap_array_t mmap_array, input int unsigned bank, input KEY_T key);
        multimap_t bank_mmap;

        bank_mmap = get_bank_mmap(mmap_array, bank);
        return mmap_elem_util_t::get_values(bank_mmap, key);
    endfunction : get_values

    // 简单逐行打印，每个 `<bank, key, values>` 占一行。
    static function string sprint(const ref multimap_array_t mmap_array, input string name = "multimap_array");
        string s;
        bit has_entries;
        key_set_t keys;
        val_set_t values;

        s = {name, " = '{"};
        has_entries = 0;

        for (int unsigned bank = 0; bank < N_BANKS; bank++) begin
            keys = get_keys(mmap_array, bank);
            foreach (keys[key]) begin
                values = get_values(mmap_array, bank, key);
                s = {s, $sformatf("\n  [bank=%0d][%p]: %p", bank, key, values)};
                has_entries = 1;
            end
        end

        if (!has_entries)
            s = {s, " // empty"};

        s = {s, "\n}"};
        return s;
    endfunction : sprint

    // 直接打印格式化后的 multimap-array。
    static function void print(const ref multimap_array_t mmap_array, input string name = "multimap_array");
        $display("%s", sprint(mmap_array, name));
    endfunction : print
endclass

`endif
