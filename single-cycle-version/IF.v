// module implementing the instruction fetch stage.
// not pipelined yet
module IF (pc_src, addr_res, instr, pc_inc2, halt, clk, rst);
  input clk,rst;
  input pc_src;
  input halt;
  input [15:0] addr_res; // calculated address for next instruction from ALU/branch
  
  output [15:0] instr, pc_inc2; // pc_inc2 = cur_addr + 2;

  wire [15:0] pc_cur, pc_next;
  

  //instantiate instruction memory. ignore addr and wr
  memory2c instr_mem(.data_out(instr),.data_in(16'h0000),.addr(pc_cur),.enable(~halt),.wr(1'b0),.createdump(halt),.clk(clk), .rst(rst));

  // pc. clears upon rst|| if halt, stop incrementing pc 
  dff pc[15:0](.q(pc_cur), .d(pc_next), .clk(clk), .rst(rst));
  assign pc_next = halt ? pc_cur : pc_src ? addr_res :pc_inc2;
  //adder that increments pc by 2
  //high Cout will signal the end of instr mem. currently ignore it.
  cla16 adder_2(.A(pc_cur),.B(16'h0002),.Cin(1'b0),.sum(pc_inc2),.Cout()); 
  

endmodule