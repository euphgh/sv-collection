`ifndef __TESTS_UTIL_SVH__
`define __TESTS_UTIL_SVH__

task automatic check_true(input bit cond, input string msg);
    if (!cond) begin
        $error("CHECK FAILED: %s", msg);
        $fatal(1);
    end
endtask

`endif
