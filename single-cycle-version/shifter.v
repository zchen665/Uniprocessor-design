//barrel shfiter for alu in demo1;
//small modification has been made 
//on op == 2'b10
module shifter (In, Cnt, Op, Out);
   
   input [15:0] In;
   input [3:0]  Cnt;
   input [1:0]  Op; // 00 rotate left, 01 shift left;
   // 10 rotate right, 11 shift right
   output [15:0] Out;

   wire [15:0] s1,s2,s4, s1_tmp, s2_tmp, s4_tmp, out_tmp;

   assign s1 =  Cnt[0] ? s1_tmp : In;
   assign s1_tmp =      Op == 2'b00 ? {In[14:0],In[15]} :
                        Op == 2'b01 ? {In[14:0],1'b0} :
                        Op == 2'b10 ? {In[0], In[15:1]} :
                                 {1'b0, In[15:1]};
   assign s2 = Cnt[1] ? s2_tmp : s1;
   assign s2_tmp =      Op == 2'b00 ? {s1[13:0],s1[15:14]} :
                        Op == 2'b01 ? {s1[13:0],2'b00} :
                        Op == 2'b10 ? {s1[1:0], s1[15:2]} :
                                 {2'b00,s1[15:2]};

   assign s4 = Cnt[2] ? s4_tmp : s2;
   assign s4_tmp =      Op == 2'b00 ? {s2[11:0], s2[15:12]} :
                        Op == 2'b01 ? {s2[11:0], 4'h0} :
                        Op == 2'b10 ? {s2[3:0],s2[15:4]} :
                                 {4'h0,s2[15:4]};
   assign Out = Cnt[3] ? out_tmp : s4;
   assign out_tmp =     Op == 2'b00 ? {s4[7:0], s4[15:8]} :
                        Op == 2'b01 ? {s4[7:0], 8'h00} :
                        Op == 2'b10 ? {s4[7:0], s4[15:8]} :
                                 {8'h00, s4[15:8]};

   
endmodule

