//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//-----------------------------------------------------------------------
module timing_gen #(
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] pix_count,
    input [15:0] line_count,
    input [15:0] hs_count,
    input [15:0] vs_count,

    output reg [PIXEL_WIDTH-1:0] do_o = 0,
    output reg                   de_o = 0,
    output reg                   hs_o = 0,
    output reg                   vs_o = 0,

    input clk
);

`ifdef SIM_FSM
    enum int unsigned {
        HS,
        PIX,
        VS1,
        VS2
    } fsm_cs = HS;
`else
    localparam  HS  = 0;
    localparam  PIX = 1;
    localparam  VS1 = 2;
    localparam  VS2 = 2;
    reg [2:0] fsm_cs = HS;
`endif

reg [15:0] cnt_x = 0;
reg [15:0] cnt_y = 0;
reg [15:0] pix_cnt = 0;
always @ (posedge clk) begin
    case (fsm_cs)
        HS : begin
            pix_cnt <= 0;
            vs_o <= 1'b0;
            if (cnt_x == (hs_count -1)) begin
                cnt_x <= 0;
                hs_o <= 1'b1;
                fsm_cs <= PIX;
            end else begin
                cnt_x <= cnt_x + 1;
                hs_o <= 1'b0;
            end
        end

        PIX : begin
            if (cnt_x == (pix_count -1)) begin
                cnt_x <= 0;
                if (cnt_y == (line_count -1)) begin
                    cnt_y <= 0;
                    hs_o <= 1'b0;
                    // vs_o <= 1'b1;
                    fsm_cs <= VS1;
                end else begin
                    cnt_y <= cnt_y + 1;
                    fsm_cs <= HS;
                end
            end else begin
                cnt_x <= cnt_x + 1;
            end
            do_o <= (pix_cnt[0]) ? pix_cnt : 8'd128;
            pix_cnt <= pix_cnt + 1;
        end

        VS1 : begin
            pix_cnt <= 0;
            if (cnt_x == (hs_count -1)) begin
                cnt_x <= 0;
                vs_o <= 1'b1;
                fsm_cs <= VS2;
            end else begin
                cnt_x <= cnt_x + 1;
            end
        end

        VS2 : begin
            pix_cnt <= 0;
            if (cnt_y == (vs_count -1)) begin
                cnt_y <= 0;
                vs_o <= 1'b0;
                fsm_cs <= HS;
            end else begin
                cnt_y <= cnt_y + 1;
            end
        end
    endcase
end


endmodule
