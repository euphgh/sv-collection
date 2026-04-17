`ifndef __MULTIMAP_ARRAY_SVH__
`define __MULTIMAP_ARRAY_SVH__

`include "multimap.svh"
`include "aa_array.svh"

class multimap_array #(int unsigned N_BANKS = 4,
                        type KEY_T = logic [7:0],
                        type VAL_T = logic [31:0]);

    typedef multimap#(KEY_T, VAL_T) bank_t;
    typedef multimap_array#(N_BANKS, KEY_T, VAL_T) this_t;
    // single map array 
    typedef aa_array_t#(N_BANKS, KEY_T, VAL_T) smap_array_t;

    bank_t banks[N_BANKS];

    function new();
        foreach (banks[bank])
            banks[bank] = new();
    endfunction

    function void clear();
        foreach (banks[bank])
            banks[bank].clear();
    endfunction

    function void add(int unsigned bank, KEY_T key, VAL_T value);
        banks[bank].add(key, value);
    endfunction

    function void merge_from(const ref this_t rhs);
        foreach (banks[bank])
            banks[bank].merge_from(rhs.banks[bank]);
    endfunction

    function void merge_from_aa_array(const ref smap_array_t rhs);
        foreach (rhs.banks[bidx])
            banks[bidx].merge_from_aa(rhs.banks[bidx]);
    endfunction

    /**
     * 计算和rhs地交集，要求对应bank下，相同key对应地queue有交集，返回两个queue有交集的元素
     */
    function this_t pair_intersect(this_t rhs);
    endfunction

    /**
     * 
     */
    function smap_array_t pair_intersect_from_aa_array(const ref smap_array_t rhs);
    endfunction

    /**
     * remove self <key, value> from rhs
     * 在对应bank中查找是否由相同的key存在
     * 如果存在，顺序地从queue中查找是否有对应地value，存在则移除
     */
    function void remove_from_aa_array(const ref smap_array_t rhs);
    endfunction

    function this_t key_intersect(this_t rhs);
        this_t result;

        result = new();
        foreach (banks[bank])
            result.banks[bank] = banks[bank].key_intersect(rhs.banks[bank]);

        return result;
    endfunction

    function string pad_right(string s, int width);
        while (s.len() < width)
            s = {s, " "};
        return s;
    endfunction

    function string sprint(string name = "multimap_array");
        string s;
        string entry_str;
        string header[N_BANKS];
        string entries[N_BANKS][$];
        int col_width[N_BANKS];
        int max_entries;
        int row;

        max_entries = 0;
        s = "";

        foreach (banks[bank]) begin
            header[bank] = $sformatf("bank[%0d]", bank);
            col_width[bank] = header[bank].len();
            if (banks[bank].num_keys() > max_entries)
                max_entries = banks[bank].num_keys();

            foreach (banks[bank].data[key]) begin
                entry_str = $sformatf("[%p]: %p", key, banks[bank].data[key]);
                entries[bank].push_back(entry_str);
                if (entry_str.len() > col_width[bank])
                    col_width[bank] = entry_str.len();
            end
        end

        foreach (header[bank]) begin
            if (bank > 0)
                s = {s, " | "};
            s = {s, pad_right(header[bank], col_width[bank])};
        end

        for (row = 0; row < max_entries; row++) begin
            s = {s, "\n"};
            foreach (banks[bank]) begin
                if (bank > 0)
                    s = {s, " | "};
                entry_str = (row < entries[bank].size()) ? entries[bank][row] : "";
                s = {s, pad_right(entry_str, col_width[bank])};
            end
        end

        return s;
    endfunction

    function void print(string name = "multimap_array");
        $display("%s", sprint(name));
    endfunction

endclass

`endif