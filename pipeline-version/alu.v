module alu (A, B, Cin, Op, invA, invB, clearB, sign, Out, Ofl, Z);
   
        input [15:0] A;
        input [15:0] B;
        input Cin;
        input [2:0] Op;
        input invA;
        input invB;
        input sign;
        input clearB;
        output [15:0] Out;
        output Ofl;
        output Z;

        wire [15:0] _A, _B;
        wire [15:0] shift_out, add_out, or_out, xor_out, and_out;
        wire Cout;
        wire o_flag, o_pos, o_neg;

        assign o_pos = add_out[15] & !(_A[15] | _B[15]);
        assign o_neg = add_out[15] ^ (_A[15] & _B[15]);
        assign o_flag = (_A[15] & _B[15]) ? o_neg : o_pos;

        assign _A = invA ?   ~A : A;
        assign _B = clearB ? 15'h0000 : 
                    invB ?   ~B : B;

        shifter s(.In(_A), .Cnt(_B[3:0]), .Op(Op[1:0]), .Out(shift_out)); 
        cla16 add(.A(_A), .B(_B), .Cin(Cin), .sum(add_out), .Cout(Cout));
        assign or_out = _A | _B; // IS of SLBI
        assign xor_out = _A ^ _B;
        assign and_out = _A & _B;

        //modification made to adapt project: op[2]. if op[2] == 1 shift;
        assign Out = !Op[2] ? Op[1:0] == 2'b00 ? add_out :
                             Op[1:0] == 2'b01 ? or_out :
                             Op[1:0] == 2'b10 ? xor_out :
                                                and_out : shift_out;
        assign Ofl = Op == 3'b000 ? sign ? o_flag : Cout : 1'b0;
        assign Z = !(|Out); //high when out == 0
    
endmodule
