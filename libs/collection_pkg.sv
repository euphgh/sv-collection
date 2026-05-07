`ifdef XILINX_SIMULATOR
    `define COLLECTION_NESTED_AA_WORKAROUND
`endif

package collection;
    `include "set_util.svh"
    `include "set_array_util.svh"
    `include "aa_util.svh"
    `include "aa_array_util.svh"
    `include "aa_of_q_util.svh"
    `include "aa_of_q_array_util.svh"
endpackage
