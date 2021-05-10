module MA (in_MA_control, in_WB_control,zero,in_EX_out,in_pc_inc2, pc_add_imm,
    in_dst_reg,out_WB_control, out_EX_out, forw_MA_EX,
    out_dst_reg, mr_data,rr_data2, clk,rst, alu_cout,
    pc_next, out_pc_inc2,ex_cond, pc_src, stall, stall_MA_EX);

input clk, rst;
input zero;
input [15:0] in_EX_out, in_pc_inc2, pc_add_imm;
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
output [21:0] forw_MA_EX;
output stall, stall_MA_EX;

//////////////////////////////////////////////////////////////////////////
//pipeline logic starts here
wire [15:0] in_EX_out_MA, in_pc_inc2_MA,pc_add_imm_MA, rr_data2_MA;
wire zero_MA, alu_cout_MA;
wire [8:0] in_MA_control_MA;
wire [2:0] in_WB_control_MA, in_dst_reg_MA;

dff MA_ff0[15:0](.q(in_EX_out_MA),.d(in_EX_out),.clk(clk),.rst(rst));
dff MA_ff1[15:0](.q(in_pc_inc2_MA),.d(in_pc_inc2),.clk(clk),.rst(rst));
dff MA_ff2[15:0](.q(pc_add_imm_MA),.d(pc_add_imm),.clk(clk),.rst(rst));
dff MA_ff3[15:0](.q(rr_data2_MA),.d(rr_data2),.clk(clk),.rst(rst));
dff MA_ff4[8:0](.q(in_MA_control_MA),.d(in_MA_control),.clk(clk),.rst(rst));
dff MA_ff5[2:0](.q(in_WB_control_MA),.d(in_WB_control),.clk(clk),.rst(rst));
dff MA_ff6[2:0](.q(in_dst_reg_MA),.d(in_dst_reg),.clk(clk),.rst(rst));
dff MA_ff7(.q(alu_cout_MA),.d(alu_cout),.clk(clk),.rst(rst));
dff MA_ff8(.q(zero_MA),.d(zero),.clk(clk),.rst(rst));


/////////////////////////////////////////////////////////////////////////
wire branching; //combined signal for branching: == branch & ex_cond 
wire b_cond, s_cond;//b_cond for branch, s_cond for set conditions 

//////////////////// parse bus MA_control /////////////////
//{mem_write,pc_rs,branch,jump,halt};
wire mem_read = in_MA_control_MA[8];

wire [1:0] comp_sel = in_MA_control_MA[6:5]; //instr[12:11];
wire mem_write = in_MA_control_MA[4];
wire pc_rs = in_MA_control_MA[3];
wire branch = in_MA_control_MA[2];
wire jump = in_MA_control_MA[1];
wire halt = in_MA_control_MA[0];


wire stall0, stall1, stall2, stall3;
assign stall0 = stall1 | stall2 | stall3 ? 1'b0 : (pc_rs | branching |jump); //prevent stalling from instr that should be stalled
assign stall = stall1 | stall2 | stall3;
assign stall_MA_EX = stall0 | stall1;

dff bubble1(.q(stall1),.d(stall0),.clk(clk),.rst(rst));
dff bubble2(.q(stall2),.d(stall1),.clk(clk),.rst(rst));
dff bubble3(.q(stall3),.d(stall2),.clk(clk),.rst(rst));
///////////////////////////////////////////////////////////
// wr mem_write clears if jump or branch succeeded.
memory2c data_mem(.data_out(mr_data), .data_in(rr_data2_MA), .addr(in_EX_out_MA), .enable((mem_read | mem_write) & !stall),
 .wr(mem_write), .createdump(halt & !stall), .clk(clk), .rst(rst));

assign ex_cond = branch ? b_cond : s_cond;
assign b_cond = comp_sel == 2'b11 ? !(in_EX_out_MA[15]) :
                comp_sel == 2'b10 ? in_EX_out_MA[15] :
                comp_sel == 2'b01 ? !zero_MA : zero_MA;
assign s_cond = comp_sel == 2'b11 ? alu_cout_MA :
                comp_sel == 2'b10 ? ((in_EX_out_MA[15] & !alu_cout_MA) | (alu_cout_MA & !in_EX_out_MA[15])) | zero_MA : //<= rt
                comp_sel == 2'b01 ? ((in_EX_out_MA[15] & !alu_cout_MA) | (alu_cout_MA & !in_EX_out_MA[15])) : zero_MA;  //<rt 

assign branching = ex_cond & branch;
assign pc_next = pc_rs ? in_EX_out_MA :
                 (branching | jump) ? pc_add_imm_MA : in_pc_inc2_MA;

assign out_WB_control = stall1 | stall2 | stall3 ? {1'b0, in_WB_control_MA[1:0]} : in_WB_control_MA;
assign out_pc_inc2 = in_pc_inc2_MA;
assign out_EX_out = in_EX_out_MA;
assign out_dst_reg = in_dst_reg_MA;

assign forw_MA_EX = {in_WB_control_MA[1:0] == 2'b10 ? {15'h0000, ex_cond} :in_EX_out_MA, in_dst_reg_MA, out_WB_control};


assign pc_src = (branch & !branching | stall) ? 1'b0 : in_MA_control_MA[7];

//branching logic


endmodule