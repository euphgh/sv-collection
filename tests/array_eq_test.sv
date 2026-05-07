module array_eq_test;
    int unsigned a[$];
    int unsigned b[$];
    byte a_aa[int];
    byte b_aa[int];

    typedef byte byte_q[$];

    byte_q a_q_aa[int];
    byte_q b_q_aa[int];

    initial begin
        a = '{1, 2, 3};
        b = '{1, 2, 3};

        if (a == b)
            $display("PASS: a == b works for identical queues");
        else
            $display("FAIL: a == b returned false for identical queues");

        b = '{1, 2, 4};
        if (a != b)
            $display("PASS: a != b works for different queues");
        else
            $display("FAIL: a != b returned false for different queues");

        a_aa = '{0: 1, 1: 2, 2: 3};
        b_aa = '{0: 1, 1: 2, 2: 3};
        if (a_aa == b_aa)
            $display("PASS: a_aa == b_aa works for identical associative arrays");
        else
            $display("FAIL: a_aa == b_aa returned false for identical associative arrays");
        b_aa = '{0: 1, 1: 2, 2: 4};
        if (a_aa != b_aa)
            $display("PASS: a_aa != b_aa works for different associative arrays");
        else            
            $display("FAIL: a_aa != b_aa returned false for different associative arrays");

        a_q_aa[0] = '{1, 2, 3};
        b_q_aa[0] = '{1, 2, 3};

        if (a_q_aa == b_q_aa)
            $display("PASS: a_q_aa == b_q_aa works for identical queues");
        else begin
            $display("FAIL: a_q_aa == b_q_aa returned false for identical queues");
            foreach (a_q_aa[i]) begin
                $display("a_q_aa[%0d] = %p", i, a_q_aa[i]);
            end
            foreach (b_q_aa[i]) begin
                $display("b_q_aa[%0d] = %p", i, b_q_aa[i]);
            end
        end

        b_q_aa[2] = '{1, 2, 4};
        if (a_q_aa != b_q_aa)
            $display("PASS: a_q_aa != b_q_aa works for different queues");
        else begin
            $display("FAIL: a_q_aa != b_q_aa returned false for different queues");
            foreach (a_q_aa[i]) begin
                $display("a_q_aa[%0d] = %p", i, a_q_aa[i]);
            end
            foreach (b_q_aa[i]) begin
                $display("b_q_aa[%0d] = %p", i, b_q_aa[i]);
            end
        end

        $finish;
    end
endmodule
