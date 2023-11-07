module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output valid;
output [6:0] result;

localparam DATA_IN 			= 4'd0;
localparam TOKEN_IN 			= 4'd1;
localparam OP_EQUAL			= 4'd2;
localparam OP_GENERAL		= 4'd3;
localparam OP_RIGHT_BRACK	= 4'd4;
localparam CALCULATION		= 4'd5;
localparam OUT 				= 4'd6;
localparam WAIT 				= 4'd7;
localparam OP_MULTIPLY		= 4'd8;
localparam OP_ADD_SUB		= 4'd9;
localparam OP_LEFT_BRACK	= 4'd10;
localparam CAL_MULTIPLY		= 4'd11;
localparam CAL_ADDITION		= 4'd12;
localparam CAL_SUBTRACTION = 4'd13;
localparam TEMP				= 4'd14;

localparam LEFT_BRACK	= 8'd40;
localparam RIGHT_BRACK	= 8'd41;
localparam MULTIPLY		= 8'd42;
localparam ADDITION		= 8'd43;
localparam SUBTRACTION	= 8'd45;
localparam EQUAL			= 8'd61;

reg valid;
reg [6:0] result;
reg [3:0] next_state, state;
reg [1:0] substate;
reg [3:0] index;
reg [7:0] token [0:15];
reg [3:0] postfix_index;
reg [7:0] postfix [0:15];
reg [2:0] stack_index;
reg [7:0] stack [0:7];

wire [2:0] stack_index_minus_one = stack_index - 1;
wire [2:0] stack_index_minus_two = stack_index - 2;
wire check_stack_index = stack_index > 8'd0;
wire [7:0] ascii2value = (token[index] < 8'd58) ? token[index] - 8'd48 : token[index] - 8'd87;

integer i;

always@(posedge clk or posedge rst) begin
	if(rst) state <= DATA_IN;
	else state <= next_state;
end

always@(*) begin
	case(state)
		DATA_IN: begin
			if(ascii_in == EQUAL) next_state = TOKEN_IN;
			else next_state = DATA_IN;
		end
		TOKEN_IN: begin
			if(token[index] > 8'd47 && token[index] != EQUAL) next_state = TOKEN_IN;
			else begin
				case(token[index])
					EQUAL: next_state = OP_EQUAL;
					LEFT_BRACK: next_state = OP_LEFT_BRACK;
					RIGHT_BRACK: next_state = OP_RIGHT_BRACK;
					MULTIPLY: next_state = OP_MULTIPLY;
					default: next_state = OP_ADD_SUB;
				endcase
			end
		end
		OP_EQUAL: begin
			if(stack_index == 8'd0) next_state = CALCULATION;
			else next_state = OP_EQUAL;
		end
		OP_RIGHT_BRACK: begin
			if(stack[stack_index_minus_one] != LEFT_BRACK && check_stack_index) next_state = OP_RIGHT_BRACK;
			else next_state = TOKEN_IN;
		end
		OP_MULTIPLY: next_state = TOKEN_IN;
		OP_ADD_SUB: begin
			if(stack[stack_index_minus_one] != LEFT_BRACK && check_stack_index) next_state = OP_ADD_SUB;
			else next_state = TOKEN_IN;
		end
		OP_LEFT_BRACK: next_state = TOKEN_IN;
		CALCULATION: begin
			case(postfix[postfix_index])
				EQUAL: next_state = OUT;
				MULTIPLY: next_state = CAL_MULTIPLY;
				ADDITION: next_state = CAL_ADDITION;
				SUBTRACTION: next_state = CAL_SUBTRACTION;
				default: next_state = CALCULATION;
			endcase
		end
		CAL_MULTIPLY: next_state = CALCULATION;
		CAL_ADDITION: next_state = CALCULATION;
		CAL_SUBTRACTION: next_state = CALCULATION;
		OUT: next_state = WAIT;
		WAIT: next_state = DATA_IN;
		TEMP: next_state = TOKEN_IN;
		default: next_state = OUT;
	endcase
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		for(i = 0; i < 16; i = i + 1) postfix[i] <= 8'hFF;
		index <= 4'd0;
		postfix_index <= 4'd0;
		stack_index <= 4'd0;
		valid <= 1'b0;
		result <= 6'd0;
	end
	else begin
		case(state)
			DATA_IN: begin
				token[index] <= ascii_in;
				if(ascii_in == 8'd61) index <= 0;
				else index <= index + 1;
			end
			TOKEN_IN: begin
				if(token[index] > 8'd47 && token[index] != EQUAL) begin
					postfix[postfix_index] <= ascii2value;
					postfix_index <= postfix_index + 1;
					index <= index + 1;
				end
			end
			OP_EQUAL: begin
				if(check_stack_index) begin
					postfix[postfix_index] <= stack[stack_index_minus_one];
					postfix_index <= postfix_index + 1;
					stack_index <= stack_index - 1;
				end
				else begin
					postfix[postfix_index] <= 8'd61;
					postfix_index <= 0;
				end
			end
			OP_RIGHT_BRACK: begin
				if(stack[stack_index_minus_one] != LEFT_BRACK && check_stack_index) begin
					postfix[postfix_index] <= stack[stack_index_minus_one];
					postfix_index <= postfix_index + 1;
					stack_index <= stack_index - 1;
				end
				else begin
					stack_index <= stack_index - 1;
					index <= index + 1;
				end
			end
			OP_MULTIPLY: begin
				if(stack[stack_index_minus_one] == MULTIPLY && check_stack_index) begin
					postfix[postfix_index] <= token[index];
					postfix_index <= postfix_index + 1;
					index <= index + 1;
				end
				else begin
					stack[stack_index] <= token[index];
					stack_index <= stack_index + 1;
					index <= index + 1;
				end
			end
			OP_ADD_SUB: begin
				if(stack[stack_index_minus_one] != LEFT_BRACK && check_stack_index)	begin
					postfix[postfix_index] <= stack[stack_index_minus_one];
					postfix_index <= postfix_index + 1;
					stack_index <= stack_index - 1;
				end
				else begin
					stack[stack_index] <= token[index];
					stack_index <= stack_index + 1;
					index <= index + 1;
				end
			end
			OP_LEFT_BRACK: begin
				stack[stack_index] <= token[index];
				stack_index <= stack_index + 1;
				index <= index + 1;
			end
			CALCULATION: begin
				if(postfix[postfix_index] < 8'd16) begin
					stack[stack_index] <= postfix[postfix_index];
					stack_index <= stack_index + 1;
					postfix_index <= postfix_index + 1;
				end
				else postfix_index <= postfix_index + 1;
			end
			CAL_MULTIPLY: begin
				stack[stack_index_minus_two] <= stack[stack_index_minus_one] * stack[stack_index_minus_two];
				stack_index <= stack_index - 1;
			end
			CAL_ADDITION: begin
				stack[stack_index_minus_two] <= stack[stack_index_minus_one] + stack[stack_index_minus_two];
				stack_index <= stack_index - 1;
			end
			CAL_SUBTRACTION: begin
				stack[stack_index_minus_two] <= stack[stack_index_minus_two] - stack[stack_index_minus_one];
				stack_index <= stack_index - 1;
			end
			OUT: begin
				valid <= 1'b1;
				result <= stack[0][6:0];
			end
			WAIT: begin
				for(i = 0; i < 16; i = i + 1) postfix[i] <= 8'hFF;
				index <= 4'd0;
				postfix_index <= 4'd0;
				stack_index <= 4'd0;
				valid <= 1'b0;
				result <= 6'd0;
			end
		endcase
	end
end

endmodule