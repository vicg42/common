//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 22.07.2016 18:41:16
// Module Name : spi_slave
//
// Description :
// Request write to user register:
// SPI_MOSI bit:  |31.....24|23..16|15..8|7...0|
//                |msb   lsb|msb            lsb|
//                ------------------------------
//                |  RegAdr |   RegData        |
//                ------------------------------
// SPI_MISO bit:  |          don`t care        |
//                ------------------------------
//
// Request read from user register:
// SPI_MOSI bit:  |31.........24|23..........16|15...8|7...0|
//                |msb       lsb|msb        lsb|msb      lsb|
//                -------------------------------------------
//                |  RegAdr     |  adr_rdata   | don`t care |
//                | (Responder) |   (MUX)      |            |
//                -------------------------------------------
// SPI_MISO bit:  |          don`t care        | ReadData   |
//                -------------------------------------------
//
// SPI MODE = 3 (CPOL = 1, CPHA = 1)
// CPOL=1 - the base value of the clock is one (inversion of CPOL=0), i.e.
//          the active state is 0 and idle state is 1.
// CPHA=1 - data are captured on clock's rising edge and data is output on a falling edge.
//-----------------------------------------------------------------------
module spi_slave #(
parameter G_ADR_BASE = 8'h00,
parameter G_ADR_SPACE_SIZE = 8'hFF,
parameter G_ADR_RESPONDER = 8'hFE,
parameter G_RD_WIDTH = (8 * 8) //8 registers pre 8bit
)(
//SPI port
input  p_in_spi_cs   ,
input  p_in_spi_ck   ,
input  p_in_spi_mosi ,
output p_out_spi_miso,

//User IF
input [(G_RD_WIDTH - 1):0] reg_rd_data,
output reg [7:0]  reg_wr_addr = 0,
output reg [23:0] reg_wr_data = 0,
output reg        reg_wr_en = 0,
input             reg_clk
);

// -------------------------------------------------------------------------
localparam CI_SPI_WIDTH = 32;

localparam S_IDLE     = 0;
localparam S_RCV_ADR  = 1;
localparam S_M2S      = 2;
localparam S_M2S_END  = 3;
localparam S_S2M_MUX  = 4;
localparam S_S2M      = 5;
localparam S_WAIT_END = 6;

reg [2:0] i_fsm_cs = S_IDLE;//current state

reg [2:0] sr_spi_cs = 0;
reg [1:0] sr_spi_mosi = 0;
reg [2:0] sr_spi_ck = 0;

//oversample
always @ (posedge reg_clk) begin
  sr_spi_cs <= {sr_spi_cs[1:0], p_in_spi_cs};
  sr_spi_ck <= {sr_spi_ck[1:0], p_in_spi_ck};
  sr_spi_mosi <= {sr_spi_mosi[0], p_in_spi_mosi};
end

wire i_spi_cs, i_spi_mosi, i_spi_rst;
assign i_spi_cs = sr_spi_cs[1];
assign i_spi_mosi = sr_spi_mosi[1];
assign i_spi_rst = sr_spi_cs[2] & (~sr_spi_cs[1]);

//edge detector
wire [1:0] i_spi_ck_edge;
assign i_spi_ck_edge[0] = (~sr_spi_ck[2]) &   sr_spi_ck[1]; //rising_edge
assign i_spi_ck_edge[1] =   sr_spi_ck[2]  & (~sr_spi_ck[1]);//faling_edge


