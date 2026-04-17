`ifndef __CONTAINER_HANDLE_SVH__
`define __CONTAINER_HANDLE_SVH__

// 没有返回值的loop函数的接口参数
virtual class for_hdl_t #(type T = int);
    pure virtual function void apply(ref T item);
endclass

// 有返回值的map函数的接口参数
virtual class map_hdl_t #(type T_IN = byte, type T_OUT = int);
    pure virtual function T_OUT apply(ref T_IN key);
endclass

virtual class filter_hdl_t #(type T_IN = byte);
    pure virtual function bit apply(ref T_IN key);
endclass

`endif