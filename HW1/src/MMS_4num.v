module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result; 

wire [7:0] mux0_out, mux1_out;

MUX2to1 mux0(number0, number1, select ? (number1<number0) : (number1>number0), mux0_out);
MUX2to1 mux1(number2, number3, select ? (number3<number2) : (number3>number2), mux1_out);
MUX2to1 mux2(mux0_out, mux1_out, select ? (mux1_out<mux0_out) : (mux1_out>mux0_out), result);

endmodule

module MUX2to1 (input [7:0] a, 
		input [7:0] b,
		input sel,
		output [7:0] c);

assign c = sel ? b : a;
	
endmodule