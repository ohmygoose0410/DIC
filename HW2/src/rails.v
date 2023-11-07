module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result; 

localparam IDLE  	= 3'b000;
localparam CHECK	= 3'b001;
localparam STORE	= 3'b010;
localparam MOVE	 	= 3'b011;
localparam EQUAL	= 3'b100;
localparam INVALID	= 3'b101;
localparam RESET	= 3'b110;
localparam VALID	= 3'b111;

reg [2:0] 	curr_state;
reg [2:0] 	next_state;

reg 		valid, result;
reg [3:0] 	counter;
reg [3:0] 	order_cnt;
reg [3:0] 	number_of_train;

reg 		lifo_stack_rst_n;
reg			lifo_stack_en_i;
reg			lifo_stack_w_r_i;
reg  [3:0] 	lifo_stack_data_i;
wire		lifo_stack_full_o;
wire 		lifo_stack_empty_o;
wire [3:0] 	lifo_stack_data_o;

LIFO_STACK lifo_stack(	
		.clk(clk),
		.rst_n(~reset & lifo_stack_rst_n),
		.en_i(lifo_stack_en_i),
		.w_r_i(lifo_stack_w_r_i),
		.data_i(lifo_stack_data_i),
		.full_o(lifo_stack_full_o),
		.empty_o(lifo_stack_empty_o),
		.data_o(lifo_stack_data_o)
);

reg	 		rsg_arr_rst_n;
reg	 [3:0] 	rsg_arr_addr;
reg  		rsg_arr_w_r;
reg			rsg_arr_en;
reg  [3:0] 	rsg_arr_data_i;
wire [3:0] 	rsg_arr_data_o;

RSG_ARR rsg_arr(
		.clk(clk),
		.rst_n(~reset & rsg_arr_rst_n),
		.addr(rsg_arr_addr),
		.w_r(rsg_arr_w_r),
		.en(rsg_arr_en),
		.data_i(rsg_arr_data_i),
		.data_o(rsg_arr_data_o)
);
					
always @(posedge clk or posedge reset) begin
	if (reset) 	curr_state <= IDLE;
	else curr_state <= next_state;
end

always @(*)
	case (curr_state)
		IDLE	:	next_state = STORE;
		STORE	:	begin
					if (counter > 4'd1) 	next_state = STORE;
					else					next_state = MOVE;
					end
		MOVE	: 	begin
					if ((number_of_train + 4'd1) > counter) next_state = CHECK;
					else next_state = INVALID;
					end
		CHECK	:	if(order_cnt == 4'd0 & lifo_stack_empty_o == 1'b1) next_state = VALID;
					else next_state = EQUAL;
		EQUAL	:	if (rsg_arr_data_o == lifo_stack_data_o)
						next_state = CHECK;
					else if (result == 1'b1)
						next_state = RESET;
					else
						next_state = MOVE;
		INVALID	:	next_state = RESET;
		VALID	: 	next_state = RESET;
		RESET	:	next_state = IDLE;
		default : 	next_state = IDLE;
	endcase
		
always @(posedge clk or posedge reset)
	if (reset) ;
	else 
		case (curr_state)
			IDLE	: 	begin					
							result	<= 1'b0;
							valid 	<= 1'b0;
							
							lifo_stack_w_r_i	<= 1'b0;
							lifo_stack_en_i		<= 1'b0;
							lifo_stack_rst_n	<= 1'b1;

							rsg_arr_en			<= 1'b1;
							rsg_arr_w_r			<= 1'b1;
							rsg_arr_rst_n		<= 1'b1;

							counter 			<= data;
							number_of_train		<= data;
							order_cnt			<= data - 4'd1;
						end
			STORE	:	begin
							rsg_arr_addr 		<= counter - 4'd1;
							rsg_arr_data_i		<= data;
							counter 			<= counter - 4'd1;
						end
			MOVE	:	begin
							lifo_stack_w_r_i	<= 1'b1;
							lifo_stack_en_i		<= 1'b1;
							lifo_stack_data_i	<= counter + 4'd1;

							rsg_arr_w_r			<= 1'b0;
							rsg_arr_addr		<= order_cnt;

							counter	<= counter + 4'd1;
						end
			CHECK	:	begin
							lifo_stack_en_i	<= 1'b0;
						end
			EQUAL	:	begin
							if (lifo_stack_data_o == rsg_arr_data_o) begin
								order_cnt			<= (order_cnt == 4'd0)? order_cnt : order_cnt - 4'd1;
								rsg_arr_addr		<= order_cnt - 4'd1;
								lifo_stack_w_r_i	<= 1'b0;
								lifo_stack_en_i		<= 1'b1;
							end 
						end
			INVALID	:	begin
							result	<= 1'b0;
							valid 	<= 1'b1;
						end
			VALID	: 	begin
							result 	<= 1'b1;
							valid	<= 1'b1;
						end
			RESET	:	begin
							lifo_stack_rst_n 	<= 1'b0;
							rsg_arr_rst_n		<= 1'b0;

							result	<= 1'b0;
							valid 	<= 1'b0;
						end
			default: 	begin
							result 	<= 1'b0;
							valid	<= 1'b0;

							counter	<= 4'd0;
							number_of_train		<= 4'd0;
							order_cnt			<= 4'd0;
						end
		endcase

endmodule

module RSG_ARR(clk, rst_n, addr, w_r, en, data_i, data_o);

input 			clk, rst_n, w_r, en;
input  [3:0] 	addr;
input  [3:0]	data_i;
output [3:0]	data_o;

reg [3:0] register [0:9];
integer i;

assign data_o = (en & ~w_r)? register[addr] : 4'h0;
	
always @(posedge clk) begin
	if (!rst_n) begin
		for (i = 0; i < 10; i = i + 1) register[i] <= 4'h0;
	end else begin
		if (en & w_r)
			register[addr] <= data_i;
		else
			register[addr] <= register[addr];
	end
end
	
endmodule

module LIFO_STACK(clk, rst_n, en_i, w_r_i, data_i, data_o, full_o, empty_o);

input 				w_r_i, clk, rst_n, en_i;
input  		[3:0] 	data_i;
output reg			full_o,empty_o;
output 		[3:0]	data_o;

reg [3:0] stack_mem [0:9];
reg [3:0] sp;

assign data_o = stack_mem[sp-4'd1];

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sp 		<= 4'd0;
		empty_o <= 1'b1;
		full_o	<= 1'b0;
	end else begin
		if (en_i) begin
			if (w_r_i == 1 & full_o == 0) begin
				empty_o <= 0;
				sp <= sp + 4'd1;
				stack_mem[sp] <= data_i;
				full_o <= (sp == 4'd9)? 1'b1 : full_o;
			end else if (w_r_i == 0 & empty_o == 0) begin
				full_o <= 1'b0;
				sp <= sp - 4'd1;
				empty_o <= ((sp-4'd1) == 4'd0)? 1'b1 : empty_o;
			end else begin
				stack_mem[sp] <= stack_mem[sp];
				sp <= sp;
				empty_o <= empty_o;
				full_o <= full_o;
			end
		end else begin
			stack_mem[sp] <= stack_mem[sp];
			sp <= sp;
			empty_o <= empty_o;
			full_o <= full_o;
		end
	end
end

endmodule