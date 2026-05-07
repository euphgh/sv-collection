`ifndef __AA_OF_Q_ARRAY_UTIL_SVH__
`define __AA_OF_Q_ARRAY_UTIL_SVH__

`include "aa_util.svh"
`include "aa_of_q_util.svh"
`include "aa_array_util.svh"

class aa_of_q_array_util #(int unsigned N_BANKS = 4,
                      type KEY_T = logic [7:0],
                      type VAL_T = logic [31:0]);
endclass

`endif