/* $Author: karu $ */
/* $LastChangedDate: 2009-03-04 23:09:45 -0600 (Wed, 04 Mar 2009) $ */
/* $Rev: 45 $ */
module rf (
           // Outputs
           read1data, read2data, err,
           // Inputs
           clk, rst, read1regsel, read2regsel, writeregsel, writedata, write
           );
   input clk, rst;
   input [2:0] read1regsel;
   input [2:0] read2regsel;
   input [2:0] writeregsel;
   input [15:0] writedata;
   input        write;

   output [15:0] read1data;
   output [15:0] read2data;
   output        err; // high if high impedance

   parameter BIT_WIDTH = 16;

   wire [BIT_WIDTH - 1:0] regs[7:0];

   register r0(.writedata(writedata),.readdata(regs[0]),
   .write(write ? writeregsel == 0 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
  
   register r1(.writedata(writedata),.readdata(regs[1]),
   .write(write ? writeregsel == 1 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
   
   register r2(.writedata(writedata),.readdata(regs[2]),
   .write(write ? writeregsel == 2 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
   
   register r3(.writedata(writedata),.readdata(regs[3]),
   .write(write ? writeregsel == 3 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
   
   register r4(.writedata(writedata),.readdata(regs[4]),
   .write(write ? writeregsel == 4 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
   
   register r5(.writedata(writedata),.readdata(regs[5]),
   .write(write ? writeregsel == 5 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
   
   register r6(.writedata(writedata),.readdata(regs[6]),
   .write(write ? writeregsel == 6 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));
   
   register r7(.writedata(writedata),.readdata(regs[7]),
   .write(write ? writeregsel == 7 ? 1'b1 : 1'b0 : 1'b0),.clk(clk),.rst(rst));

   assign read1data = regs[read1regsel];
   assign read2data = regs[read2regsel];
   //assign err = (^read1data === 1'bx | ^read2data === 1'bx) ? 1'b1 : 1'b0;

endmodule
// DUMMY LINE FOR REV CONTROL :1:
