module cla16 (A,B,Cin,sum,Cout);
    input [15:0] A,B;
    input Cin;
    output [15:0] sum;
    output Cout;

    wire p0, p1,p2,p3,g0,g1,g2,g3;
    wire c1,c2,c3;

    //logic for carreis
    assign c1 = g0 | p0 & Cin;
    assign c2 = g1 | p1 & c1;
    assign c3 = g2 | p2 & c2;
    assign Cout = g3 | p3 & c3; 

    cla4 cla1(.A(A[3:0]),.B(B[3:0]),.Cin(Cin), .Cout(), .sum(sum[3:0]),.pg(p0),.gg(g0));
    cla4 cla2(.A(A[7:4]),.B(B[7:4]),.Cin(c1), .Cout(), .sum(sum[7:4]),.pg(p1),.gg(g1));
    cla4 cla3(.A(A[11:8]),.B(B[11:8]),.Cin(c2), .Cout(), .sum(sum[11:8]),.pg(p2),.gg(g2));
    cla4 cla4(.A(A[15:12]),.B(B[15:12]),.Cin(c3), .Cout(), .sum(sum[15:12]),.pg(p3),.gg(g3));

    
endmodule
