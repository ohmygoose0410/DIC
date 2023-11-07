module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;

//state param
localparam DATAIN   = 2'd0;
localparam CALRGB   = 2'd1;
localparam READRGB  = 2'd2;
localparam FINISH   = 2'd3;

//regs
reg [1:0] state, nextState;
reg [1:0] local_cnt;
wire [1:0] local_cnt_minus1 = local_cnt - 1;

reg [13:0] pixelAddr; // Coordinate (row, column) = (pixelAddr[13:7], pixelAddr[6:0])
wire [13:0] startAddr = pixelAddr - 14'd127;
reg [31:0] pixelBuf [0:2];

reg [9:0] result1, result2;

integer i;

//state ctrl
always @(posedge clk or posedge reset) begin
	if(reset)
        state <= DATAIN;
	else
        state <= nextState;
end

//next state logic
always @(*) begin
    case(state)
        DATAIN: begin
            nextState = (pixelAddr == 14'd16383) ? CALRGB : DATAIN;
        end
        CALRGB: begin
            if(pixelAddr == 14'd16253)
                nextState = FINISH;
            else if(local_cnt == 2'd1)
                nextState = READRGB;
            else
                nextState = CALRGB;
        end
        READRGB: begin
            nextState = (local_cnt == 2'd3) ? CALRGB : READRGB;
        end
        FINISH: begin
            nextState = DATAIN;
        end
    endcase
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        pixelAddr <= 0;
        local_cnt <= 0;
        done <= 0;
        wr_r <= 0;
        wr_g <= 0;
        wr_b <= 0;

        for(i=0;i<3;i=i+1)
            pixelBuf[i] <= 32'd0;
    end
    else begin
        case(state)
            DATAIN: begin
                if(in_en) begin
                    pixelAddr <= (pixelAddr == 14'd16383) ? 14'd129 : pixelAddr + 1;
                    case({pixelAddr[7],pixelAddr[0]})
                        2'b01: begin
                            wr_r <= 1;
                            wr_g <= 0;
                            wr_b <= 0;
                            addr_r <= pixelAddr;
                            wdata_r <= data_in;
                        end
                        2'b10: begin
                            wr_r <= 0;
                            wr_g <= 0;
                            wr_b <= 1;
                            addr_b <= pixelAddr;
                            wdata_b <= data_in;
                        end
                        default: begin
                            wr_r <= 0;
                            wr_g <= 1;
                            wr_b <= 0;
                            addr_g <= pixelAddr;
                            wdata_g <= data_in;
                        end
                    endcase
                end

                if(pixelAddr[13:7] < 7'd3 && pixelAddr[6:0] < 7'd4) begin
                    pixelBuf[pixelAddr[13:7]] <= (pixelBuf[pixelAddr[13:7]] << 8) + data_in;
                end
            end
            CALRGB: begin
                local_cnt <= (local_cnt < 2'd1) ? local_cnt + 1 : 0;
                pixelAddr <= pixelAddr + 14'd1;

                pixelBuf[0] <= pixelBuf[0] << 8;
                pixelBuf[1] <= pixelBuf[1] << 8;
                pixelBuf[2] <= pixelBuf[2] << 8;

                case({pixelAddr[7],pixelAddr[0]})
                    2'b00: begin // GREEN_1
                        wr_b <= 1;
                        addr_b <= pixelAddr;
                        wdata_b <= result1;
                        wr_r <= 1;
                        addr_r <= pixelAddr;
                        wdata_r <= result2;
                        wr_g <= 0;
                    end
                    2'b01: begin // RED
                        wr_b <= 1;
                        addr_b <= pixelAddr;
                        wdata_b <= result1;
                        wr_g <= 1;
                        addr_g <= pixelAddr;
                        wdata_g <= result2;
                        wr_r <= 0;
                    end
                    2'b10: begin // BLUE
                        wr_r <= 1;
                        addr_r <= pixelAddr;
                        wdata_r <= result1;
                        wr_g <= 1;
                        addr_g <= pixelAddr;
                        wdata_g <= result2;
                        wr_b <= 0;
                    end
                    2'b11: begin // GREEN_2
                        wr_b <= 1;
                        addr_b <= pixelAddr;
                        wdata_b <= result2;
                        wr_r <= 1;
                        addr_r <= pixelAddr;
                        wdata_r <= result1;
                        wr_g <= 0;
                    end
                endcase
            end
            READRGB: begin
                local_cnt <= local_cnt + 2'd1;
                wr_r <= 0;
                wr_g <= 0;
                wr_b <= 0;

                if(pixelAddr[7] + local_cnt[0] + &pixelAddr[6:0]) begin
                    addr_g <= {startAddr[13:7]+local_cnt,startAddr[6:0]};
                    addr_r <= {startAddr[13:7]+local_cnt,startAddr[6:0]+7'd1};
                end
                else begin
                    addr_b <= {startAddr[13:7]+local_cnt,startAddr[6:0]};
                    addr_g <= {startAddr[13:7]+local_cnt,startAddr[6:0]+7'd1};
                end

                if(local_cnt != 2'd0) begin
                    if(pixelAddr[7] + local_cnt[0] + &pixelAddr[6:0]) pixelBuf[local_cnt_minus1] <= pixelBuf[local_cnt_minus1] + {16'd0,rdata_b,rdata_g};
                    else pixelBuf[local_cnt_minus1] <= pixelBuf[local_cnt_minus1] + {16'd0,rdata_g,rdata_r};
                end
            end
            FINISH: begin
                wr_r <= 0;
                wr_g <= 0;
                wr_b <= 0;
                pixelAddr <= 0;
                local_cnt <= 0;
                done <= 0;
                for(i=0;i<3;i=i+1)
                    pixelBuf[i] <= 32'd0;

                done <= 1;
            end
        endcase
    end
end

always @(*) begin
    case(^{pixelAddr[7],pixelAddr[0]})
        0: begin
            result1 = (pixelBuf[0][23:16] + pixelBuf[2][23:16]) >> 1;
            result2 = (pixelBuf[1][31:24] + pixelBuf[1][15:8]) >> 1;
        end
        1: begin
            result1 = ((pixelBuf[0][31:24] + pixelBuf[0][15:8]) + (pixelBuf[2][31:24] + pixelBuf[2][15:8])) >> 2;
            result2 = ((pixelBuf[0][23:16] + pixelBuf[2][23:16]) + (pixelBuf[1][31:24] + pixelBuf[1][15:8])) >> 2;
        end
    endcase
end

endmodule