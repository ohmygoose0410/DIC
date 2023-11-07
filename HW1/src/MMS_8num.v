
module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output [7:0] result; 

wire [7:0] mux0_out, mux1_out;

MMS_4num mux0(  .result(mux0_out),
                .select(select),
                .number0(number0),
                .number1(number1),
                .number2(number2),
                .number3(number3));
MMS_4num mux1(  .result(mux1_out),
                .select(select),
                .number0(number4),
                .number1(number5),
                .number2(number6),
                .number3(number7));
MUX2to1 mux2(   .a(mux0_out),
                .b(mux1_out),
                .sel(select ? (mux1_out<mux0_out) : (mux1_out>mux0_out)),
                .c(result));

endmodule