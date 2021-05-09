module register(writedata,readdata,clk,rst,write);
parameter width = 16;
input clk,rst,write;
input [width-1:0] writedata;
output [width-1:0] readdata;

dff d[width-1:0] (.q(readdata),.d(write ? writedata :readdata),.clk(clk),.rst(rst));

endmodule
    