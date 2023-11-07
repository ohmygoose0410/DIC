module BITONIC_S3(  number_in1, number_in2, number_in3, number_in4,
                    number_in5, number_in6, number_in7, number_in8,
                    number_out1, number_out2, number_out3, number_out4,
                    number_out5, number_out6, number_out7, number_out8);

input  [7:0] number_in1;
input  [7:0] number_in2;
input  [7:0] number_in3;
input  [7:0] number_in4;
input  [7:0] number_in5;
input  [7:0] number_in6;
input  [7:0] number_in7;
input  [7:0] number_in8;

output  [7:0] number_out1;
output  [7:0] number_out2;
output  [7:0] number_out3;
output  [7:0] number_out4;
output  [7:0] number_out5;
output  [7:0] number_out6;
output  [7:0] number_out7;
output  [7:0] number_out8;

wire [7:0] temp1_1,temp1_2,temp1_3,temp1_4,temp1_5,temp1_6,temp1_7,temp1_8;
wire [7:0] temp2_1,temp2_2,temp2_3,temp2_4,temp2_5,temp2_6,temp2_7,temp2_8;
wire [7:0] temp3_1,temp3_2,temp3_3,temp3_4,temp3_5,temp3_6,temp3_7,temp3_8;

BITONIC_S2 BITONIC_S2_m(number_in1, number_in2, number_in3, number_in4,
								number_in5, number_in6, number_in7, number_in8,
								temp1_1, temp1_2, temp1_3, temp1_4,
								temp1_5, temp1_6, temp1_7, temp1_8);

BITONIC_AS BITONIC_AS0(temp1_1, temp1_5, temp2_1, temp2_5);
BITONIC_AS BITONIC_AS1(temp1_2, temp1_6, temp2_2, temp2_6);
BITONIC_AS BITONIC_AS2(temp1_3, temp1_7, temp2_3, temp2_7);
BITONIC_AS BITONIC_AS3(temp1_4, temp1_8, temp2_4, temp2_8);

BITONIC_AS BITONIC_AS4(temp2_1, temp2_3, temp3_1, temp3_3);
BITONIC_AS BITONIC_AS5(temp2_2, temp2_4, temp3_2, temp3_4);
BITONIC_AS BITONIC_AS6(temp2_5, temp2_7, temp3_5, temp3_7);
BITONIC_AS BITONIC_AS7(temp2_6, temp2_8, temp3_6, temp3_8);

BITONIC_AS BITONIC_AS8(temp3_1, temp3_2, number_out1, number_out2);
BITONIC_AS BITONIC_AS9(temp3_3, temp3_4, number_out3, number_out4);
BITONIC_AS BITONIC_AS10(temp3_5, temp3_6, number_out5, number_out6);
BITONIC_AS BITONIC_AS11(temp3_7, temp3_8, number_out7, number_out8);

endmodule
