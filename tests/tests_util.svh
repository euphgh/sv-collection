`ifndef __TESTS_UTIL_SVH__
`define __TESTS_UTIL_SVH__

task automatic check_true(input bit cond, input string msg, input string detail = "");
    if (!cond) begin
        if (detail.len() != 0)
            $error("CHECK FAILED: %s | %s", msg, detail);
        else
            $error("CHECK FAILED: %s", msg);
        $fatal(1);
    end
endtask

`endif
