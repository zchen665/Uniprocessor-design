module WB(alu_out,pc_inc2,ex_cond,mr_data,in_WB_control,dst_reg
    ,clk,rst, reg_write, out_dst_reg, rw_data);
input clk, rst;
input [15:0] alu_out,pc_inc2,mr_data;
input ex_cond;
input [2:0] dst_reg;
input [2:0] in_WB_control;

output [15:0] rw_data;
output reg_write;
output [2:0] out_dst_reg;
/////parse
wire [1:0] reg_src = in_WB_control[1:0];
assign reg_write = in_WB_control[2];
assign out_dst_reg = dst_reg;
assign rw_data = reg_src == 2'b11 ? mr_data :
                 reg_src == 2'b10 ? {15'h0000, ex_cond} :
                 reg_src == 2'b01 ? pc_inc2 : alu_out;


endmodule