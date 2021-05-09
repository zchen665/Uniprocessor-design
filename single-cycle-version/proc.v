/* $Author: karu $ */
/* $LastChangedDate: 2009-03-04 23:09:45 -0600 (Wed, 04 Mar 2009) $ */
/* $Rev: 45 $ */
module proc (/*AUTOARG*/
   // Outputs
   err, 
   // Inputs
   clk, rst
   );

   input clk;
   input rst;

   output err;

   // None of the above lines can be modified

   // OR all the err ouputs for every sub-module and assign it as this
   // err output
   
   // As desribed in the homeworks, use the err signal to trap corner
   // cases that you think are illegal in your statemachines

   wire halt;
   wire [15:0] instr;
   wire pc_src;
   wire [15:0] pc_next, pc_inc2_IF_ID,pc_inc2_ID_EX, pc_inc2_EX_MA, pc_inc2_MA_WB;

   wire [14:0] EX_control;
   wire [8:0] MA_control_ID_EX, MA_control_EX_MA;
   wire [2:0] WB_control_ID_EX, WB_control_EX_MA, WB_control_MA_WB;
   wire [15:0] rr_data1,rr_data2_ID_EX, rr_data2_EX_MA;
   wire [15:0] imm_ext_ID_EX;
   wire [2:0] dst_reg1, dst_reg2, dst_reg3;

   wire [15:0] EX_out_EX_MA, EX_out_MA_WB;
   wire [15:0] pc_add_imm;
   wire zero, alu_cout;
   wire [2:0] dst_reg_EX_MA, dst_reg_MA_WB, dst_reg_WB_ID;

   wire [15:0] mr_data;

   wire ex_cond;

   wire reg_write; //shared between WB and ID 
   wire [15:0] rw_data_WB_ID;


   IF instr_fetch(.pc_src(pc_src), .addr_res(pc_next), .instr(instr), .pc_inc2(pc_inc2_IF_ID), .halt(halt), .clk(clk), .rst(rst));

   ID instr_decoding(.halt(halt), .EX_control(EX_control), .MA_control(MA_control_ID_EX), .WB_control(WB_control_ID_EX), .in_pc_inc2(pc_inc2_IF_ID),
      .rr_data1(rr_data1),.rr_data2(rr_data2_ID_EX), .imm_ext(imm_ext_ID_EX),.dst_reg1(dst_reg1),.dst_reg2(dst_reg2),.dst_reg3(dst_reg3), 
      .out_pc_inc2(pc_inc2_ID_EX), .instr(instr), .reg_write(reg_write), .w_reg(dst_reg_WB_ID), .w_data(rw_data_WB_ID), .clk(clk), .rst(rst));

   EX execution(.in_EX_control(EX_control), .in_MA_control(MA_control_ID_EX), .in_WB_control(WB_control_ID_EX), .rr_data1(rr_data1), .rr_data2(rr_data2_ID_EX),
    .imm_ext(imm_ext_ID_EX), .dst_reg1(dst_reg1), .dst_reg2(dst_reg2), .dst_reg3(dst_reg3), .in_pc_inc2(pc_inc2_ID_EX), .clk(clk), .rst(rst), .out_MA_control(MA_control_EX_MA), 
    .out_WB_control(WB_control_EX_MA), .EX_out(EX_out_EX_MA), .out_pc_inc2(pc_inc2_EX_MA), .pc_add_imm(pc_add_imm), .out_rr_data2(rr_data2_EX_MA), 
    .zero(zero), .dst_reg(dst_reg_EX_MA), .alu_cout(alu_cout));
   
   MA mem_access(.in_MA_control(MA_control_EX_MA), .in_WB_control(WB_control_EX_MA),.zero(zero),.in_EX_out(EX_out_EX_MA),.in_pc_inc2(pc_inc2_EX_MA), .pc_add_imm(pc_add_imm),
    .out_WB_control(WB_control_MA_WB),.in_dst_reg(dst_reg_EX_MA), .out_EX_out(EX_out_MA_WB), .out_dst_reg(dst_reg_MA_WB), 
    .mr_data(mr_data),.rr_data2(rr_data2_EX_MA), .clk(clk),.rst(rst), .alu_cout(alu_cout), .pc_next(pc_next), .out_pc_inc2(pc_inc2_MA_WB), 
    .ex_cond(ex_cond), .pc_src(pc_src));

   WB write_back(.alu_out(EX_out_MA_WB),.pc_inc2(pc_inc2_MA_WB),.ex_cond(ex_cond),.mr_data(mr_data),.in_WB_control(WB_control_MA_WB),.dst_reg(dst_reg_MA_WB),
    .clk(clk),.rst(rst), .reg_write(reg_write), .out_dst_reg(dst_reg_WB_ID), .rw_data(rw_data_WB_ID));


   
   
endmodule // proc
// DUMMY LINE FOR REV CONTROL :0:
