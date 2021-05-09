module EX(in_EX_control, in_MA_control, in_WB_control, rr_data1, rr_data2,
    imm_ext, dst_reg1, dst_reg2, in_pc_inc2, clk, rst, out_MA_control, 
    out_WB_control, EX_out, out_pc_inc2, pc_add_imm, out_rr_data2, dst_reg3,
    zero, dst_reg, alu_cout);
input clk, rst;
input [15:0] rr_data1, rr_data2;
input [15:0] in_pc_inc2, imm_ext;
input [2:0] dst_reg1, dst_reg2, dst_reg3;
input [14:0] in_EX_control;
input [8:0]in_MA_control;
input [2:0]in_WB_control;

output zero, alu_cout; 
output [2:0] dst_reg;
output [15:0] EX_out;
output [15:0] out_rr_data2; //forwarding
output [15:0] out_pc_inc2, pc_add_imm; //pc vals to select in next stage
output [8:0] out_MA_control;
output [2:0] out_WB_control;

assign out_WB_control = in_WB_control;
assign out_MA_control = in_MA_control;
assign out_pc_inc2 = in_pc_inc2;

wire [15:0] alu_out;
wire [2:0] dst_reg_low;//low bit -> 7:5  4:2
wire [2:0] dst_reg_high;// high bit 10:8 or r7
//reverse bits in rr_data1, which is RS val
wire [15:0] reversed_rr_data1 = {rr_data1[0],rr_data1[1],rr_data1[2],rr_data1[3],rr_data1[4],rr_data1[5],rr_data1[6],rr_data1[7],
    rr_data1[8],rr_data1[9], rr_data1[10],rr_data1[11],rr_data1[12],rr_data1[13],rr_data1[14],rr_data1[15]};

////////////////////redistribute bus signal//////////////////
//{reg_dst, alu_op, alu_cin, alu_invA, alu_invB, alu_sign, alu_src, alu_a_shift8, alu_out_sel};

wire jump = in_EX_control[14];
wire reg_dst_high = in_EX_control[13];
wire alu_clearB = in_EX_control[12];
wire bit_reverse = in_EX_control[11];
wire reg_dst = in_EX_control[10];
wire [2:0] alu_op = in_EX_control[9:7];
wire alu_cin = in_EX_control[6];
wire alu_invA = in_EX_control[5];
wire alu_invB = in_EX_control[4];
wire alu_sign = in_EX_control[3];
wire alu_src = in_EX_control[2];
wire alu_a_shift8 = in_EX_control[1];
wire alu_out_sel = in_EX_control[0];

/////////////////////////////////////////////////////////////

alu main_alu(.A(alu_a_shift8? {rr_data1[7:0],8'h00} : rr_data1), .B(alu_src ? rr_data2 : imm_ext), .Cin(alu_cin), .Op(alu_op),
     .invA(alu_invA), .invB(alu_invB), .sign(alu_sign), .Out(alu_out), .Ofl(alu_cout), .Z(zero),.clearB(alu_clearB));

//add left-shift-1-bit immediate
cla16 pc_adder(.A(in_pc_inc2),.B(imm_ext[15:0]),.Cin(1'b0),.sum(pc_add_imm),.Cout());
// alu pc_alu(.A(in_pc_inc2), .B({imm_ext[14:0],1'b0}), .Cin(1'b0), .Op(3'b000), .invA(1'b0), .invB(1'b0), .sign(1'b1), .Out(pc_add_imm), .Ofl(), .Z());

assign EX_out = bit_reverse? reversed_rr_data1 :
                alu_out_sel? imm_ext : alu_out;
assign dst_reg_low = reg_dst? dst_reg2 : dst_reg1;
assign dst_reg_high = jump ? 3'b111 : dst_reg3;
assign dst_reg = reg_dst_high ? dst_reg_high : dst_reg_low;
assign out_rr_data2 = rr_data2;

endmodule