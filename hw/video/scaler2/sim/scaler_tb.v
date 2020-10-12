`timescale 1ns / 1ps
module scaler_tb;

reg clk = 1;
always #0.5 clk = ~clk;
task tick;
    begin
        @(posedge clk);#0;
    end
endtask

initial begin
    forever begin
        #100000;
        $display("%d us", $time/1000);
    end
end


integer in;
integer out;
integer r;
integer x = 0;
integer y = 0;
logic [7:0] header[4*1024];
wire [31:0] image_offset = {header[13], header[12], header[11], header[10]};
wire [31:0] image_width =  {header[21], header[20], header[19], header[18]};
wire [31:0] image_height = {header[25], header[24], header[23], header[22]};
logic [7:0] pixel = 0;
integer i;
initial begin
    r = 0;
    in = $fopen("img_600x600_1x8bit_T01L01_GRAY_garden_table.bmp","rb");
    // in = $fopen("1-3ML.bmp","rb");
    out = $fopen("result_image.bmp","wb");
    r = $fread(header, in);
    for (i = 0; i < image_offset; i = i + 1) begin
        r = $fputc(header[i], out);
    end
    r = $fseek(in, image_offset, 0);
    d_in = 0;
    dv_in = 0;
    hs_in = 0;
    vs_in = 0;
    tick;
    tick;
    tick;
    tick;
    tick;
    tick;
    tick;
    forever begin
        tick;
        r = $fread(pixel, in);
        if (r == 0) begin // file end
            r = $fseek(in, image_offset, 0);
            r = $fread(pixel, in);
        end
        d_in = {pixel, 4'b0000};
        dv_in = 1;
        if (x == 0) hs_in = 1;
        if ((y == 0) && (x == 0)) vs_in = 1;
        x = x + 1;
        if (x == image_width) begin
            x = 0;
            y = y + 1;
            if (y == image_height) begin
                y = 0;
            end
        end
        tick;
        dv_in = 0;
        hs_in = 0;
        vs_in = 0;
        repeat (4) tick;
    end
end


integer out_x_cntr = 0;
integer out_y_cntr = 0;
integer out_width = 0;
integer out_height = 0;
wire [7:0] b = d_out[4 +: 8];
always @(posedge clk) begin
    if (dv_out) begin
        if (hs_out && vs_out) begin
            out_width = out_x_cntr;
            out_height = out_y_cntr;
            if ((out_width != 0) && (out_height != 0)) begin
                $display(out_width, out_height);
                r = $fseek(out, 18, 0);
                r = $fputc(out_width[0  +: 8], out);
                r = $fputc(out_width[8  +: 8], out);
                r = $fputc(out_width[16 +: 8], out);
                r = $fputc(out_width[24 +: 8], out);
                r = $fputc(out_height[0  +: 8], out);
                r = $fputc(out_height[8  +: 8], out);
                r = $fputc(out_height[16 +: 8], out);
                r = $fputc(out_height[24 +: 8], out);
                $finish;
            end
        end
        if (hs_out && !vs_out) begin // 4 byte boundary padding
            if (out_x_cntr[1:0] == 1) begin
                r = $fputc(0, out);
                r = $fputc(0, out);
                r = $fputc(0, out);
            end
            if (out_x_cntr[1:0] == 2) begin
                r = $fputc(0, out);
                r = $fputc(0, out);
            end
            if (out_x_cntr[1:0] == 3) begin
                r = $fputc(0, out);
            end
        end
        if (hs_out) out_x_cntr = 0;
        if (vs_out) out_y_cntr = 0;
        if (hs_out) out_y_cntr = out_y_cntr + 1;
        r = $fputc(b, out);
        out_x_cntr = out_x_cntr + 1;
    end
end


initial begin
    $dumpfile("icarus/scaler_tb.v.fst");
    $dumpvars;
    // $dumpvars(1);
    
    // #100;
    #50_000_000;
    
    $display("\007");
    $finish;
end

localparam WIDTH = 12;

// control interface
wire            reg_clk = clk;
logic [7:0]     reg_wr_addr = 0;
logic [23:0]    reg_wr_data = 0;
logic           reg_wr_en = 0;

// Video input
logic [WIDTH-1:0] d_in;
logic dv_in;
logic hs_in;
logic vs_in;

// Video output
logic [WIDTH-1:0] d_out;
logic dv_out;
logic hs_out;
logic vs_out;

scaler scaler(.*);

endmodule
