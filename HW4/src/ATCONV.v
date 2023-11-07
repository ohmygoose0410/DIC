`timescale 1ns/10ps
`define LOG_FILE "./log_data.txt"

module  ATCONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);


//=================================================
//            write your design below
//=================================================

localparam BUFFER1 		= 5'd0;
localparam CONV_RELU 	= 5'd1;
localparam BUFFER2		= 5'd2;
localparam MAXPOOLING	= 5'd3;
localparam RESET		= 5'd4;

reg signed [13:0] dataBuf;
reg [2:0] state, nextState;
reg readEn;
reg n_cwr, n_crd, n_csel;
reg finalPixel, n_finalPixel;
reg [11:0] globalPixelPt, n_globalPixelPt;

reg [3:0] dataBufPt;
reg [10:0] PixelPt;
reg [11:0] addrBuf [0:8];
reg [11:0] addrBuf2, n_addrBuf2;

reg [1:0] globalRowLayer;
reg [8:0] globalColLayer;

wire [11:0]	col = globalPixelPt >> 6;
wire [11:0] row = globalPixelPt % 64;
wire [12:0] reluResult = (dataBuf[13] == 1) ? 14'd0 : dataBuf;
wire [12:0] outputBuf = {dataBuf[12:4] + |dataBuf[3:0], 4'd0};

integer i;
//state register
always @(posedge clk or posedge reset) begin
	if(reset) begin
		state 			<= BUFFER1;
		cwr				<= 0;
		crd				<= 0;
		csel			<= 0;
		globalPixelPt 	<= 12'd0;
		addrBuf2		<= 12'd0;
		finalPixel		<= 0;
	end
	else begin
		state 			<= nextState;
		cwr				<= n_cwr;
		crd				<= n_crd;
		csel			<= n_csel;
		globalPixelPt 	<= n_globalPixelPt;
		addrBuf2		<= n_addrBuf2;
		finalPixel		<= n_finalPixel;
	end
end

//next state logic
always @(*) begin
	case(state)
		BUFFER1:begin
			nextState = (dataBufPt < 9) ? BUFFER1 : CONV_RELU;
		end
		CONV_RELU:begin
			if (finalPixel == 1) nextState = CONV_RELU;
			else nextState = (globalPixelPt != 0) ? BUFFER1 : BUFFER2;
		end
		BUFFER2:begin
			nextState = (dataBufPt < 4) ? BUFFER2 : MAXPOOLING;
		end
		MAXPOOLING:begin
			if (finalPixel == 1) nextState = MAXPOOLING;
			else nextState = (PixelPt < 1023) ? BUFFER2 : RESET;
		end
		RESET:begin
			nextState = BUFFER1;
		end
		default:begin
			nextState = BUFFER1;
		end
	endcase
end

always @(*) begin
	n_globalPixelPt = 12'd0;
	n_addrBuf2 = addrBuf2;
	n_finalPixel = finalPixel;
	n_cwr = 0;
	n_crd = 0;
	n_csel = 0;

	case(state)
		BUFFER1:begin
			if (dataBufPt < 9) begin
				n_globalPixelPt = globalPixelPt;
				n_cwr = 0;
				n_crd = 0;
			end
			else begin
				n_globalPixelPt = globalPixelPt + 12'd1;
				n_cwr = 1;
				n_crd = 0;
			end
			n_finalPixel = (globalPixelPt == 4095) ? 1 : 0;
		end
		CONV_RELU:begin
			n_globalPixelPt = globalPixelPt;
			n_cwr = (finalPixel == 1) ? 1 : 0;
			n_crd = (globalPixelPt == 0 && finalPixel == 0) ? 1 : 0;
			n_finalPixel = 0;
		end
		BUFFER2:begin
			if (dataBufPt < 4) begin
				n_globalPixelPt = globalPixelPt;
				n_cwr = 0;
				n_crd = 1;
			end
			else begin
				n_globalPixelPt = (row == 12'd62) ? (globalPixelPt + 12'd66) : (globalPixelPt + 12'd2);
				n_cwr = 1;
				n_crd = 0;
				n_csel = 1;
			end
			n_finalPixel = (PixelPt == 1023) ? 1 : 0;
		end
		MAXPOOLING:begin
			n_globalPixelPt = globalPixelPt;
			n_addrBuf2 = globalPixelPt;
			n_finalPixel = 0;
			n_crd = (PixelPt < 1023 && finalPixel == 0) ? 1 : 0;
			if (finalPixel == 1) begin
				n_cwr = 1;
				n_csel = 1;
			end
			else begin
				n_cwr = 0;
				n_csel = 0;
			end
		end
		RESET:begin
			n_globalPixelPt = 12'd0;
			n_addrBuf2 = 12'd0;
			n_finalPixel = 0;
			n_cwr = 0;
			n_crd = 0;
			n_csel = 0;
		end
	endcase
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		busy 		<= 0;
		dataBuf		<= 0;
		dataBufPt	<= 4'd0;
		PixelPt 	<= 12'd0;
		iaddr 		<= 11'd0;
		readEn		<= 0;
		caddr_wr	<= 12'd0;
		cdata_wr	<= 13'd0;
		caddr_rd	<= 12'd0;
	end
	else begin
		case(state)
			BUFFER1:begin
				case(dataBufPt - 4'd1)
					4'd0: dataBuf <= dataBuf - (idata >> 4);
					4'd1: dataBuf <= dataBuf - (idata >> 3);
					4'd2: dataBuf <= dataBuf - (idata >> 4);
					4'd3: dataBuf <= dataBuf - (idata >> 2);
					4'd4: dataBuf <= dataBuf + idata - 12;	// bias: 12
					4'd5: dataBuf <= dataBuf - (idata >> 2);
					4'd6: dataBuf <= dataBuf - (idata >> 4);
					4'd7: dataBuf <= dataBuf - (idata >> 3);
					4'd8: dataBuf <= dataBuf - (idata >> 4);
					default: dataBuf <= dataBuf;
				endcase
				iaddr <= addrBuf[dataBufPt];

				if(ready) begin
					busy <= 1;
					readEn <= 1;
				end

				if(readEn || ready) begin
					dataBufPt <= (dataBufPt < 9) ? dataBufPt + 1 : 0;
				end
			end
			CONV_RELU:begin
				dataBuf <= 14'd0;
				caddr_wr <= globalPixelPt - 12'd1;
				cdata_wr <= reluResult;
			end
			BUFFER2:begin
				if (dataBufPt != 0)
					dataBuf <= (cdata_rd > dataBuf) ? cdata_rd : dataBuf;
				dataBufPt <= (dataBufPt < 4) ? dataBufPt + 1 : 0;
				case(dataBufPt[1:0])
					0: caddr_rd <= addrBuf2;
					1: caddr_rd <= addrBuf2 + 1;
					2: caddr_rd <= addrBuf2 + 64;
					3: caddr_rd <= addrBuf2 + 65;
				endcase
			end
			MAXPOOLING:begin
				PixelPt <= PixelPt + 1;
				dataBuf <= 0;
				caddr_wr <= PixelPt;
				cdata_wr <= outputBuf;
			end
			RESET:begin
				busy 		<= 0;
				dataBuf		<= 14'd0;
				dataBufPt 	<= 4'd0;
				PixelPt 	<= 12'd0;
				iaddr 		<= 11'd0;
				readEn		<= 0;
			end
			default:begin
				busy 		<= busy;
				dataBuf		<= 14'd0;
				dataBufPt	<= 4'd0;
				PixelPt 	<= 12'd0;
				iaddr 		<= 11'd0;
				readEn		<= readEn;
				caddr_wr	<= 12'd0;
				cdata_wr	<= 13'd0;
				caddr_rd	<= 12'd0;
			end
		endcase
	end
end

always @(*) begin
	// col x 64
	case(col)
		12'd0:	 globalColLayer = 0;
		12'd1: 	 globalColLayer = 64;
		12'd62:  globalColLayer = 64;
		12'd63:  globalColLayer = 0;
		default: globalColLayer = 128;
	endcase

	//  row
	case(row)
		12'd0:	 globalRowLayer = 0;
		12'd1: 	 globalRowLayer = 1;
		12'd62:  globalRowLayer = 1;
		12'd63:  globalRowLayer = 0;
		default: globalRowLayer = 2;
	endcase
end

always @(*) begin
	if(row < 2 && col < 2)
		addrBuf[0] = globalPixelPt - globalColLayer - globalRowLayer;
	else if(col < 2)
		addrBuf[0] = globalPixelPt - globalColLayer - 2;
	else if(row < 2)
		addrBuf[0] = globalPixelPt - 128 - globalRowLayer;
	else
		addrBuf[0] = globalPixelPt - 130;
	
	if(col < 2)
		addrBuf[1] = globalPixelPt - globalColLayer;
	else
		addrBuf[1] = globalPixelPt - 128;
	
	if(row > 61 && col < 2)
		addrBuf[2] = globalPixelPt - globalColLayer + globalRowLayer;
	else if(col < 2)
		addrBuf[2] = globalPixelPt - globalColLayer + 2;
	else if(row > 61)
		addrBuf[2] = globalPixelPt - 128 + globalRowLayer;
	else
		addrBuf[2] = globalPixelPt - 126;
		
	if(row < 2)
		addrBuf[3] = globalPixelPt - globalRowLayer;
	else
		addrBuf[3] = globalPixelPt - 2;

	addrBuf[4] = globalPixelPt;

	if(row > 61)
		addrBuf[5] = globalPixelPt + globalRowLayer;
	else
		addrBuf[5] = globalPixelPt + 2;

	if(row < 2 && col > 61)
		addrBuf[6] = globalPixelPt + globalColLayer - globalRowLayer;
	else if(col > 61)
		addrBuf[6] = globalPixelPt + globalColLayer - 2;
	else if(row < 2)
		addrBuf[6] = globalPixelPt + 128 - globalRowLayer;
	else
		addrBuf[6] = globalPixelPt + 126;

	if(col > 61)
		addrBuf[7] = globalPixelPt + globalColLayer;
	else
		addrBuf[7] = globalPixelPt + 128;

	if(row > 61 && col > 61)
		addrBuf[8] = globalPixelPt + globalColLayer + globalRowLayer;
	else if(col > 61)
		addrBuf[8] = globalPixelPt + globalColLayer + 2;
	else if(row > 61)
		addrBuf[8] = globalPixelPt + 128 + globalRowLayer;
	else
		addrBuf[8] = globalPixelPt + 130;
end

endmodule