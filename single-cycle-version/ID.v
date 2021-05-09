// instruction decode stage
module ID(halt, EX_control, MA_control, WB_control, in_pc_inc2,rr_data1,rr_data2,
   imm_ext,dst_reg1,dst_reg2,dst_reg3, out_pc_inc2, instr, 
   reg_write, w_reg, w_data, clk, rst);
input clk, rst;
input [15:0] in_pc_inc2;
input [15:0] instr; //instr to decode
input [15:0] w_data; // data to write
input [2:0] w_reg; // specifies which reg to write to;
input reg_write; // write enable;

// input [1:0] imm_size;
output [15:0] rr_data1, rr_data2; // reg read data;
output [15:0] imm_ext;
output [2:0] dst_reg1, dst_reg2, dst_reg3; // candidate destination regs to write to
output halt; // should be combinational. !don't use reg!
output [14:0] EX_control;
output [8:0] MA_control;
output [2:0] WB_control;

output [15:0] out_pc_inc2;


//////////////////////Instruction Fetch(IF)///////////////////////
// reg pc_src; //0 for no branch/jump
// included in MA control
//////////////////////////////////////////////////////////////////

//////////////////////Decoding stage(ID)/////////////////////////
reg [1:0] imm_size; // 10 for 11bits, 01 for 8 bits,00 for 5 bits
reg zero_ext; // control for immediate extension

/////////////////////////////////////////////////////////////////

/////////////////////Execution stage(EX)/////////////////////////
reg reg_dst; 
reg [2:0] alu_op;
reg alu_cin, alu_invB, alu_invA, alu_sign;
reg alu_src;
reg alu_a_shift8; //shift input a by 8 bits
reg alu_out_sel; //sel for imm or alu_res
reg bit_reverse;
reg alu_clearB;
reg reg_dst_high;
reg jump; //this is shared with MA

assign EX_control = {jump,reg_dst_high, alu_clearB, bit_reverse,reg_dst, alu_op, alu_cin, alu_invA, alu_invB, alu_sign, alu_src, alu_a_shift8, alu_out_sel};
///////////////////////////////////////////////////////////////////

///////////////////////Mem access (MA)//////////////////////////////////
reg mem_read;
reg mem_write;
reg branch; // select signals for pc decision
reg pc_rs; // JR or JALR instruction
reg pc_src;
assign MA_control = {mem_read, pc_src, instr[12:11],mem_write,pc_rs,branch,jump,halt};
////////////////////////////////////////////////////////////////////

///////////////////////Write Back (WB)//////////////////////////////////
reg _reg_write; //control sig to pass down
reg[1:0] reg_src;
assign WB_control = {_reg_write, reg_src};

///////////////////////////////////////////////////////////////////

wire [15:0] imm_signed, imm_zero;

assign out_pc_inc2 = in_pc_inc2; // may change for optimization.

rf regfile(.read1data(rr_data1), .read2data(rr_data2), .err(),
           .clk(clk), .rst(rst), .read1regsel(instr[10:8]), .read2regsel(instr[7:5]),
            .writeregsel(w_reg), .writedata(w_data), .write(reg_write));

assign dst_reg1 = instr[7:5]; //default
assign dst_reg2 = instr[4:2];
assign dst_reg3 = instr[10:8];

