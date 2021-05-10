module WB(alu_out,pc_inc2,ex_cond,mr_data,in_WB_control,dst_reg
    ,clk,rst, reg_write, out_dst_reg, rw_data, forw_WB_EX);
input clk, rst;
input [15:0] alu_out,pc_inc2,mr_data;
input ex_cond;
input [2:0] dst_reg;
input [2:0] in_WB_control;

output [15:0] rw_data;
output reg_write;
output [2:0] out_dst_reg;

output [21:0] forw_WB_EX;

/////////////////////////////////////////////////////////////////////
// pipeline logic 
wire [15:0] alu_out_WB,pc_inc2_WB,mr_data_WB;
wire [2:0] dst_reg_WB, in_WB_control_WB;
wire ex_cond_WB;

dff WB_ff0[15:0] (.q(alu_out_WB),.d(alu_out),.clk(clk),.rst(rst));
dff WB_ff1[15:0] (.q(pc_inc2_WB),.d(pc_inc2),.clk(clk),.rst(rst));
dff WB_ff2[15:0] (.q(mr_data_WB),.d(mr_data),.clk(clk),.rst(rst));
dff WB_ff3 (.q(ex_cond_WB),.d(ex_cond),.clk(clk),.rst(rst));
dff WB_ff4[2:0] (.q(dst_reg_WB),.d(dst_reg),.clk(clk),.rst(rst));
dff WB_ff5[2:0] (.q(in_WB_control_WB),.d(in_WB_control),.clk(clk),.rst(rst));

/////////////////////////////////////////////////////////////////////

/////parse
wire [1:0] reg_src = in_WB_control_WB[1:0];
assign reg_write = in_WB_control_WB[2];
assign out_dst_reg = dst_reg_WB;
assign rw_data = reg_src == 2'b11 ? mr_data_WB :
                 reg_src == 2'b10 ? {15'h0000, ex_cond_WB} :
                 reg_src == 2'b01 ? pc_inc2_WB : alu_out_WB;

assign forw_WB_EX = {rw_data, dst_reg_WB, in_WB_control_WB};


endmodule