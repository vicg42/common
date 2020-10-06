//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//-----------------------------------------------------------------------
module timing_gen #(
    parameter PIXEL_WIDTH = 8
)(
    input [15:0] pix_count_i,
    input [15:0] line_count_i,
    input [15:0] hs_count_i,
    input [15:0] vs_count_i,

    output reg [PIXEL_WIDTH-1:0] do_o = 0,
    output reg                   de_o = 0,
    output reg                   hs_o = 0,
    output reg                   vs_o = 0,

    input clk
);

localparam LINE_MOVE_SPEED = 4;

`ifdef SIM_FSM
    enum int unsigned {
        IDLE,
        HS,
        PIX,
        VS1,
        VS2
    } fsm_cs = IDLE;
`else
    localparam  IDLE= 0;
    localparam  HS  = 1;
    localparam  PIX = 2;
    localparam  VS1 = 3;
    localparam  VS2 = 4;
    reg [2:0] fsm_cs = IDLE;
`endif

reg [15:0] pix_count = 16'd330;
reg [15:0] line_count = 16'd100;
reg [15:0] hs_count = 0;
reg [15:0] vs_count = 0;
reg [15:0] cnt_x = 0;
reg [15:0] cnt_y = 0;
reg [15:0] pix_cnt = 0;
reg [15:0] line_mv_speed = 0;
reg [15:0] line_mv = 0;
always @ (posedge clk) begin
    case (fsm_cs)
        IDLE : begin
            pix_count <= pix_count_i;
            line_count <= line_count_i;
            hs_count <= hs_count_i;
            vs_count <= vs_count_i;
            fsm_cs <= HS;
        end

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
                    if (line_mv_speed == (LINE_MOVE_SPEED -1)) begin
                        line_mv_speed <= 0;
                        if (line_mv == (line_count -1)) begin
                            line_mv <= 0;
                        end else begin
                            line_mv <= line_mv + 1;
                        end
                    end else begin
                        line_mv_speed <= line_mv_speed + 1;
                    end
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
            if (line_mv == cnt_y) begin
                do_o <= (pix_cnt[0]) ? 8'd128 : 8'd128;
            end else begin
                do_o <= (pix_cnt[0]) ? pix_cnt : 8'd128;
            end
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
                fsm_cs <= IDLE;
            end else begin
                cnt_y <= cnt_y + 1;
            end
        end
    endcase
end


endmodule