// determine output imm_ext: 10 for long: 11 bits; 01 for mid: 8bits; 00 for short: 5bits.
assign imm_zero = imm_size[1] == 1'b1 ? {5'h00, instr[10:0]} :
                 imm_size[0] == 1'b1 ? {8'h00, instr[7:0]} : {11'h000, instr[4:0]};
assign imm_signed = imm_size[1] == 1'b1 ? {{5{instr[10]}}, instr[10:0]} :
                 imm_size[0] == 1'b1 ? {{8{instr[7]}}, instr[7:0]} : {{11{instr[4]}}, instr[4:0]};
assign imm_ext = zero_ext? imm_zero : imm_signed;
///////////////////////////////////////////////////////////////////////////////////////////

assign halt = rst ? 1'b0 : !(|instr[15:11]);
// dff halt_dff(.q(halt),.d(!(|instr[15:11])),.rst(rst),.clk(clk));

//control logic: 
always @(instr) begin
    // default:
    reg_dst = 1'b0;
    imm_size = 2'b11; // TODO: check if influence flow
    zero_ext = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    pc_rs = 1'b0;
    pc_src = 1'b0; //default to +2;
    mem_write = 1'b0;
    mem_read = 1'b0;
    _reg_write = 1'b0;
    reg_dst_high = 1'b0;

    reg_src = 2'b00;

    alu_sign = 1'b0;
    alu_cin = 1'b0;
    alu_src = 1'b0; //immediate
    alu_invB = 1'b0;
    alu_invA = 1'b0;
    alu_a_shift8 = 1'b0; //only SLBI will use this.
    alu_op = 3'b000;
    alu_out_sel = 1'b0;
    bit_reverse = 1'b0;
    alu_clearB = 1'b0;
    
    casex({instr[15:11]})
       5'b000xx: begin 
         pc_src = &instr[12:11];
       end// halt + nop or siic + NOP/RTI
       5'b001xx: begin // j-format and jr jalr
         imm_size = instr[11]? 2'b01 : 2'b10;
         pc_src = 1'b1;
         _reg_write = instr[12];
         reg_src = 2'b01; // pc_inc2
         reg_dst_high = 1'b1;

         pc_rs = instr[11]; // if 1: PC = rs + I
         jump = 1'b1;
         alu_src = 1'b0; //imm
         alu_op = 3'b000; //add
          
        end
       5'b010xx, 5'b101xx: begin // I-1: op rd, rs, imm
         imm_size = 2'b00;
         zero_ext = instr[12]? 1'b1 : 1'b0;
         _reg_write = 1'b1;
         //long_imm doesn't matter
         //alu control:
         alu_op = instr[13:11] == 3'b001 ? 3'b000 : instr[13:11];
         // alu_src = 1'b0;
         alu_cin = instr[12:11] == 2'b01; //subract = +~A + 1
         alu_invA = instr[13:11] == 3'b001; //invA for subraction
         alu_invB = instr[13:11] == 3'b011; //and ~imm

        end
       5'b011xx: begin // branch rs, imm
         imm_size = 2'b01;
         branch = 1'b1;
         pc_src = 1'b1;

         alu_clearB = 1'b1; //zero input B for judge rs
        //  alu_invB = 1'b1;
        //  alu_cin = 1'b1;
        //  alu_sign = 1'b1;

        end
       5'b10010: begin // SLBI Rs, Imm
         imm_size = 2'b01;
         zero_ext = 1'b1;
         alu_a_shift8 = 1'b1;
         alu_op = 3'b001; //or operation.
         reg_dst_high = 1'b1;
         _reg_write = 1'b1;
        end
       5'b100xx: begin // ST, LD, or STU
         imm_size = 2'b00;
         alu_op = 3'b000; // add
         mem_write = !(^instr[12:11]);
         _reg_write = instr[11];
         reg_dst_high = instr[12]; //see STU
         reg_src = &instr[12:11] ? 2'b00 : 2'b11;
         mem_read = ^instr[12:11];
        end
       5'b11000: begin // LBI Rs, imm 
         imm_size = 2'b01;
         alu_out_sel = 1'b1; //select imm directly
         reg_dst_high = 1'b1;
         _reg_write = 1'b1;


        end
       5'b110xx: begin // R-format: op rs rt rd op_ext
         reg_dst = 1'b1; // instr[4:2]
         bit_reverse = instr[12:11] == 2'b01; // reverse bits of rs
         _reg_write = 1'b1;

         alu_src = 1'b1;
         alu_op = {instr[11],instr[1:0]} == 3'b101 ? 3'b000 : {!instr[11],instr[1:0]}; // ternary for subtraction
         alu_invB = {instr[11],instr[1:0]} == 3'b111;

         alu_cin = {instr[11],instr[1:0]} == 3'b101;
         alu_invA = {instr[11],instr[1:0]} == 3'b101;
                  
        end
       5'b111xx: begin // R-format compare SEQ SLT SLE SCO end
         reg_dst = 1'b1;
         alu_src = 1'b1;
         _reg_write = 1'b1;

         reg_src = 2'b10; //write with ex_cond
         alu_cin = !(&instr[12:11]);
         alu_invB = !(&instr[12:11]);
         alu_sign = !(&instr[12:11]);
        end
       default: begin end
    endcase
end

endmodule