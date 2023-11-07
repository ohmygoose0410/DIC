module rails(clk, reset, number, data1, data2, valid, result1, result2);

input        clk;
input        reset;
input  [3:0] number;
input  [3:0] data1;
input  [3:0] data2;
output  reg     valid;
output  reg     result1; 
output  reg     result2;

localparam NUMBER_IN 		= 4'd0;
localparam DATA_IN 			= 4'd1;
localparam STATION1_POP 	= 4'd2;
localparam STATION1_PUSH 	= 4'd3;
localparam STATION2_POP 	= 4'd4;
localparam STATION2_PUSH 	= 4'd5;
localparam OUT 				= 4'd6;
localparam WAIT 			= 4'd7;

reg [2:0] state, nextState;
reg [3:0] num;
reg [3:0] index, index2, sequence_index;
reg [2:0] station_index;
reg [3:0] station [0:9];//station stack
reg [3:0] order1 [0:9];//input order
reg [3:0] order2 [0:9];//input order

wire [3:0] station_index_minus_one = station_index - 4'd1;

integer i;

always @(*) begin
    case(state)
        NUMBER_IN:begin
            nextState = DATA_IN;
        end
        DATA_IN:begin
            if(index == num - 1) nextState = STATION1_POP;
            else nextState = DATA_IN;
        end
        STATION1_POP:begin
            if((station_index > 4'd0) && (station[station_index_minus_one] == order1[index])) nextState = STATION1_POP;
            else nextState = STATION1_PUSH;
        end
        STATION1_PUSH:begin
				if(index == num) nextState = STATION2_POP;
            else if((sequence_index == num + 1) || (station_index > 3'd5)) nextState = OUT;
            else nextState = STATION1_POP;
        end
		  STATION2_POP:begin
            if((station_index > 4'd0) && (station[station_index_minus_one] == order2[index2])) nextState = STATION2_POP;
            else nextState = STATION2_PUSH;
        end
        STATION2_PUSH:begin
            if((index == num) || (station_index > 3'd2)) nextState = OUT;
            else nextState = STATION2_POP;
        end
        OUT:begin
            nextState = WAIT;
        end
        default:begin
            nextState = NUMBER_IN;
        end
    endcase
end

always @(posedge clk) begin
    if(reset) state <= NUMBER_IN;
    else state <= nextState;
end

always @(posedge clk or posedge reset) begin
    if(reset)begin
        for(i = 0; i < 10; i = i + 1) station[i] <= 4'b1111;
        valid <= 1'b0;
        result1 <= 1'b0;
		  result2 <= 1'b0;
        num <= 4'd0;
        index <= 4'd0;
		  index2 <= 4'd0;
        station_index <= 4'd0;
        sequence_index <= 4'd1;
    end
    else begin
        case(state)
            NUMBER_IN:begin//read number
                num <= number;
            end
            DATA_IN:begin//read data
                order1[index] <= data1;
					 order2[index] <= data2;
                if(index == num - 1) index <= 4'd0;
                else index <= index + 1;
            end
            STATION1_POP:begin//compare top with order
                if((station_index > 4'd0) && (station[station_index_minus_one] == order1[index]))begin
                    index <= index + 1;
                    station_index <= station_index - 1;
                end
            end
            STATION1_PUSH:begin//push data into stack
                station[station_index] <= sequence_index;
                station_index <= station_index + 1;
                sequence_index <= sequence_index + 1;
					 if(index == num) begin
						result1 <= 1'b1;
						station_index <= 4'b0;
						index <= 4'b0;
					 end
            end
				STATION2_POP:begin//compare top with order
                if((station_index > 4'd0) && (station[station_index_minus_one] == order2[index2]))begin
                    index2 <= index2 + 1;
                    station_index <= station_index - 1;
                end
            end
            STATION2_PUSH:begin//push data into stack
                station[station_index] <= order1[index];
                station_index <= station_index + 1;
                index <= index + 1;
            end
            OUT:begin//output result
                valid <= 1;
                if((index2 == num) && (result1 == 1'b1)) result2 <= 1'b1;
            end
            WAIT:begin//reset register
                for(i = 0; i < 10; i = i + 1) station[i] <= 4'b1111;
                valid <= 0;
                result1 <= 0;
					 result2 <= 0;
                index <= 0;
					 index2 <= 0;
                station_index <= 4'd0;
                sequence_index <= 4'd1;
            end
        endcase
    end
end
endmodule