`ifndef __AA_ARRAY_UTIL_SVH__
`define __AA_ARRAY_UTIL_SVH__

`include "aa_util.svh"
`include "aa_of_q_util.svh"

// aa_array_util
// -------------
// 固定大小的 array-of-aa 工具类。
//
// 设计约定：
// 1. `aa_array_t[i]` 是一个普通关联数组，每个 element 彼此独立。
// 2. 整体集合运算按 element 逐项执行，对应 element 调用 `aa_util` 的同名操作。
// 3. `*_into()` 语义与 `aa_util` 保持一致：逐 element 完整覆写 `result[i]`。
// 
// 提供接口：与aa_util完全一致
//
// 参数要求：与aa_util完全一致
class aa_array_util #(int unsigned SIZE = 4,
                      type KEY_T = int,
                      type VAL_T = real);

    typedef aa_util#(KEY_T, VAL_T) elem_util;
    typedef elem_util::aa_t aa_t;
    typedef elem_util::key_set_t key_set_t;
    typedef aa_t aa_array_t[SIZE];
    typedef key_set_t key_set_array_t[SIZE];
    typedef aa_t bar_t[];

    // 判断两个 aa-array 是否逐 bank 完全相等。
    static function bit equals(const ref aa_array_t a, const ref aa_array_t b);
        for (int unsigned i = 0; i < SIZE; i++) begin
            if (!elem_util::equals(a[i], b[i]))
                return 0;
        end
        return 1;
    endfunction : equals

    // 判断 b 是否为 a 的子映射，需要同时满足 key 存在且 value 相等。
    static function bit contains(const ref aa_array_t a, const ref aa_array_t b);
        for (int unsigned i = 0; i < SIZE; i++) begin
            if (!elem_util::contains(a[i], b[i]))
                return 0;
        end
        return 1;
    endfunction : contains

    // 逐 bank 计算 merge 结果并写入 result。
    static function void merge_into(const ref aa_array_t lhs, const ref aa_array_t rhs, ref aa_array_t result);
        for (int unsigned i = 0; i < SIZE; i++)
            elem_util::merge_into(lhs[i], rhs[i], result[i]);
    endfunction : merge_into

    // 返回新的逐 bank merge 结果。
    static function aa_array_t get_merge(const ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t result;

        merge_into(lhs, rhs, result);
        return result;
    endfunction : get_merge

    // 原地逐 bank merge。
    static function void merge_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        for (int unsigned i = 0; i < SIZE; i++)
            elem_util::merge_with(lhs[i], rhs[i]);
    endfunction : merge_with

    // 逐 bank 计算交集结果并写入 result。
    static function void intersect_into(const ref aa_array_t lhs, const ref aa_array_t rhs, ref aa_array_t result);
        for (int unsigned i = 0; i < SIZE; i++)
            elem_util::intersect_into(lhs[i], rhs[i], result[i]);
    endfunction : intersect_into

    // 返回新的逐 bank 交集结果。
    static function aa_array_t get_intersect(const ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t result;

        intersect_into(lhs, rhs, result);
        return result;
    endfunction : get_intersect

    // 原地逐 bank 交集。
    static function void intersect_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        for (int unsigned i = 0; i < SIZE; i++)
            elem_util::intersect_with(lhs[i], rhs[i]);
    endfunction : intersect_with

    // 逐 bank 计算差集结果并写入 result。
    static function void diff_into(const ref aa_array_t lhs, const ref aa_array_t rhs, ref aa_array_t result);
        for (int unsigned i = 0; i < SIZE; i++)
            elem_util::diff_into(lhs[i], rhs[i], result[i]);
    endfunction : diff_into

    // 返回新的逐 bank 差集结果。
    static function aa_array_t get_diff(const ref aa_array_t lhs, const ref aa_array_t rhs);
        aa_array_t result;

        diff_into(lhs, rhs, result);
        return result;
    endfunction : get_diff

    // 原地逐 bank 差集。
    static function void diff_with(ref aa_array_t lhs, const ref aa_array_t rhs);
        for (int unsigned i = 0; i < SIZE; i++)
            elem_util::diff_with(lhs[i], rhs[i]);
    endfunction : diff_with

    // 提取所有 bank 的 key 集。
    static function key_set_array_t get_keys(const ref aa_array_t aa_array);
        key_set_array_t result;

        for (int unsigned i = 0; i < SIZE; i++)
            result[i] = elem_util::get_keys(aa_array[i]);
        return result;
    endfunction : get_keys

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
        string header[SIZE];
        string entries[SIZE][$];
        int col_width[SIZE];
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
