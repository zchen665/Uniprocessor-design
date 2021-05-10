/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err, 
   // Inputs
   Addr, DataIn, Rd, Wr, createdump, clk, rst
   );
   
   input [15:0] Addr;
   input [15:0] DataIn;
   input        Rd;
   input        Wr;
   input        createdump;
   input        clk;
   input        rst;
   
   output reg [15:0] DataOut;
   output reg Done;
   output reg Stall;
   output reg CacheHit;
   output err;

   localparam [4:0]  IDLE = 5'h00,
                     READ = 5'h01,
                     MISS = 5'h02,
                     L1 = 5'h03,
                     L2 = 5'h04,
                     L3 = 5'h05,
                     L4 = 5'h06,
                     L_stall = 5'h07,
                     W2 = 5'h09,
                     W3 = 5'h0a,
                     W4 = 5'h0b,
                     W_stall = 5'h0c,
                     LD_DONE = 5'h0f,
                     L_stall2 = 5'h11,
                     WR_DONE = 5'h1f;

   //store the signals currently working on and block incoming signals.
   reg [4:0] nxt_state;
   wire[4:0] state;
   wire cur_rd, cur_wr,vic_way;
   wire [15:0] cur_datain, cur_addr;
   reg ld_way;

   dff state_ff[4:0](.d(nxt_state),.q(state),.clk(clk),.rst(rst));
   dff data_ff[15:0](.d(state!=IDLE? cur_datain : DataIn),.q(cur_datain),.clk(clk),.rst(rst));
   dff addr_ff[15:0](.d(state!=IDLE? cur_addr : Addr),.q(cur_addr),.clk(clk),.rst(rst));
   dff RD_ff(.d(state!=IDLE? cur_rd : Rd),.q(cur_rd),.clk(clk),.rst(rst));
   dff WR_ff(.d(state!=IDLE? cur_wr : Wr),.q(cur_wr),.clk(clk),.rst(rst));
   //flip vic_way on each read or write
   dff vic_way_dff(.d(state == IDLE && nxt_state != IDLE && Rd|Wr ? ~vic_way : vic_way), .q(vic_way), .clk(clk),.rst(rst));

   //state machine signals.
   reg sys_err;

   // cache
   reg c_comp, c_write, c_validin, c0_enable, c1_enable;
   wire [4:0] c0_tag_out, c1_tag_out;
   wire [15:0] c0_data_out, c1_data_out;
   wire c0_valid, c1_valid, c0_dirty, c1_dirty, c0_err, c1_err, c0_hit, c1_hit;
   reg[15:0] c_datain;
   reg[4:0] c_tagin; //cur_addr[15:11]
   reg[2:0] c_offset; 

   wire hit = c0_hit | c1_hit;
   wire full = c0_valid & c1_valid;

   reg [15:0] vic_data;
   reg [4:0] vic_tag;

   //mem
   wire[15:0] m_data_out;
   wire m_stall, m_err;
   reg [15:0] m_addr, m_data_in;
   reg m_wr, m_rd;
   // wire[3:0] busy;

   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (c0_tag_out),
                          .data_out             (c0_data_out),
                          .hit                  (c0_hit),
                          .dirty                (c0_dirty),
                          .valid                (c0_valid),
                          .err                  (c0_err),
                          // Inputs
                          .enable               (c0_enable),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (c_tagin),
                          .index                (state == IDLE ? Addr[10:3] : cur_addr[10:3]),
                          .offset               (c_offset),
                          .data_in              (c_datain),
                          .comp                 (c_comp),
                          .write                (c_write),
                          .valid_in             (c_validin));
   cache #(2 + memtype) c1(// Outputs
                          .tag_out              (c1_tag_out),
                          .data_out             (c1_data_out),
                          .hit                  (c1_hit),
                          .dirty                (c1_dirty),
                          .valid                (c1_valid),
                          .err                  (c1_err),
                          // Inputs
                          .enable               (c1_enable),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (c_tagin),
                          .index                (state == IDLE ? Addr[10:3] : cur_addr[10:3]),
                          .offset               (c_offset),
                          .data_in              (c_datain),
                          .comp                 (c_comp),
                          .write                (c_write),
                          .valid_in             (c_validin));

   four_bank_mem mem(// Outputs
                     .data_out          (m_data_out),
                     .stall             (m_stall),
                     .busy              (),//don't care
                     .err               (m_err),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (m_addr),
                     .data_in           (m_data_in),
                     .wr                (m_wr),
                     .rd                (m_rd));
   
   
   always @(state,cur_addr, Wr, Rd,c0_valid, c1_valid, hit, c0_data_out,c1_data_out, c0_tag_out,c1_tag_out,
   c0_dirty, c1_dirty, Done,full) begin
      Stall = 1'b1;
      CacheHit = 1'b0;
      nxt_state = IDLE;
      Done = 1'b0;
      c0_enable = 1'b0;
      c1_enable = 1'b0;
      c_comp = 1'b0;
      c_write = 1'b0;
      c_validin = 1'b0;
      m_rd = 1'b0;
      m_wr = 1'b0;
      m_addr = {cur_addr[15:3], 3'b000};
      sys_err = 1'b0;
      ld_way = Done? 1'b0 : ld_way;

      case(state) 
        IDLE: begin
           Stall = Wr | Rd;
           nxt_state = Wr | Rd ? READ : IDLE;
           

        end
        READ: begin
           c0_enable = cur_rd | cur_wr;
           c1_enable = cur_rd | cur_wr;
           c_comp = cur_rd | cur_wr;
           c_write = cur_wr;
           c_datain = cur_datain;
           c_tagin = cur_addr[15:11];
           c_offset = cur_addr[2:0];
           // hit?
           Done = (c0_hit & c0_valid) | (c1_hit & c1_valid);
           nxt_state =  Done  ?    IDLE : //cache hit
                        !full ?      L1 : MISS ; // if not valid, don't care about that tag
           CacheHit = Done;
           Stall = !Done;
           DataOut = !Done ? 16'h0000 : c0_hit? c0_data_out : c1_data_out;
           ld_way = full? vic_way : c0_valid;
        end
        MISS: begin //get info about the victim cache: comp = 0, write = 0;
           // cache is full. need to victimize one cacheline
           c0_enable = !vic_way;
           c1_enable = vic_way;
           c_tagin = cur_addr[15:11];
           c_offset = 3'b000;
           //it must be valid to reach this state
           vic_data = vic_way? c1_data_out : c0_data_out;
           vic_tag = vic_way?  c1_tag_out : c0_tag_out;

           nxt_state = vic_way?  c1_dirty & c1_valid ? W2 : L1 : 
                                 c0_dirty & c0_valid ? W2 : L1;
                      
           m_wr = (c1_dirty & c1_valid) | (c0_dirty & c0_valid);
           m_data_in = vic_way? c1_data_out : c0_data_out;
           m_addr = {vic_way?  c1_tag_out : c0_tag_out, cur_addr[10:3], 3'b000}; //1st word
        end
        L1: begin
           m_rd = 1'b1;
           m_addr = {cur_addr[15:3], 3'b000}; //1st word
           nxt_state = L2;
        end
        L2: begin
           m_rd = 1'b1;
           m_addr = {cur_addr[15:3], 3'b010}; //2nd
           nxt_state = L3;
        end
        L3: begin
           m_rd = 1'b1;
           m_addr = {cur_addr[15:3], 3'b100}; //3rd
           nxt_state = L4;
           //the 1st word is ready
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_write = 1'b1; //comp =1 ; write =1 access write
           c_tagin = cur_addr[15:11];
           c_offset = 3'b000; 
           c_validin = 1'b1; //may only need at last
           c_datain = m_data_out;

        end
        L4: begin
           m_rd = 1'b1;
           m_addr = {cur_addr[15:3], 3'b110}; //4th
           nxt_state = L_stall;
           //the 2nd word is ready
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_write = 1'b1; //comp =1 ; write =1 access write
           c_tagin = cur_addr[15:11];
           c_offset = 3'b010; 
           c_validin = 1'b1;
           c_datain = m_data_out;
        end
        L_stall: begin
           nxt_state = L_stall2;
           //the 3rd word is ready
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_write = 1'b1; //comp =1 ; write =1 access write
           c_tagin = cur_addr[15:11];
           c_offset = 3'b100; 
           c_validin = 1'b1;
           c_datain = m_data_out;
        end
        L_stall2: begin
           nxt_state = LD_DONE;
           
           //the 4th word is ready
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_write = 1'b1; //comp =1 ; write =1 access write
           c_tagin = cur_addr[15:11];
           c_offset = 3'b110; 
           c_validin = 1'b1;
           c_datain = m_data_out;
        end
        LD_DONE: begin
           // if write then one more state is needed to update
           // the cache content. or perform write.
           nxt_state = cur_wr? WR_DONE : IDLE; 
           c0_enable = !ld_way ? cur_rd : 1'b0;
           c1_enable = ld_way ? cur_rd : 1'b0;
           c_comp = 1'b1;
           c_tagin = cur_addr[15:11];
           c_offset = cur_addr[2:0];
           DataOut = cur_rd? ld_way? c1_data_out : c0_data_out : 16'h0000; 
           Done = cur_rd;
           Stall = cur_wr;
        end
        W2: begin
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_offset = 3'b010;
           m_wr = 1'b1;
           m_data_in = ld_way? c1_data_out: c0_data_out;
           m_addr = {vic_tag, cur_addr[10:3], 3'b010}; //2nd word
           nxt_state = W3;
        end
        W3: begin
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_offset = 3'b100;
           m_wr = 1'b1;
           m_data_in = ld_way? c1_data_out: c0_data_out;
           m_addr = {vic_tag, cur_addr[10:3], 3'b100}; //3rd word
           nxt_state = W4;
        end
        W4: begin
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_offset = 3'b110;
           m_wr = 1'b1;
           m_data_in = ld_way? c1_data_out: c0_data_out;
           m_addr = {vic_tag, cur_addr[10:3], 3'b110}; //3rd word
           nxt_state = L1;
        end
        W_stall: begin
           //stall state 
           nxt_state = L1;
        end
        WR_DONE: begin //data should be in cache now. simply update it
           c0_enable = !ld_way;
           c1_enable = ld_way;
           c_comp = 1'b1;
           c_write = 1'b1;
           c_datain = cur_datain;
           c_tagin = cur_addr[15:11];
           c_offset = cur_addr[2:0];
         //   sys_err = !(hit && valid); //error checking
           nxt_state = IDLE;
           Done = 1'b1;
           Stall = 1'b0;
        end
        default:sys_err = 1'b1;

      endcase
      
   end
   assign err = c1_err | m_err |c0_err|sys_err;
   
endmodule // mem_system

   


// DUMMY LINE FOR REV CONTROL :9:
