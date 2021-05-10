module EX(in_EX_control, in_MA_control, in_WB_control, rr_data1, rr_data2,
    imm_ext, dst_reg1, dst_reg2, in_pc_inc2, clk, rst, out_MA_control, 
    out_WB_control, EX_out, out_pc_inc2, pc_add_imm, out_rr_data2, dst_reg3,
    zero, dst_reg, alu_cout, forw_MA_EX, forw_WB_EX, instr);
input clk, rst;
input [15:0] instr; //piped instr
input [15:0] rr_data1, rr_data2;
input [15:0] in_pc_inc2, imm_ext;
input [2:0] dst_reg1, dst_reg2, dst_reg3;
input [14:0] in_EX_control;
input [8:0] in_MA_control;
input [2:0] in_WB_control;

/////////////////////////////////////////////////////////////////
input [21:0] forw_MA_EX, forw_WB_EX;   //do not need to be piped
////////////////////////////////////////////////////////////////

output zero, alu_cout; 
output [2:0] dst_reg;
output [15:0] EX_out;
output [15:0] out_rr_data2; //forwarding
output [15:0] out_pc_inc2, pc_add_imm; //pc vals to select in next stage
output [8:0] out_MA_control;
output [2:0] out_WB_control;

//////////////////////////////////////////////////////////////////////////
//pipeline logic starts here
// output [14:0] EX_control_EX_ID;
wire [15:0] rr_data1_EX, rr_data2_EX, in_pc_inc2_EX, imm_ext_EX, instr_EX;
wire [2:0] dst_reg1_EX, dst_reg2_EX, dst_reg3_EX;
wire [14:0] in_EX_control_EX;
wire [8:0] in_MA_control_EX;
wire [2:0] in_WB_control_EX;

dff EX_ffA[15:0] (.q(instr_EX),.d(instr),.clk(clk),.rst(rst));
dff EX_ff0[15:0] (.q(rr_data1_EX),.d(rr_data1),.clk(clk),.rst(rst));
dff EX_ff1[15:0] (.q(rr_data2_EX),.d(rr_data2),.clk(clk),.rst(rst));
dff EX_ff2[15:0] (.q(in_pc_inc2_EX),.d(in_pc_inc2),.clk(clk),.rst(rst));
dff EX_ff3[15:0] (.q(imm_ext_EX),.d(imm_ext),.clk(clk),.rst(rst));
dff EX_ff4[2:0] (.q(dst_reg1_EX),.d(dst_reg1),.clk(clk),.rst(rst));
dff EX_ff5[2:0] (.q(dst_reg2_EX),.d(dst_reg2),.clk(clk),.rst(rst));
dff EX_ff6[2:0] (.q(dst_reg3_EX),.d(dst_reg3),.clk(clk),.rst(rst));
dff EX_ff7[14:0] (.q(in_EX_control_EX),.d(in_EX_control),.clk(clk),.rst(rst));
dff EX_ff8[8:0](.q(in_MA_control_EX),.d(in_MA_control),.clk(clk),.rst(rst));
dff EX_ff9[2:0](.q(in_WB_control_EX),.d(in_WB_control),.clk(clk),.rst(rst));

////////////////////////////////////////////////////////////////////////////

assign out_WB_control = in_WB_control_EX;
// assign EX_control_EX_ID = in_EX_control_EX;
assign out_MA_control = in_MA_control_EX;
assign out_pc_inc2 = in_pc_inc2_EX;

wire [15:0] alu_out;
wire [2:0] dst_reg_low;//low bit -> 7:5  4:2
wire [2:0] dst_reg_high;// high bit 10:8 or r7

////////////////////redistribute bus signal//////////////////
//{reg_dst, alu_op, alu_cin, alu_invA, alu_invB, alu_sign, alu_src, alu_a_shift8, alu_out_sel};

wire jump = in_EX_control_EX[14];
wire reg_dst_high = in_EX_control_EX[13];
wire alu_clearB = in_EX_control_EX[12];
wire bit_reverse = in_EX_control_EX[11];
wire reg_dst = in_EX_control_EX[10];
wire [2:0] alu_op = in_EX_control_EX[9:7];
wire alu_cin = in_EX_control_EX[6];
wire alu_invA = in_EX_control_EX[5];
wire alu_invB = in_EX_control_EX[4];
wire alu_sign = in_EX_control_EX[3];
wire alu_src = in_EX_control_EX[2];
wire alu_a_shift8 = in_EX_control_EX[1];
wire alu_out_sel = in_EX_control_EX[0];

wire [15:0] alu_a_forw, alu_b_forw; // holds reg value with forwarding.

/////////////////////////////////////////////////////////////

//forwarding logic goes here
// forw_MA_EX, forw_WB_EX;
// 20-6 data; 5-3 write dst reg;  2-0 {must be 00, regwrite}
// 10:8 rr1, 7:5 rr2
assign alu_a_forw = (instr_EX[10:8] == forw_MA_EX[5:3]) & (forw_MA_EX[2] == 1'b1) ? forw_MA_EX[21:6] :
                    (instr_EX[10:8] == forw_WB_EX[5:3]) & (forw_WB_EX[2] == 1'b1) ? forw_WB_EX[21:6] : rr_data1_EX;
assign alu_b_forw = (instr_EX[7:5] == forw_MA_EX[5:3]) & (forw_MA_EX[2] == 1'b1) ? forw_MA_EX[21:6] :
                    (instr_EX[7:5] == forw_WB_EX[5:3]) & (forw_WB_EX[2] == 1'b1) ? forw_WB_EX[21:6] : rr_data2_EX;

//reverse bits in rr_data1_EX, which is RS val
wire [15:0] reversed_rr_data1 = {alu_a_forw[0],alu_a_forw[1],alu_a_forw[2],alu_a_forw[3],alu_a_forw[4],alu_a_forw[5],alu_a_forw[6],alu_a_forw[7],
    alu_a_forw[8],alu_a_forw[9], alu_a_forw[10],alu_a_forw[11],alu_a_forw[12],alu_a_forw[13],alu_a_forw[14],alu_a_forw[15]};

alu main_alu(.A(alu_a_shift8? {alu_a_forw[7:0],8'h00} : alu_a_forw), .B(alu_src ? alu_b_forw : imm_ext_EX), .Cin(alu_cin), .Op(alu_op),
     .invA(alu_invA), .invB(alu_invB), .sign(alu_sign), .Out(alu_out), .Ofl(alu_cout), .Z(zero),.clearB(alu_clearB));

//add left-shift-1-bit immediate
cla16 pc_adder(.A(in_pc_inc2_EX),.B(imm_ext_EX[15:0]),.Cin(1'b0),.sum(pc_add_imm),.Cout());

assign EX_out = bit_reverse? reversed_rr_data1 : //note reversed_rr_data1 operates on forwarded operand already
                alu_out_sel? imm_ext_EX : alu_out;
assign dst_reg_low = reg_dst? dst_reg2_EX : dst_reg1_EX;
assign dst_reg_high = jump ? 3'b111 : dst_reg3_EX;
assign dst_reg = reg_dst_high ? dst_reg_high : dst_reg_low;
assign out_rr_data2 = alu_b_forw;

endmodule