`ifndef __SET_ARRAY_SVH__
`define __SET_ARRAY_SVH__

`include "collection_set.svh"

class set_array_t #(type DATA_T = logic [31:0], int SIZE = 32);
    typedef set_t#(DATA_T) this_t;
    this_t sets[SIZE];

    function void insert(int index, DATA_T key);
        sets[index].insert(key);
    endfunction

    function void delete(int index, DATA_T key);
        sets[index].delete(key);
    endfunction

    function bit contains(int index, DATA_T key);
        return sets[index].contains(key);
    endfunction

    function void clear(int index);
        sets[index].clear();
    endfunction

    function int size(int index);
        return sets[index].size();
    endfunction
    
endclass
    
`endif