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
   
   output [15:0] DataOut;
   output reg Done;
   output reg Stall;
   output reg CacheHit;
   output err;

   localparam [4:0]  IDLE = 5'h00,
                     // READ = 5'h01,
                     MISS = 5'h02,
                     L1 = 5'h03,
                     L2 = 5'h04,
                     L3 = 5'h05,
                     L4 = 5'h06,
                     L_stall = 5'h07,
                     // W1 = 5'h08,
                     W2 = 5'h09,
                     W3 = 5'h0a,
                     W4 = 5'h0b,
                     W_stall = 5'h0c,
                     // WRITE=  5'h0d,
                     LD_DONE = 5'h0f,
                     L_stall2 = 5'h11,
                     WR_DONE = 5'h1f;

   //store the signals currently working on and block incoming signals.
   reg [4:0] nxt_state;
   wire[4:0] state;
   wire cur_rd, cur_wr;
   wire [15:0] cur_datain, cur_addr;

   dff state_ff[4:0](.d(nxt_state),.q(state),.clk(clk),.rst(rst));
   dff data_ff[15:0](.d(state!=IDLE? cur_datain : DataIn),.q(cur_datain),.clk(clk),.rst(rst));
   dff addr_ff[15:0](.d(state!=IDLE? cur_addr : Addr),.q(cur_addr),.clk(clk),.rst(rst));
   dff RD_ff(.d(state!=IDLE? cur_rd : Rd),.q(cur_rd),.clk(clk),.rst(rst));
   dff WR_ff(.d(state!=IDLE? cur_wr : Wr),.q(cur_wr),.clk(clk),.rst(rst));


   //state machine signals.
   reg sys_err;

   // cache
   reg c_comp, c_write, c_validin, c_enable;
   wire [4:0] tag_out;
   wire [15:0] c_data_out;
   wire valid, dirty, c_err, hit;
   reg[15:0] c_datain;
   reg[4:0] c_tagin; //cur_addr[15:11]
   reg[2:0] c_offset; 

   reg [15:0] vic_data;
   reg [4:0] vic_tag;
   // reg vic_valid, vic_dirty;

   //mem
   wire[15:0] m_data_out;
   wire m_stall, m_err;
   reg [15:0] m_addr, m_data_in;
   reg m_wr, m_rd;
   wire[3:0] busy;


   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (tag_out),
                          .data_out             (c_data_out),
                          .hit                  (hit),
                          .dirty                (dirty),
                          .valid                (valid),
                          .err                  (c_err),
                          // Inputs
                          .enable               (c_enable),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (c_tagin),
                          .index                (state == IDLE ? Addr[10:3] : cur_addr[10:3]), //should always
                          // be this during the same operation
                          .offset               (c_offset),
                          .data_in              (c_datain),
                          .comp                 (c_comp),
                          .write                (c_write),
                          .valid_in             (c_validin));

   four_bank_mem mem(// Outputs
                     .data_out          (m_data_out),
                     .stall             (m_stall),
                     .busy              (busy),
                     .err               (m_err),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (m_addr),
                     .data_in           (m_data_in),
                     .wr                (m_wr),
                     .rd                (m_rd));

   always @(state, cur_rd, cur_wr, cur_addr, cur_datain, valid, hit, dirty, c_data_out, tag_out) begin
      Stall = 1'b1;
      CacheHit = 1'b0;
      nxt_state = IDLE;
      Done = 1'b0;
      c_enable = 1'b0;
      c_comp = 1'b0;
      c_write = 1'b0;
      c_validin = 1'b0;
      m_rd = 1'b0;
      m_wr = 1'b0;
      m_addr = {cur_addr[15:3], 3'b000};
      sys_err = 1'b0;

      case(state) 
        IDLE: begin
           Stall = Rd | Wr;
           // use incoming signal in IDLE, Rd, and Wr
         //   nxt_state = Rd ? READ :   
         //               Wr ? WRITE : IDLE;
           c_enable = Rd | Wr;
           c_comp = Rd | Wr;
           c_write = Wr;
           c_datain = DataIn;
           c_tagin = Addr[15:11];
           c_offset = Addr[2:0];
           // hit?
           Done = hit & valid;
           nxt_state =  !(Rd|Wr) ? IDLE : 
                     hit & valid ? IDLE : 
                     !valid ?        L1 : MISS ; // if not valid, don't care about that tag
           CacheHit = hit & valid;
        end

        MISS: begin //get info about the victim cache: comp = 0, write = 0;
           c_enable = 1'b1;
           c_tagin = cur_addr[15:11];
           c_offset = 3'b000;
           //it must be valid to reach this state
           vic_data = c_data_out;
           vic_tag = tag_out;

           nxt_state = dirty & valid ? W2 : L1;
                      
           m_wr = dirty & valid;
           m_data_in =  c_data_out;
           m_addr = {tag_out, cur_addr[10:3], 3'b000}; //1st word
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
           c_enable = 1'b1;
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
           c_enable = 1'b1;
           c_write = 1'b1; //comp =1 ; write =1 access write
           c_tagin = cur_addr[15:11];
           c_offset = 3'b010; 
           c_validin = 1'b1;
           c_datain = m_data_out;
        end
        L_stall: begin
           nxt_state = L_stall2;
           //the 3rd word is ready
           c_enable = 1'b1;
           c_write = 1'b1; //comp =1 ; write =1 access write
           c_tagin = cur_addr[15:11];
           c_offset = 3'b100; 
           c_validin = 1'b1;
           c_datain = m_data_out;
        end
        L_stall2: begin
           nxt_state = LD_DONE;
           
           //the 4th word is ready
           c_enable = 1'b1;
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
           c_enable = cur_rd;
           c_comp = 1'b1;
           c_tagin = cur_addr[15:11];
           c_offset = cur_addr[2:0];
           
           Done = cur_rd;
           Stall = cur_wr;
        end
        W2: begin
           c_enable = 1'b1;
           c_offset = 3'b010;
           m_wr = 1'b1;
           m_data_in = c_data_out;
           m_addr = {vic_tag, cur_addr[10:3], 3'b010}; //2nd word
           nxt_state = W3;
        end
        W3: begin
           c_enable = 1'b1;
           c_offset = 3'b100;
           m_wr = 1'b1;
           m_data_in = c_data_out;
           m_addr = {vic_tag, cur_addr[10:3], 3'b100}; //3rd word
           nxt_state = W4;
        end
        W4: begin
           c_enable = 1'b1;
           c_offset = 3'b110;
           m_wr = 1'b1;
           m_data_in = c_data_out;
           m_addr = {vic_tag, cur_addr[10:3], 3'b110}; //3rd word
           nxt_state = L1;
        end
        W_stall: begin
           //stall state 
           nxt_state = L1;
        end
        WR_DONE: begin //data should be in cache now. simply update it
           c_enable = 1'b1;
           c_comp = 1'b1;
           c_write = 1'b1;
           c_datain = cur_datain;
           c_tagin = cur_addr[15:11];
           c_offset = cur_addr[2:0];
           sys_err = !(hit && valid); //error checking
           nxt_state = IDLE;
           Done = 1'b1;
           Stall = 1'b0;
        end

        default:
           sys_err = 1'b1;
      endcase
      
   end
   assign DataOut = Done? c_data_out : 16'h0000; // may change based on Done Signal
   assign err = c_err | m_err | sys_err;

   
endmodule // mem_system

// DUMMY LINE FOR REV CONTROL :9:
