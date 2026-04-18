`ifndef __AA_ARRAY_UTIL_SVH__
`define __AA_ARRAY_UTIL_SVH__

`include "aa_util.svh"

// aa_array_util
// -------------
// 固定大小的 array-of-aa 工具类。
//
// 设计约定：
// 1. `aa_array_t[bank]` 是一个普通关联数组，每个 bank 彼此独立。
// 2. 整体集合运算按 bank 逐项执行，对应 bank 调用 `aa_util` 的同名操作。
// 3. `*_into()` 语义与 `aa_util` 保持一致：逐 bank 完整覆写 `result[bank]`。
// 4. 打印采用表格样式：每一列对应一个 bank，每一行显示各 bank 的一条 key-value 项。
class aa_array_util #(int unsigned N_BANKS = 4,
                      type ADDR_T = logic [7:0],
                      type DATA_T = logic [31:0]);

    typedef aa_util#(ADDR_T, DATA_T) aa_elem_util_t;
    typedef aa_elem_util_t::aa_t aa_t;
    typedef aa_elem_util_t::key_set_t key_set_t;
    typedef aa_t aa_array_t[N_BANKS];
    typedef key_set_t key_set_array_t[N_BANKS];

    // 判断指定 bank 是否包含某个 key。
    static function bit contains_key(const ref aa_array_t aa_array, input int unsigned bank, input ADDR_T key);
        return aa_elem_util_t::has_key(aa_array[bank], key);
    endfunction : contains_key

    // 判断指定 bank 是否包含一个子映射。
    static function bit contains(const ref aa_array_t aa_array, input int unsigned bank, const ref aa_t subset);
        return aa_elem_util_t::contains(aa_array[bank], subset);
    endfunction : contains

    // 判断指定 bank 是否包含一组 key。
    static function bit contains_keys(const ref aa_array_t aa_array, input int unsigned bank, const ref key_set_t keys);
        return aa_elem_util_t::contains_keys(aa_array[bank], keys);
    endfunction : contains_keys

    // 判断 `aa_array[bank]` 是否同时包含 rhs 数组中每个 bank 的子映射。
    static function bit contains_aa_array(const ref aa_array_t aa_array, input int unsigned bank, const ref aa_array_t rhs);
        foreach (rhs[i]) begin
            if (!aa_elem_util_t::contains(aa_array[bank], rhs[i]))
                return 0;
        end
        return 1;
    endfunction : contains_aa_array

    // 判断两个 aa-array 是否逐 bank 完全相等。
    static function bit equals(const ref aa_array_t a, const ref aa_array_t b);
        for (int unsigned i = 0; i < N_BANKS; i++) begin
            if (!aa_elem_util_t::equals(a[i], b[i]))
                return 0;
        end
        return 1;
    endfunction : equals

    // 逐 bank 计算 merge 结果并写入 result。
    static function void merge_into(const ref aa_array_t lhs, const ref aa_array_t rhs, ref aa_array_t result);
        for (int unsigned i = 0; i < N_BANKS; i++)
            aa_elem_util_t::merge_into(lhs[i], rhs[i], result[i]);
    endfunction : merge_into

    // 返回新的逐 bank merge 结果。
    static function aa_array_t get_merge(const ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    // 原地逐 bank merge。
    static function void merge_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        for (int unsigned i = 0; i < N_BANKS; i++)
            aa_elem_util_t::merge_with(lhs[i], rhs[i]);
    endfunction : merge_with

    // 逐 bank 计算交集结果并写入 result。
    static function void intersect_into(const ref aa_array_t lhs, const ref aa_array_t rhs, ref aa_array_t result);
        for (int unsigned i = 0; i < N_BANKS; i++)
            aa_elem_util_t::intersect_into(lhs[i], rhs[i], result[i]);
    endfunction : intersect_into

    // 返回新的逐 bank 交集结果。
    static function aa_array_t get_intersect(const ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地逐 bank 交集。
    static function void intersect_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        for (int unsigned i = 0; i < N_BANKS; i++)
            aa_elem_util_t::intersect_with(lhs[i], rhs[i]);
    endfunction : intersect_with

    // 先按 bank 记录会被覆盖的交集部分，再对 lhs 做原地 merge。
    static function aa_array_t get_intersect_merge_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t overwritten;

        for (int unsigned i = 0; i < N_BANKS; i++)
            overwritten[i] = aa_elem_util_t::get_intersect_merge_with(lhs[i], rhs[i]);

        return overwritten;
    endfunction : get_intersect_merge_with

    // 逐 bank 计算差集结果并写入 result。
    static function void diff_into(const ref aa_array_t lhs, const ref aa_array_t rhs, ref aa_array_t result);
        for (int unsigned i = 0; i < N_BANKS; i++)
            aa_elem_util_t::diff_into(lhs[i], rhs[i], result[i]);
    endfunction : diff_into

    // 返回新的逐 bank 差集结果。
    static function aa_array_t get_diff(const ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    // 原地逐 bank 差集。
    static function void diff_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        for (int unsigned i = 0; i < N_BANKS; i++)
            aa_elem_util_t::diff_with(lhs[i], rhs[i]);
    endfunction : diff_with

    // 提取指定 bank 的 key 集。
    static function key_set_t get_keys(const ref aa_array_t aa_array, input int unsigned bank);
        return aa_elem_util_t::get_keys(aa_array[bank]);
    endfunction : get_keys

    // 提取所有 bank 的 key 集。
    static function key_set_array_t get_key_sets(const ref aa_array_t aa_array);
        key_set_array_t result;

        for (int unsigned i = 0; i < N_BANKS; i++)
            result[i] = aa_elem_util_t::get_keys(aa_array[i]);

        return result;
    endfunction : get_key_sets

    // 右填充，便于把每个 bank 按列对齐打印。
    static function string pad_right(input string s, input int width);
        while (s.len() < width)
            s = {s, " "};
        return s;
    endfunction : pad_right

    // 以列为 bank、行为条目的形式打印 aa-array。
    static function string sprint(const ref aa_array_t aa_array, input string name = "bank_mem");
        string s;
        string entry_str;
        string header[N_BANKS];
        string entries[N_BANKS][$];
        int col_width[N_BANKS];
        int max_entries;
        int row;

        max_entries = 0;
        s = {name, "\n"};

        foreach (aa_array[bank]) begin
            header[bank] = $sformatf("bank[%0d]", bank);
            col_width[bank] = header[bank].len();
            if (aa_array[bank].size() > max_entries)
                max_entries = aa_array[bank].size();
        end

        foreach (aa_array[bank, key]) begin
                entry_str = $sformatf("[%p]: %p", key, aa_array[bank][key]);
                entries[bank].push_back(entry_str);
                if (entry_str.len() > col_width[bank])
                    col_width[bank] = entry_str.len();
        end

        foreach (header[bank]) begin
            if (bank > 0)
                s = {s, " | "};
            s = {s, pad_right(header[bank], col_width[bank])};
        end

        for (row = 0; row < max_entries; row++) begin
            s = {s, "\n"};
            foreach (aa_array[bank]) begin
                if (bank > 0)
                    s = {s, " | "};
                entry_str = (row < entries[bank].size()) ? entries[bank][row] : "";
                s = {s, pad_right(entry_str, col_width[bank])};
            end
        end

        return s;
    endfunction : sprint

    // 直接打印格式化后的 aa-array。
    static function void print(const ref aa_array_t aa_array, input string name = "bank_mem");
        $display("%s", sprint(aa_array, name));
    endfunction : print
endclass

`endif