//FSM
reg [(CI_SPI_WIDTH - 1):0] sr_mosi = 0;
reg [15:0] sr_miso = 0;
reg [7:0] i_adr_rdata = 0;
reg [5:0] i_cntb = 0; //bit cnt
always @(posedge reg_clk) begin
    if (i_spi_rst) begin
        i_cntb <= 0;
        i_adr_rdata <= 0;
        sr_mosi <= 0;
        sr_miso <= 0;
        i_fsm_cs <= S_IDLE;
    end
    else begin
        reg_wr_en <= 1'b0;

        case (i_fsm_cs)
            S_IDLE : begin
                if (!i_spi_cs) begin
                    i_cntb <= 0;
                    i_adr_rdata <= 0;
                    i_fsm_cs <= S_RCV_ADR;
                end
            end

            S_RCV_ADR : begin
                if (!i_spi_cs) begin
                    if (i_spi_ck_edge[0]) begin
                        if (i_cntb == (8 - 1)) begin
                            //check adress space
                            if ( ({sr_mosi[6:0], i_spi_mosi} >= G_ADR_BASE) &&
                                 ({sr_mosi[6:0], i_spi_mosi} <= (G_ADR_BASE + G_ADR_SPACE_SIZE)) ) begin

                                 if ({sr_mosi[6:0], i_spi_mosi} == G_ADR_RESPONDER) begin
                                    i_fsm_cs <= S_S2M_MUX;
                                 end
                                 else begin //master -> slave
                                    i_fsm_cs <= S_M2S;
                                 end
                            end
                            else begin
                                i_fsm_cs <= S_WAIT_END;//Not my adress space
                            end
                        end

                        i_cntb <= i_cntb + 1'b1;
                        sr_mosi <= {sr_mosi[(CI_SPI_WIDTH - 2):0], i_spi_mosi}; //recieve MSB first
                    end
                end
            end

            S_M2S : begin //master 2 slave
                if (!i_spi_cs) begin
                    if (i_spi_ck_edge[0]) begin
                        if (i_cntb == (CI_SPI_WIDTH - 1)) begin
                          i_fsm_cs <= S_M2S_END;
                        end
                        else
                          i_cntb <= i_cntb + 1'b1;

                        sr_mosi <= {sr_mosi[(CI_SPI_WIDTH - 2):0], i_spi_mosi}; //recieve MSB first
                    end
                end
            end

            S_M2S_END : begin //master 2 slave
                if (!i_spi_cs) begin
                    reg_wr_addr <= sr_mosi[(CI_SPI_WIDTH - 1):(CI_SPI_WIDTH - 8)];
                    reg_wr_data <= sr_mosi[((CI_SPI_WIDTH - 8) - 1):0];
                    reg_wr_en <= 1'b1;
                    i_fsm_cs <= S_IDLE; //Go to next packet
                end
            end

            S_S2M_MUX : begin //slave 2 master
                if (!i_spi_cs) begin
                    if (i_spi_ck_edge[0]) begin
                        if (i_cntb == (16 - 1)) begin
                            i_adr_rdata <= {sr_mosi[6:0], i_spi_mosi};
                            i_fsm_cs <= S_S2M;
                        end

                        i_cntb <= i_cntb + 1'b1;
                        sr_mosi <= {sr_mosi[(CI_SPI_WIDTH - 2):0], i_spi_mosi}; //recieve MSB first
                    end
                end
            end

            S_S2M : begin //slave 2 master
                if (!i_spi_cs) begin
                    if (i_spi_ck_edge[0]) begin
                        if (i_cntb == (CI_SPI_WIDTH - 1)) begin
                          i_fsm_cs <= S_IDLE;
                        end
                        else begin
                          i_cntb <= i_cntb + 1'b1;
                        end
                    end

                    if (i_spi_ck_edge[1]) begin //select & send read data
                        if (i_cntb == 16) begin
                            sr_miso <= reg_rd_data[(i_adr_rdata * 8) +: 16]; //Read Reg16bit
                        end
                        else begin
                            sr_miso <= {sr_miso[14:0], 1'b0};//send MSB first
                        end
                    end
                end
            end

            S_WAIT_END : begin
                if (i_spi_cs) begin
                    if (i_spi_ck_edge[0]) begin
                        if (i_cntb == (CI_SPI_WIDTH - 1)) begin
                          i_fsm_cs <= S_IDLE;
                        end
                        else begin
                          i_cntb <= i_cntb + 1'b1;
                        end
                    end
                end
            end

        endcase
    end
end

assign p_out_spi_miso = sr_miso[15];

endmodule