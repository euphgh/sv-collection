`ifndef __AA_ARRAY_SVH__
`define __AA_ARRAY_SVH__

`include "q_array.svh"

class aa_array_t #(int unsigned N_BANKS = 4,
                type ADDR_T = logic [7:0],
                type DATA_T = logic [31:0]);

    typedef aa_util#(ADDR_T, DATA_T)::aa_t bank_aa_t;
    typedef aa_array_t#(N_BANKS, ADDR_T, DATA_T) this_t;
    typedef q_array_t#(N_BANKS) key_sets_t;

    bank_aa_t banks[N_BANKS];

    function void clear();
        foreach (banks[bank])
            banks[bank].delete();
    endfunction

    function this_t merge_from(const ref this_t rhs);
        this_t overwritten = new();

        foreach (rhs.banks[bank])
            aa_util#(ADDR_T, DATA_T)::merge(banks[bank], rhs.banks[bank], overwritten.banks[bank]);

        return overwritten;
    endfunction


    function key_sets_t get_key_sets();
    endfunction

    function key_sets_t key_intersect(const ref this_t rhs);
    endfunction

    function key_sets_t key_unionset(const ref this_t rhs);
    endfunction

    function this_t pair_intersect(const ref this_t rhs);
    endfunction


    function void remove_from_aa_array(const ref this_t rhs);
    endfunction

    function void remove_from_key_sets(const ref key_sets_t rhs);
    endfunction

    function this_t key_intersect_lift(const ref this_t rhs);
        this_t result = new();

        foreach (banks[bank])
            aa_util#(ADDR_T, DATA_T)::key_intersect(banks[bank], rhs.banks[bank], result.banks[bank]);

        return result;
    endfunction

    function string pad_right(string s, int width);
        while (s.len() < width)
            s = {s, " "};
        return s;
    endfunction

    function string sprint(string name = "bank_mem");
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
            if (banks[bank].size() > max_entries)
                max_entries = banks[bank].size();

            foreach (banks[bank][addr]) begin
                entry_str = $sformatf("[%p]: %p", addr, banks[bank][addr]);
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

    function void print(string name = "bank_mem");
        $display("%s", sprint(name));
    endfunction

endclass

`endif