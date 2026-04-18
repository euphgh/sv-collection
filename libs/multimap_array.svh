`ifndef __MULTIMAP_ARRAY_SVH__
`define __MULTIMAP_ARRAY_SVH__

`include "multimap.svh"
`include "aa_array.svh"

class multimap_array #(int unsigned N_BANKS = 4,
                        type KEY_T = logic [7:0],
                        type VAL_T = logic [31:0]);

endclass

`endif