// module implementing the instruction fetch stage.
// not pipelined yet
module IF (pc_src, addr_res, instr, stall, RAW_stall, pc_inc2, halt,
pc_inc2_MA_IF, clk, rst);
  input clk,rst;
  input pc_src;
  input halt, stall, RAW_stall;
  // input [1:0] siic_rti;
  input [15:0] addr_res, pc_inc2_MA_IF; // calculated address for next instruction from ALU/branch
  // input instr_ID_IF;
  output [15:0] instr, pc_inc2; // pc_inc2 = cur_addr + 2;

  wire [15:0] pc_cur, pc_next;
  wire [15:0] instr_rd;
  wire halt1,halt2,halt_pipe, halt3; // need to pipe halt for 3 cycles;
  wire [15:0] EPC_in, EPC_out;
  wire [1:0] sr1,sr2;

  // dff epc[15:0](.q(EPC_out), .d(EPC_in), .clk(clk), .rst(rst));
  
  // dff siic0[1:0](.q(sr1),.d(siic_rti),.clk(clk),.rst(rst));
  // dff siic1[1:0](.q(sr2),.d(sr1),.clk(clk),.rst(rst));
  // // assign EPC_in = sr2 == 2'b10 ? pc_inc2_MA_IF : EPC_out;
  
  dff ff_halt0(.q(halt1),.d(halt),.clk(clk),.rst(rst));
  dff ff_halt1(.q(halt2),.d(halt1),.clk(clk),.rst(rst));
  dff ff_halt2(.q(halt_pipe),.d(halt2),.clk(clk),.rst(rst));
  assign halt3 = halt_pipe & !stall;

  //instantiate instruction memory. 
  memory2c instr_mem(.data_out(instr_rd),.data_in(16'h0000),.addr(pc_cur),.enable(~halt3),.wr(1'b0),.createdump(halt3),.clk(clk), .rst(rst));

  // pc. clears upon rst|| if halt3, stop incrementing pc 
  dff pc[15:0](.q(pc_cur), .d(pc_next), .clk(clk), .rst(rst));

  assign pc_next = halt3 ? pc_cur : 
                  // sr2 == 2'b10 ? 16'h0002 :
                  // sr2 == 2'b11 ? EPC_out :
                  pc_src ? addr_res : 
                  RAW_stall & !stall ? pc_cur : pc_inc2;

  // assign instr = RAW_stall & !stall ? instr_ID_IF : instr_rd;
  assign instr = instr_rd;
  //adder that increments pc by 2
  //high Cout will signal the end of instr mem. currently ignore it.
  cla16 adder_2(.A(pc_cur),.B(16'h0002),.Cin(1'b0),.sum(pc_inc2),.Cout()); 
  

endmodule