`ifndef __Q_ARRAY_SVH__
`define __Q_ARRAY_SVH__

class q_array_t #(int unsigned BANK_N = 4, type DATA_T = logic [31:0]);
    typedef q_array_t#(BANK_N, DATA_T) this_t;
    function bit contains(this_t rhs);
    endfunction
endclass

`endif