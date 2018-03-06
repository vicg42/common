//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 25.07.2016 18:31:51
// Module Name : spi_master
//
// Description :
//       bit:|(G_SPI_WIDTH - 1)..........0|
// SPI_MOSI :|lsb......................msb|
// SPI_MISO :
// Module send/recieve LSB first!!!
// for send/recieve MSB first user must swap bit on port p_in_txd/p_out_rxd
//
// SPI MODE = 3 (CPOL = 1, CPHA = 1)
// CPOL=1 - the base value of the clock is one (inversion of CPOL=0), i.e.
//          the active state is 0 and idle state is 1.
// CPHA=1 - data are captured on clock's rising edge and data is output on a falling edge.
//
//------------------------------------------------------------------------
module spi_master #(
parameter G_FRQ_DIV = 3,
parameter G_PRE_DLY = 3,
parameter G_SPI_WIDTH = 32 //Max 32
)(
//spi port
output reg p_out_spi_ck = 1'b1,
output reg p_out_spi_cs = 1'b1,
output     p_out_spi_mosi,
input      p_in_spi_miso,

//user if
input  p_in_start,
input [(G_SPI_WIDTH - 1):0] p_in_txd,
output reg [(G_SPI_WIDTH - 1):0] p_out_rxd = 0,

//sys
input p_in_clk,
input p_in_rst
);

// -------------------------------------------------------------------------
localparam S_IDLE = 0;
localparam S_PRE  = 1;
localparam S_TX   = 2;
reg [1:0] i_fsm_cs = S_IDLE; //current state

reg [7:0] i_cntf = 0; //ferq cnt
reg [4:0] i_cntb = 0; //bit cnt
reg [(G_SPI_WIDTH - 1):0] sr_miso = 0;
reg [(G_SPI_WIDTH - 1):0] sr_mosi = 0;

always @(posedge p_in_clk) begin
    if (p_in_rst) begin
        i_fsm_cs <= S_IDLE;
        i_cntf <= 0;
        i_cntb <= 0;
        sr_miso <= 0;
        sr_mosi <= 0;
    end
    else begin
        case (i_fsm_cs)
            S_IDLE: begin
                if (p_in_start) begin
                    i_cntb <= 0;
                    i_cntf <= 0;
                    p_out_spi_cs <= 1'b0;
                    sr_miso <= 0;
                    i_fsm_cs <= S_PRE;
                end
                else begin
                  p_out_spi_cs <= 1'b1;
                  p_out_spi_ck <= 1'b1;
                end
            end

            S_PRE: begin
                if (i_cntf == (G_PRE_DLY - 1)) begin
                    i_cntf <= 0;
                    p_out_spi_ck <= 1'b0;
                    sr_mosi <= p_in_txd;
                    i_fsm_cs <= S_TX;
                end
                else
                    i_cntf <= i_cntf + 1'b1;
            end

            S_TX: begin
                if (i_cntf == ((G_FRQ_DIV / 2) - 1)) begin
                    p_out_spi_ck <= 1'b1;
                    sr_miso <= {p_in_spi_miso, sr_miso[(G_SPI_WIDTH - 1):1]}; //recieve LSB first
                end

                if (i_cntf == (G_FRQ_DIV - 1)) begin
                    i_cntf <= 0;
                    p_out_spi_ck <= 1'b0;
                    sr_mosi <= {1'b0, sr_mosi[(G_SPI_WIDTH - 1):1]};
                    if (i_cntb == (G_SPI_WIDTH - 1)) begin
                        i_cntb <= 0;
                        p_out_spi_ck <= 1'b1;
                        p_out_spi_cs <= 1'b1;
                        p_out_rxd <= sr_miso;
                        i_fsm_cs <= S_IDLE;
                    end
                    else
                        i_cntb <= i_cntb + 1'b1;
                end
                else
                    i_cntf <= i_cntf + 1'b1;
            end

            default: i_fsm_cs <= S_IDLE; // fsm recovery
        endcase
    end
end

assign p_out_spi_mosi = sr_mosi[0]; //send LSB first

endmodule
