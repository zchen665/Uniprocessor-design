module MA (in_MA_control, in_WB_control,zero,in_EX_out,in_pc_inc2, pc_add_imm,
    in_dst_reg,out_WB_control, out_EX_out,
    out_dst_reg, mr_data,rr_data2, clk,rst, alu_cout,
    pc_next, out_pc_inc2,ex_cond, pc_src);

input clk, rst;
input zero;
input [15:0] in_EX_out, in_pc_inc2,pc_add_imm;
input [15:0] rr_data2;
input [8:0] in_MA_control;
input [2:0] in_WB_control;
input [2:0] in_dst_reg;
input alu_cout;

output [2:0] out_dst_reg;
output [2:0] out_WB_control;
output [15:0] out_EX_out, mr_data;
output [15:0] pc_next, out_pc_inc2; //pc_next wired to IF
output ex_cond;
output pc_src;

wire branching; //combined signal for branching: == branch & ex_cond 
wire b_cond, s_cond;//b_cond for branch, s_cond for set conditions 

//////////////////// parse bus MA_control /////////////////
//{mem_write,pc_rs,branch,jump,halt};
wire mem_read = in_MA_control[8];
assign pc_src = in_MA_control[7];
// dff pc_src_ff(.q(pc_src),.d(in_MA_control[7]),.clk(clk),.rst(rst));
wire [1:0] comp_sel = in_MA_control[6:5]; //instr[12:11];
wire mem_write = in_MA_control[4];
wire pc_rs = in_MA_control[3];
wire branch = in_MA_control[2];
wire jump = in_MA_control[1];
wire halt = in_MA_control[0];

///////////////////////////////////////////////////////////

memory2c data_mem(.data_out(mr_data), .data_in(rr_data2), .addr(in_EX_out), .enable(mem_read | mem_write), .wr(mem_write), .createdump(halt), .clk(clk), .rst(rst));

assign ex_cond = branch ? b_cond : s_cond;
assign b_cond = comp_sel == 2'b11 ? !(in_EX_out[15]) :
                comp_sel == 2'b10 ? in_EX_out[15] :
                comp_sel == 2'b01 ? !zero : zero;
assign s_cond = comp_sel == 2'b11 ? alu_cout :
                comp_sel == 2'b10 ? ((in_EX_out[15] & !alu_cout) | (alu_cout & !in_EX_out[15])) | zero : //<= rt
                comp_sel == 2'b01 ? ((in_EX_out[15] & !alu_cout) | (alu_cout & !in_EX_out[15])) : zero;  //<rt 

assign branching = ex_cond & branch;
assign pc_next = pc_rs ? in_EX_out :
                 (branching | jump) ? pc_add_imm : in_pc_inc2;

assign out_WB_control = in_WB_control;
assign out_pc_inc2 = in_pc_inc2;
assign out_EX_out = in_EX_out;
assign out_dst_reg = in_dst_reg;
endmodule