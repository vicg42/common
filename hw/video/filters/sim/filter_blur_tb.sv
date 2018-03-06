`timescale 1ns / 1ps
module filter_blur_tb;

//***********************************
//System clock gen
//***********************************
reg clk = 1;
reg rst = 0;
always #0.5 clk = ~clk;
task tick;
    begin : blk_clkgen
        @(posedge clk);#0;
    end : blk_clkgen
endtask : tick


//***********************************
//System time
//***********************************
initial begin
    forever begin
        #100000;
        $display("%d us", $time/1000);
    end
end



integer status;
integer i,x,y;

localparam WIDTH = 8;

// Video input
reg  [WIDTH-1:0]   d_in;
reg                dv_in;
reg                hs_in;
reg                vs_in;

// Video output
wire [WIDTH-1:0]   d_out;
wire               dv_out;
wire               hs_out;
wire               vs_out;


typedef struct {
    reg [15:0] signature;
    reg [31:0] filesize;  //offset 2
    reg [31:0] reserved;
    reg [31:0] data_offset;

    struct {
        reg [31:0] size;
        reg [31:0] width;
        reg [31:0] height;
        reg [15:0] planes;
        reg [15:0] bit_count;
        reg [15:0] compression;
        reg [31:0] image_size;
        reg [31:0] x_pixels_pre_meter;
        reg [31:0] y_pixels_pre_meter;
        reg [31:0] colors_used;
        reg [31:0] colors_important;
    } info;

    struct {
        reg [7:0] red;
        reg [7:0] green;
        reg [7:0] blue;
        reg [7:0] reserved;
    } color_table;

//    struct {
//    } image;
} t_bmp_header;


struct {
    t_bmp_header header;
} in_bmp;

struct {
    t_bmp_header header;
} out_bmp;


localparam FILE_OUT_COUNT = 3;
reg  [0:FILE_OUT_COUNT-1][63:0][7:0] str_array;
reg  [31:0] fd_o [0:FILE_OUT_COUNT-1];

integer in_fd;

//string imgi_name = "24x24_8bit_test1.bmp";
string imgi_name = "img_600x600_8bit.bmp";
//string imgi_name = "1-3ML.bmp";

logic [7:0] in_data [4*1024];

reg  [7:0]    in_val = 0;
reg  [31:0]   in_xcnt = 0;
reg  [31:0]   in_ycnt = 0;
reg  [31:0]   in_frame_cnt = 0;
reg  [7:0]    in_frame_end = 0;

reg  [23:0]   scale_w = 0;
reg  [23:0]   scale_h = 0;
reg  [23:0]   scaler_line_size = 0;


initial begin : video_in

    tick;
    rst = 0;
    tick;
    rst = 1;
    tick;
    rst = 0;

    status = 0;

    str_array[0]="blur_result_image1.bmp";
    str_array[1]="blur_result_image2.bmp";
    str_array[2]="blur_result_image3.bmp";

    //------------------------------
    //get info input image:
    //------------------------------
    in_fd = $fopen(imgi_name,"rb");
    if (in_fd == 0) begin
        $stop;
    end

    status = $fread(in_data, in_fd);

    in_bmp.header.filesize = {in_data[5], in_data[4], in_data[3], in_data[2]};
    in_bmp.header.data_offset = {in_data[13], in_data[12], in_data[11], in_data[10]};
    in_bmp.header.info.size = {in_data[17], in_data[16], in_data[15], in_data[14]};
    in_bmp.header.info.width = {in_data[21], in_data[20], in_data[19], in_data[18]};
    in_bmp.header.info.height = {in_data[25], in_data[24], in_data[23], in_data[22]};
    in_bmp.header.info.planes = {in_data[27], in_data[26]};
    in_bmp.header.info.bit_count = {in_data[29], in_data[28]};
    in_bmp.header.info.compression = {in_data[33], in_data[32], in_data[31], in_data[30]};
    in_bmp.header.info.image_size = {in_data[37], in_data[36], in_data[35], in_data[34]};
    in_bmp.header.info.x_pixels_pre_meter = {in_data[41], in_data[40], in_data[39], in_data[38]};
    in_bmp.header.info.y_pixels_pre_meter = {in_data[45], in_data[44], in_data[43], in_data[42]};
    in_bmp.header.info.colors_used = {in_data[49], in_data[48], in_data[47], in_data[46]};
//    in_bmp.header.info.compression = 0;
//    in_bmp.header.info.x_pixels_pre_meter = 0;
//    in_bmp.header.info.y_pixels_pre_meter = 0;
//    in_bmp.header.info.colors_used = 0;

    $display("Input Image: %s",imgi_name);
    $display("\tFileSize: %d", in_bmp.header.filesize);
    $display("\tDataOffset: %d", in_bmp.header.data_offset);
    $display("\tInfoHeaderSize: %d", in_bmp.header.info.size);
    $display("\tWidth: %d", in_bmp.header.info.width);
    $display("\tHeight: %d", in_bmp.header.info.height);
    $display("\tPlanes: %d", in_bmp.header.info.planes);
    $display("\tBitCount: %d", in_bmp.header.info.bit_count);
    $display("\tCompresion: %d", in_bmp.header.info.compression);
    $display("\tImageSize(Compresion): %d", in_bmp.header.info.image_size);
    $display("\tXpixelPreM: %d", in_bmp.header.info.x_pixels_pre_meter);
    $display("\tYpixelPreM: %d", in_bmp.header.info.y_pixels_pre_meter);
    $display("\tColor: %d", in_bmp.header.info.colors_used);

    $fclose(in_fd);

    //imgo_name[0]
    //copy data from input image to tamplate output image
    for (x = 0; x < $size(str_array) - 1; x += 1) begin
        fd_o[x] = $fopen(str_array[x],"wb");
        for (i = 0; i < in_bmp.header.data_offset; i += 1) begin
            $fwrite(fd_o[x], "%c", in_data[i]);
        end
        status = $fseek(fd_o[x], in_bmp.header.data_offset, 0);
    end


    //------------------------------
    //get video from input image:
    //------------------------------
    d_in = 0;
    dv_in = 0;
    hs_in = 0;
    vs_in = 0;
    tick;

    in_frame_cnt = 0;
    while(1) begin : vin_main_loop
        tick;
        in_fd = $fopen(imgi_name,"rb");
        $display("video_in: frame(%02d)", in_frame_cnt);
        if ((status = $fseek(in_fd, in_bmp.header.data_offset, 0)) < 0) begin
            $stop;
        end
        in_xcnt = 0;
        in_ycnt = 0;
        in_frame_end = 0;
        repeat (4*2) tick;

        do begin
            in_val = $fgetc(in_fd);

            d_in = {in_val}; //, 4'b0000};
            dv_in = 1;
            if (in_xcnt == 0) begin
                hs_in = 1;
            end

            if ((in_ycnt == 0) && (in_xcnt == 0)) begin
                vs_in = 1;
            end
            tick;

            dv_in = 0;

            if (in_xcnt == (in_bmp.header.info.width - 1)) begin
                in_xcnt = 0;
                if (in_ycnt == (in_bmp.header.info.height - 1)) begin
                    in_ycnt = 0;
                    in_frame_end = 1;
                end else begin
                    in_ycnt++;
                end
            end else begin
                in_xcnt++;
            end
//            repeat (4) tick;
            hs_in = 0;
            vs_in = 0;

        end while (in_frame_end < 1);
////        end while (!$feof(in_fd));
//        $fclose(in_fd);

        in_frame_cnt = in_frame_cnt + 1;
//        if (in_frame_cnt == 2) begin
//            $finish;
//        end
    end : vin_main_loop
end : video_in


reg [31:0] out_xcnt = 0;
reg [31:0] out_ycnt = 0;
integer out_frame_cnt = 0;

always @(posedge clk) begin : video_out
    if (dv_out) begin : dv_out

        //bmp image width must be multiple 4.
        //4 byte boundary padding
        if (hs_out) begin
            if (out_xcnt[1:0] == 1) begin
                $fwrite(fd_o[out_frame_cnt], "%c", 0);
                $fwrite(fd_o[out_frame_cnt], "%c", 0);
                $fwrite(fd_o[out_frame_cnt], "%c", 0);

            end else if (out_xcnt[1:0] == 2) begin
                $fwrite(fd_o[out_frame_cnt], "%c", 0);
                $fwrite(fd_o[out_frame_cnt], "%c", 0);

            end else if (out_xcnt[1:0] == 3) begin
                $fwrite(fd_o[out_frame_cnt], "%c", 0);
            end
        end

        //close output file image
        if (hs_out && vs_out) begin : close_out_bmp

            out_bmp.header.info = in_bmp.header.info;
            out_bmp.header.data_offset = in_bmp.header.data_offset;

            if (|out_xcnt[1:0]) begin
                out_bmp.header.info.width = out_xcnt + 4;
                out_bmp.header.info.width[1:0] = 0;
            end else begin
                out_bmp.header.info.width = out_xcnt;
            end

            out_bmp.header.info.height = out_ycnt;
            out_bmp.header.info.image_size = (out_bmp.header.info.width * out_bmp.header.info.height);
            out_bmp.header.filesize = (out_bmp.header.info.width * out_bmp.header.info.height) + in_bmp.header.data_offset;

            out_ycnt = 0;

            if ((out_bmp.header.info.width != 0) && (out_bmp.header.info.height != 0)) begin
                $display("Output Image: %s", str_array[out_frame_cnt]);
                $display("\tFileSize: %d", out_bmp.header.filesize);
                $display("\tDataOffset: %d", out_bmp.header.data_offset);
                $display("\tInfoHeaderSize: %d", out_bmp.header.info.size);
                $display("\tWidth: %d", out_bmp.header.info.width);
                $display("\tHeight: %d", out_bmp.header.info.height);
                $display("\tPlanes: %d", out_bmp.header.info.planes);
                $display("\tBitCount: %d", out_bmp.header.info.bit_count);
                $display("\tCompresion: %d", out_bmp.header.info.compression);
                $display("\tImageSize(Compresion): %d", out_bmp.header.info.image_size);
                $display("\tXpixelPreM: %d", out_bmp.header.info.x_pixels_pre_meter);
                $display("\tYpixelPreM: %d", out_bmp.header.info.y_pixels_pre_meter);
                $display("\tColor: %d", out_bmp.header.info.colors_used);

                if ((status = $fseek(fd_o[out_frame_cnt], 2, 0)) < 0) begin
                    $stop;
                end
                for (i = 0; i < $bits(out_bmp.header.filesize); i += 8) begin
                    $fwrite(fd_o[out_frame_cnt], "%c", out_bmp.header.filesize[i +: 8]);
                end

                if ((status = $fseek(fd_o[out_frame_cnt], 18, 0)) < 0) begin
                    $stop;
                end
                for (i = 0; i < $bits(out_bmp.header.info.width); i += 8) begin
                    $fwrite(fd_o[out_frame_cnt], "%c", out_bmp.header.info.width[i +: 8]);
                end

                if ((status = $fseek(fd_o[out_frame_cnt], 22, 0)) < 0) begin
                    $stop;
                end
                for (i = 0; i < $bits(out_bmp.header.info.height); i += 8) begin
                    $fwrite(fd_o[out_frame_cnt], "%c", out_bmp.header.info.height[i +: 8]);
                end

                if ((status = $fseek(fd_o[out_frame_cnt], 34, 0)) < 0) begin
                    $stop;
                end
                for (i = 0; i < $bits(out_bmp.header.info.image_size); i += 8) begin
                    $fwrite(fd_o[out_frame_cnt], "%c", out_bmp.header.info.image_size[i +: 8]);
                end

                $fclose(fd_o[out_frame_cnt]);
                out_frame_cnt++;

                if (out_frame_cnt == 2) begin
                $finish;
                end
            end
        end : close_out_bmp

        //write data to output image file
//        if (d_out > 200) begin
        $fwrite(fd_o[out_frame_cnt], "%c", d_out); //d_out[4 +: 8]);
//        end else begin
//        $fwrite(fd_o[out_frame_cnt], "%c", 0); //d_out[4 +: 8]);
//        end

        if (hs_out) begin
            out_xcnt = 0;
            out_ycnt = out_ycnt + 1;
        end

        out_xcnt = out_xcnt + 1;

    end : dv_out
end : video_out


//initial begin
//    $dumpfile("icarus/filter_blur_tb.v.fst");
//    $dumpvars;
//    // $dumpvars(1);
//
//    // #100;
////    #10000;
//    #50_000_000;
//
//    $fclose(fdo);
//    $display("\007");
//    $finish;
//end


filter_blur #(
    .WIDTH(WIDTH),
    .SPARSE_OUTPUT(0)
) filter_blur (
    // Video clock
    .clk(clk),
    .rst(rst),

    .pix_count(in_bmp.header.info.width[15:0]),
    .line_count(in_bmp.header.info.height[15:0]),

    .bypass (1'b0),

    // Video input
    .d_in (d_in ),
    .dv_in(dv_in),
    .hs_in(hs_in),
    .vs_in(vs_in),

    // Video output
    .dout (d_out ),
    .dv_out(dv_out),
    .hs_out(hs_out),
    .vs_out(vs_out)
);



endmodule
