//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 22.05.2018 11:58:21
// Module Name : filter_core_7x7
//
// Description :
//
//------------------------------------------------------------------------

module filter_core_7x7 #(
    parameter DE_I_PERIOD = 0, //0 - no empty cycles
                               //2 - 1 empty cycle per pixel
                               //4 - 3 empty cycle per pixel
                               //etc...
    parameter LINE_SIZE_MAX = 1024,
    parameter DATA_WIDTH = 12
)(
    input bypass,

    //input resolution X * Y
    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    //output resolution (X - 6) * (Y - 6)
    //pixel pattern:
    //line[0]: x00 x01 x02 x03 x04 x05 x06
    //line[1]: x07 x08 x09 x10 x11 x12 x13
    //line[2]: x14 x15 x16 x17 x18 x19 x20
    //line[3]: x21 x22 x23 x24 x25 x26 x27
    //line[4]: x28 x29 x30 x31 x32 x33 x34
    //line[5]: x35 x36 x37 x38 x39 x40 x41
    //line[6]: x42 x43 x44 x45 x46 x47 x48
    output reg [DATA_WIDTH-1:0] x00 = 0,
    output reg [DATA_WIDTH-1:0] x01 = 0,
    output reg [DATA_WIDTH-1:0] x02 = 0,
    output reg [DATA_WIDTH-1:0] x03 = 0,
    output reg [DATA_WIDTH-1:0] x04 = 0,
    output reg [DATA_WIDTH-1:0] x05 = 0,
    output reg [DATA_WIDTH-1:0] x06 = 0,
    output reg [DATA_WIDTH-1:0] x07 = 0,
    output reg [DATA_WIDTH-1:0] x08 = 0,
    output reg [DATA_WIDTH-1:0] x09 = 0,
    output reg [DATA_WIDTH-1:0] x10 = 0,
    output reg [DATA_WIDTH-1:0] x11 = 0,
    output reg [DATA_WIDTH-1:0] x12 = 0,
    output reg [DATA_WIDTH-1:0] x13 = 0,
    output reg [DATA_WIDTH-1:0] x14 = 0,
    output reg [DATA_WIDTH-1:0] x15 = 0,
    output reg [DATA_WIDTH-1:0] x16 = 0,
    output reg [DATA_WIDTH-1:0] x17 = 0,
    output reg [DATA_WIDTH-1:0] x18 = 0,
    output reg [DATA_WIDTH-1:0] x19 = 0,
    output reg [DATA_WIDTH-1:0] x20 = 0,
    output reg [DATA_WIDTH-1:0] x21 = 0,
    output reg [DATA_WIDTH-1:0] x22 = 0,
    output reg [DATA_WIDTH-1:0] x23 = 0,
    output reg [DATA_WIDTH-1:0] x24 = 0, //can be use like bypass
    output reg [DATA_WIDTH-1:0] x25 = 0,
    output reg [DATA_WIDTH-1:0] x26 = 0,
    output reg [DATA_WIDTH-1:0] x27 = 0,
    output reg [DATA_WIDTH-1:0] x28 = 0,
    output reg [DATA_WIDTH-1:0] x29 = 0,
    output reg [DATA_WIDTH-1:0] x30 = 0,
    output reg [DATA_WIDTH-1:0] x31 = 0,
    output reg [DATA_WIDTH-1:0] x32 = 0,
    output reg [DATA_WIDTH-1:0] x33 = 0,
    output reg [DATA_WIDTH-1:0] x34 = 0,
    output reg [DATA_WIDTH-1:0] x35 = 0,
    output reg [DATA_WIDTH-1:0] x36 = 0,
    output reg [DATA_WIDTH-1:0] x37 = 0,
    output reg [DATA_WIDTH-1:0] x38 = 0,
    output reg [DATA_WIDTH-1:0] x39 = 0,
    output reg [DATA_WIDTH-1:0] x40 = 0,
    output reg [DATA_WIDTH-1:0] x41 = 0,
    output reg [DATA_WIDTH-1:0] x42 = 0,
    output reg [DATA_WIDTH-1:0] x43 = 0,
    output reg [DATA_WIDTH-1:0] x44 = 0,
    output reg [DATA_WIDTH-1:0] x45 = 0,
    output reg [DATA_WIDTH-1:0] x46 = 0,
    output reg [DATA_WIDTH-1:0] x47 = 0,
    output reg [DATA_WIDTH-1:0] x48 = 0,

    output reg de_o = 0,
    output reg hs_o = 0,
    output reg vs_o = 0,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
localparam PIPELINE = (DE_I_PERIOD == 0) ? 16 : (DE_I_PERIOD*16);

//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf0 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf1 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf2 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf3 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf4 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf5 [LINE_SIZE_MAX-1:0];
reg [DATA_WIDTH-1:0] buf0_do;
reg [DATA_WIDTH-1:0] buf1_do;
reg [DATA_WIDTH-1:0] buf2_do;
reg [DATA_WIDTH-1:0] buf3_do;
reg [DATA_WIDTH-1:0] buf4_do;
reg [DATA_WIDTH-1:0] buf5_do;

reg [$clog2(LINE_SIZE_MAX)-1:0] buf_wptr = 0;
wire buf_wptr_clr;
wire buf_wptr_en;

reg [DATA_WIDTH-1:0] sr_di_i [0:6];
reg [DATA_WIDTH-1:0] sr_buf1_do [0:0];
reg [DATA_WIDTH-1:0] sr_buf2_do [0:1];
reg [DATA_WIDTH-1:0] sr_buf3_do [0:2];
reg [DATA_WIDTH-1:0] sr_buf4_do [0:3];
reg [DATA_WIDTH-1:0] sr_buf5_do [0:4];

reg [0:(PIPELINE+1)] sr_de_i = 0;
reg [0:7] sr_hs_i = 0;
reg [0:(PIPELINE)] sr_vs_i = 0;

reg [0:3] line_out_en;

wire vs_opt;
wire buf_wptr_en_opt;
wire sr_hs_i_opt;
assign vs_opt = vs_i | sr_vs_i[PIPELINE-1];
assign buf_wptr_en_opt = (hs_i & (~sr_hs_i[4]));
assign sr_hs_i_opt = (hs_i & (~sr_hs_i[7]));

assign buf_wptr_clr = (!sr_hs_i[4] && sr_hs_i[3] & sr_de_i[PIPELINE-1]);
assign buf_wptr_en = de_i | (buf_wptr_en_opt & sr_de_i[PIPELINE-1]);

always @(posedge clk) begin : buf_line5
    if (buf_wptr_en) begin
        buf5[buf_wptr] <= di_i;
        buf5_do <= buf5[buf_wptr];
    end
end

always @(posedge clk) begin : buf_line4
    if (buf_wptr_en) begin
        buf4[buf_wptr] <= buf5_do;
        buf4_do <= buf4[buf_wptr];
    end
end

always @(posedge clk) begin : buf_line3
    if (buf_wptr_en) begin
        buf3[buf_wptr] <= buf4_do;
        buf3_do <= buf3[buf_wptr];
    end
end

always @(posedge clk) begin : buf_line2
    if (buf_wptr_en) begin
        buf2[buf_wptr] <= buf3_do;
        buf2_do <= buf2[buf_wptr];
    end
end

always @(posedge clk) begin : buf_line1
    if (buf_wptr_en) begin
        buf1[buf_wptr] <= buf2_do;
        buf1_do <= buf1[buf_wptr];
    end
end

always @(posedge clk) begin : buf_line0
    if (buf_wptr_en) begin
        buf0[buf_wptr] <= buf1_do;
        buf0_do <= buf0[buf_wptr];
    end
end

always @(posedge clk) begin
    if (buf_wptr_clr) begin
        buf_wptr <= 0;

    end else if (buf_wptr_en) begin
        buf_wptr <= buf_wptr + 1'b1;

        //align
        sr_di_i[0] <= di_i;
        sr_di_i[1] <= sr_di_i[0];
        sr_di_i[2] <= sr_di_i[1];
        sr_di_i[3] <= sr_di_i[2];
        sr_di_i[4] <= sr_di_i[3];
        sr_di_i[5] <= sr_di_i[4];
        x48 <= sr_di_i[5];
        x47 <= x48;
        x46 <= x47;
        x45 <= x46;
        x44 <= x45;
        x43 <= x44;
        x42 <= x43;

        sr_buf5_do[0] <= buf5_do;
        sr_buf5_do[1] <= sr_buf5_do[0];
        sr_buf5_do[2] <= sr_buf5_do[1];
        sr_buf5_do[3] <= sr_buf5_do[2];
        sr_buf5_do[4] <= sr_buf5_do[3];
        x41 <= sr_buf5_do[4];
        x40 <= x41;
        x39 <= x40;
        x38 <= x39;
        x37 <= x38;
        x36 <= x37;
        x35 <= x36;

        sr_buf4_do[0] <= buf4_do;
        sr_buf4_do[1] <= sr_buf4_do[0];
        sr_buf4_do[2] <= sr_buf4_do[1];
        sr_buf4_do[3] <= sr_buf4_do[2];
        x34 <= sr_buf4_do[3];
        x33 <= x34;
        x32 <= x33;
        x31 <= x32;
        x30 <= x31;
        x29 <= x30;
        x28 <= x29;

        sr_buf3_do[0] <= buf3_do;
        sr_buf3_do[1] <= sr_buf3_do[0];
        sr_buf3_do[2] <= sr_buf3_do[1];
        x27 <= sr_buf3_do[2];
        x26 <= x27;
        x25 <= x26;
        x24 <= x25;
        x23 <= x24;
        x22 <= x23;
        x21 <= x22;

        sr_buf2_do[0] <= buf2_do;
        sr_buf2_do[1] <= sr_buf2_do[0];
        x20 <= sr_buf2_do[1];
        x19 <= x20;
        x18 <= x19;
        x17 <= x18;
        x16 <= x17;
        x15 <= x16;
        x14 <= x15;

        sr_buf1_do[0] <= buf1_do;
        x13 <= sr_buf1_do[0];
        x12 <= x13;
        x11 <= x12;
        x10 <= x11;
        x09 <= x10;
        x08 <= x09;
        x07 <= x08;

        x06 <= buf0_do;
        x05 <= x06;
        x04 <= x05;
        x03 <= x04;
        x02 <= x03;
        x01 <= x02;
        x00 <= x01;
    end
end

always @(posedge clk) begin
    sr_de_i <= {de_i, sr_de_i[0:(PIPELINE-1)]};
    sr_vs_i <= {vs_i, sr_vs_i[0:(PIPELINE-1)]};
    if (de_i || (sr_hs_i_opt && sr_de_i[PIPELINE-1])) begin
        sr_hs_i <= {hs_i, sr_hs_i[0:6]};
    end
end

always @(posedge clk) begin
    if (!vs_opt) begin
        line_out_en <= 0;
    end else if (buf_wptr_clr) begin
        line_out_en <= {1'b1, line_out_en[0:2]};
    end
end

always @(posedge clk) begin
    if (!bypass) begin
        de_o <= (&line_out_en) & !sr_hs_i[3] & !sr_hs_i[7] & buf_wptr_en;
        hs_o <= ~((&line_out_en) & !sr_hs_i[3] & !sr_hs_i[7]);
        vs_o <= sr_vs_i[(PIPELINE-1)];
    end else begin
        de_o <= de_i;
        hs_o <= hs_i;
        vs_o <= vs_i;
    end
end


endmodule
