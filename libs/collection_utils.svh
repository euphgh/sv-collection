`ifndef __COLLECTION_UTILS_SVH__
`define __COLLECTION_UTILS_SVH__

`include "collection_handler.svh"

class collection_utils#(type T_IN = int, type T_OUT = int);
    typedef T_OUT out_q_t [$];
    static function out_q_t q_map (
        const ref T_IN in_q [$],       // 输入容器
        map_hdl_t #(T_IN, T_OUT) m    // 转换策略对象
    );
        out_q_t out_q;
        out_q.delete(); // 清空输出
        foreach (in_q[i]) begin
            out_q.push_back(m.apply(in_q[i]));
        end
        return out_q;
    endfunction

    static function out_q_t q_filter (
        const ref T_IN in_q [$],       // 输入容器
        filter_hdl_t #(T_IN) f       // 过滤策略对象
    );
        out_q_t out_q;
        out_q.delete(); // 清空输出
        foreach (in_q[i]) begin
            if (f.apply(in_q[i])) begin
                out_q.push_back(in_q[i]);
            end
        end
        return out_q;
    endfunction

endclass

`endif