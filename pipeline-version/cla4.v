module cla4 (A,B,Cin,Cout, sum, pg,gg);
    input [3:0] A, B;
    input Cin;
    output [3:0] sum;
    output Cout,pg,gg;

    wire p0, p1,p2,p3,g0,g1,g2,g3;
    wire c1,c2,c3;

    //instantiate the intermeddiate vals for cla
    assign p0 = A[0] ^ B[0];
    assign p1 = A[1] ^ B[1];
    assign p2 = A[2] ^ B[2];
    assign p3 = A[3] ^ B[3];
    assign g0 = A[0] & B[0];
    assign g1 = A[1] & B[1];
    assign g2 = A[2] & B[2];
    assign g3 = A[3] & B[3];

    //logic for sum
    assign sum[0] = p0 ^ Cin;
    assign sum[1] = p1 ^ c1;
    assign sum[2] = p2 ^ c2;
    assign sum[3] = p3 ^ c3;

    //logic for carreis
    assign c1 = g0 | p0 & Cin;
    assign c2 = g1 | p1 & c1;
    assign c3 = g2 | p2 & c2;
    assign Cout = g3 | p3 & c3;

    //logic for pg gg
    assign pg = p0 & p1 & p2 & p3;
    assign gg = g3 | p3 & g2 | p3 & p2 & g1 | p3 & p2 & p1 & g0;

endmodule