//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 11.06.2018 11:52:24
// Module Name : bmp_io
//
// Description :
// --------------------------------
// Example read from bmp file:
// --------------------------------
// 1. Create instance of class BMP_IO
//      BMP_IO image_in
//      image_in = new();
//
// 2. Read image data to internal buffer of class BMP_IO
//      image_in.fread("test_image.bmp");
//
// 3. Get image data from internal buffer of class BMP_IO
//      for(y = 0; y < image_in.get_y(); y++) begin
//          for(x = 0; x < image_in.get_x(); x++) begin
//              fr_pix = image_in.get_pixel(x, y);
//              readBMP_data = fr_pix[7:0];
//          end
//      end
//
// --------------------------------
// Example write to bmp file:
// --------------------------------
// 1. Create instance of class BMP_IO
//      BMP_IO image_out
//      image_out = new();
//
// 2. In testbanch create tmp buffer and write image data to it.
//    for (i = 0; i < (writeBMP_monitor_xcnt * writeBMP_monitor_ycnt); i++) begin
//      video_buf_out[i] = i;
//    end
// 3. Write image data to bmp file
//    //allocated memary for video data
//    image_out.set_pixel_array(writeBMP_monitor_xcnt, writeBMP_monitor_ycnt, 1);
//    //copy video data
//    for (i = 0; i < (writeBMP_monitor_xcnt * writeBMP_monitor_ycnt * 1); i++) begin
//    image_out.set_pixel(i, video_buf_out[i]);
//    end
//    //write data to bmp file
//    image_out.fwrite(writeBMP_filename, WRITE_BMP_BIT_COUNT
//                   , writeBMP_monitor_xcnt, writeBMP_monitor_ycnt);
//------------------------------------------------------------------------

class BMP_IO ; //#(parameter int PIXEL_WIDTH = 8);
    int fr_xcnt;
    int fr_ycnt;
    int bcnt;
    int fr_end;
    logic [7:0] pixel;
    logic [31:0] pixel_32b;

    int fd;//file descriptor
    int status;
    int align;
    int padding;

    logic [7:0] img_hdr [2048]; //Max header size 2048 byte!!!
    int img_data [];

    int BMP_signature;
    int filesize;
    int data_offset;
    int info_size;
    int info_width = 0;
    int info_height = 0;
    int info_planes;
    int info_bit_count;
    int info_compression;
    int info_image_size;
    int info_x_pixels_pre_meter;
    int info_y_pixels_pre_meter;
    int info_colors_used;

    int READ_BMP_DATA_CNT;
    int READ_BMP_VERBOSE;

    int raw_data_size;

    // Class Constructor
    function new () ;
        int i;

        fr_xcnt = 0;
        fr_ycnt = 0;
        fr_end = 0;

        fd = 0;
        status = 0;

        info_width = 0;
        info_height = 0;

        align = 4;//byte count
        padding = 0;

        for (i = 0; i < $size(img_hdr); i++) begin
            img_hdr[i] = 0;
        end

        READ_BMP_DATA_CNT = 0;
        READ_BMP_VERBOSE = 0;

    endfunction : new


    function int get_x();
        return info_width;
    endfunction : get_x


    function int get_y();
        return info_height;
    endfunction : get_y

    function int get_ColortBitCount();
        return info_bit_count;
    endfunction : get_ColortBitCount

    function int get_pixel(int x, int y);
        return img_data[x + (y * info_width)];
    endfunction : get_pixel


    function void set_pixel_array(int size);
        img_data = new [size];
    endfunction : set_pixel_array


    function void set_pixel(int idx, int value);
        img_data[idx] = value;
    endfunction : set_pixel


    function int get_raw_data(int x);
        return img_data[x];
    endfunction : get_raw_data

    function int get_raw_data_size();
        return raw_data_size;
    endfunction : get_raw_data_size

    task fread_raw (string filename);
        int i;

        fd = $fopen(filename,"rb");
        if (fd == 0) begin
            $display("\t Error: filename - bad value !");
            $stop;
        end

        //get file size:
        while (! $feof(fd)) begin
            pixel = $fgetc(fd);
            raw_data_size++;
        end

        if (raw_data_size == 0) begin
            $display("\t Error: raw_data_size = 0 !");

        end else begin

            raw_data_size--;

            img_data = new[raw_data_size];

            status = $fseek(fd, 0, 0);
            if (status < 0) begin
                $stop;
            end

            //$display("\t fread_raw: read data");
            i = 0;
            while(! $feof(fd)) begin
                pixel = $fgetc(fd);
                img_data[i++] = {pixel};
            end
        end

        $fclose(fd);

    endtask : fread_raw


    task fread_bmp (string filename);
        int i;

        //------------------------------
        //get info input image:
        //------------------------------
        fd = $fopen(filename,"rb");
        if (fd == 0) begin
            $display("\t Error: filename - bad value !");
            $stop;
        end

        status = $fread(img_hdr, fd);

        filesize = 0;                for (i = 0; i < 4; i++) filesize[(8*i) +: 8]                = img_hdr[2  + i];
        data_offset = 0;             for (i = 0; i < 4; i++) data_offset[(8*i) +: 8]             = img_hdr[10 + i];
        info_size = 0;               for (i = 0; i < 4; i++) info_size[(8*i) +: 8]               = img_hdr[14 + i];
        info_width = 0;              for (i = 0; i < 4; i++) info_width[(8*i) +: 8]              = img_hdr[18 + i];
        info_height = 0;             for (i = 0; i < 4; i++) info_height[(8*i) +: 8]             = img_hdr[22 + i];
        info_planes = 0;             for (i = 0; i < 2; i++) info_planes[(8*i) +: 8]             = img_hdr[26 + i];
        info_bit_count = 0;          for (i = 0; i < 2; i++) info_bit_count[(8*i) +: 8]          = img_hdr[28 + i];
        info_compression = 0;        for (i = 0; i < 4; i++) info_compression[(8*i) +: 8]        = img_hdr[30 + i];
        info_image_size = 0;         for (i = 0; i < 4; i++) info_image_size[(8*i) +: 8]         = img_hdr[34 + i];
        info_x_pixels_pre_meter = 0; for (i = 0; i < 4; i++) info_x_pixels_pre_meter[(8*i) +: 8] = img_hdr[38 + i];
        info_y_pixels_pre_meter = 0; for (i = 0; i < 4; i++) info_y_pixels_pre_meter[(8*i) +: 8] = img_hdr[42 + i];
        info_colors_used = 0;        for (i = 0; i < 4; i++) info_colors_used[(8*i) +: 8]        = img_hdr[46 + i];

        $display("ReadBMP: %s                     ", filename               );
        $display("\tFileSize: \t\t\t%04d          ", filesize               );
        $display("\tDataOffset: \t\t\t%04d        ", data_offset            );
        $display("\tInfoHeaderSize: \t\t\t%04d    ", info_size              );
        $display("\tWidth: \t\t\t%04d             ", info_width             );
        $display("\tHeight: \t\t\t%04d            ", info_height            );
        $display("\tPlanes: \t\t\t%04d            ", info_planes            );
        $display("\tBitCount: \t\t\t%04d          ", info_bit_count         );
        $display("\tCompresion: \t\t\t%04d        ", info_compression       );
        $display("\tImageSize: \t\t\t%04d         ", info_image_size        );
        $display("\tXpixelPreM: \t\t\t%04d        ", info_x_pixels_pre_meter);
        $display("\tYpixelPreM: \t\t\t%04d        ", info_y_pixels_pre_meter);
        $display("\tColor: \t\t\t%04d             ", info_colors_used       );

        status = $fseek(fd, data_offset, 0);
        if (status < 0) begin
            $stop;
        end

        if ((info_width > 0) & (info_height > 0)) begin
            img_data = new[info_width * info_height];
        end else begin
            $display("Error: bad value info_width or info_height");
            $stop;
        end

        //------------------------------
        //get data input image:
        //------------------------------
        fr_xcnt = 0;
        fr_ycnt = 0;
        bcnt = 0;
        fr_end = 0;
        pixel_32b = 0;

    if (info_bit_count == 8) begin
        padding = align - ((info_width * (info_bit_count/8)) & (align - 1));
//        $display("align: %04d; padding: %04d", align, padding);
        for (fr_ycnt = 0; fr_ycnt < info_height; fr_ycnt++) begin
            for (fr_xcnt = 0; fr_xcnt < info_width; fr_xcnt++) begin

                if (READ_BMP_DATA_CNT) begin
                    pixel = (fr_xcnt + (fr_ycnt * info_width)) + 1;
                end else begin
                    pixel = $fgetc(fd);
                end

                //save image data
                img_data[fr_xcnt + (fr_ycnt * info_width)] = {pixel};

                if (READ_BMP_VERBOSE) begin
                    if (fr_ycnt == 0) begin
                        $display("\t x=%04d; y=%04d; img_data[%04d] = %h", fr_xcnt
                                                                         , fr_ycnt
                                                                         , (fr_xcnt + (fr_ycnt * info_width))
                                                                         , img_data[fr_xcnt + (fr_ycnt * info_width)]);
                    end
                end

            end //fr_xcnt

            if (padding < align) begin
                for (i = 0; i < padding; i++) begin
                    pixel = $fgetc(fd);
                end
            end

        end //fr_ycnt
    end else if (info_bit_count == 24) begin
        padding = align - ((info_width * (info_bit_count/8)) & (align - 1));
        for (fr_ycnt = 0; fr_ycnt < info_height; fr_ycnt++) begin
            for (fr_xcnt = 0; fr_xcnt < info_width; fr_xcnt++) begin
                for (bcnt = 0; bcnt < info_bit_count; bcnt+=8) begin
                    pixel_32b[bcnt +: 8] = $fgetc(fd);
                end

                //save image data
                //pixel_32b[0  +: 8] - B
                //pixel_32b[8  +: 8] - G
                //pixel_32b[16 +: 8] - R
                img_data[fr_xcnt + (fr_ycnt * info_width)] = {pixel_32b};

                if (READ_BMP_VERBOSE) begin
                    if (fr_ycnt == 0) begin
                        $display("\t x=%04d; y=%04d; img_data[%04d] = %h", fr_xcnt
                                                                         , fr_ycnt
                                                                         , (fr_xcnt + (fr_ycnt * info_width))
                                                                         , img_data[fr_xcnt + (fr_ycnt * info_width)]);
                    end
                end
            end //fr_xcnt

            if (padding < align) begin
                for (i = 0; i < padding; i++) begin
                    pixel = $fgetc(fd);
                end
            end
        end //fr_ycnt
    end else begin
        $display("\t info_bit_count = %d - don't support", info_bit_count);
        $stop;
    end

    endtask : fread_bmp


    task fwrite_bmp (
                   input string filename
                 , input int bit_count //24 - for color image, 8 - for grayscale image
                 , input int img_width
                 , input int img_height
                  );
            int i;
            int idx;

            if ((img_width <= 0) & (img_height <= 0)) begin
                $display("\t Error: img_width, img_height - bad value !");
                $stop;
            end

            if ((bit_count != 24) & (bit_count != 8)) begin
                $display("\t Error: bit_count - bad value !");
                $stop;
            end

            for (i = 0; i < $size(img_hdr); i++) begin
                img_hdr[i] = 0;
            end

            BMP_signature = 16'h4D42;
            info_size = 40;//byte

            data_offset = 54;//byte
            info_width = img_width;
            info_height = img_height;
            info_planes = 1;
            info_bit_count = bit_count;
            info_compression = 0;
            info_image_size = 0;
            info_x_pixels_pre_meter = 0;
            info_y_pixels_pre_meter = 0;
            if (info_bit_count == 24) begin
            info_colors_used = 0;
            end else begin
            info_colors_used = 256;
            end

            //write color table
            if (info_bit_count == 8) begin
                fr_xcnt = 0;
                for (i = 0; i < (info_colors_used * 4); i++) begin
                    if (fr_xcnt < 3) begin
                        img_hdr[(data_offset + i)] = i[9:2];
                    end else begin
                        img_hdr[(data_offset + i)] = 0;
                    end

                    if (fr_xcnt == 3) fr_xcnt = 0;
                    else fr_xcnt++;
                end

                data_offset += (info_colors_used * 4);
            end

            //------------------------------
            //write image data:
            //------------------------------
            fd = $fopen(filename,"wb");
            if (fd == 0) begin
                $display("\t Error: filename - bad value !");
                $stop;
            end

            status = $fseek(fd, data_offset, 0);
            if (status < 0) begin
                $stop;
            end

            idx =0;
            info_image_size = 0;
            filesize = 0;
            padding = align - ((info_width * (info_bit_count/8)) & (align - 1));
//            $display("align: %04d; padding: %04d", align, padding);
            for (fr_ycnt = 0; fr_ycnt < info_height; fr_ycnt++) begin
                for (fr_xcnt = 0; fr_xcnt < info_width; fr_xcnt++) begin
                    //write pixel value
                    if (info_bit_count == 24) begin
                        $fwrite(fd, "%c", img_data[idx++]);
                        $fwrite(fd, "%c", img_data[idx++]);
                        $fwrite(fd, "%c", img_data[idx++]);
                    end else begin
                        $fwrite(fd, "%c", img_data[idx++]);
                    end
                    info_image_size += (info_bit_count/8);
                    filesize += (info_bit_count/8);
                end
                if (padding < align) begin
                    for (i = 0; i < padding; i++) begin
                        $fwrite(fd, "%c", 0);
                    end
                    info_image_size += padding;
                    filesize += padding;
                end
            end

            filesize += data_offset;

            //------------------------------
            //write header BMP:
            //------------------------------
            status = $fseek(fd, 0, 0);
            if (status < 0) begin
                $stop;
            end

            for (i = 0; i < 2; i++) img_hdr[0  + i] = BMP_signature[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[2  + i] = filesize[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[10 + i] = data_offset[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[14 + i] = info_size[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[18 + i] = info_width[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[22 + i] = info_height[(8*i) +: 8];
            for (i = 0; i < 2; i++) img_hdr[26 + i] = info_planes[(8*i) +: 8];
            for (i = 0; i < 2; i++) img_hdr[28 + i] = info_bit_count[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[30 + i] = info_compression[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[34 + i] = info_image_size[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[38 + i] = info_x_pixels_pre_meter[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[42 + i] = info_y_pixels_pre_meter[(8*i) +: 8];
            for (i = 0; i < 4; i++) img_hdr[46 + i] = info_colors_used[(8*i) +: 8];

            $display("");
            $display("WriteBMP: %s                    ", filename               );
            $display("\tFileSize: \t\t\t%04d          ", filesize               );
            $display("\tDataOffset: \t\t\t%04d        ", data_offset            );
            $display("\tInfoHeaderSize: \t\t\t%04d    ", info_size              );
            $display("\tWidth: \t\t\t%04d             ", info_width             );
            $display("\tHeight: \t\t\t%04d            ", info_height            );
            $display("\tPlanes: \t\t\t%04d            ", info_planes            );
            $display("\tBitCount: \t\t\t%04d          ", info_bit_count         );
            $display("\tCompresion: \t\t\t%04d        ", info_compression       );
            $display("\tImageSize: \t\t\t%04d         ", info_image_size        );
            $display("\tXpixelPreM: \t\t\t%04d        ", info_x_pixels_pre_meter);
            $display("\tYpixelPreM: \t\t\t%04d        ", info_y_pixels_pre_meter);
            $display("\tColor: \t\t\t%04d             ", info_colors_used       );

            for (i = 0; i < (data_offset); i++) begin
                $fwrite(fd, "%c", img_hdr[i]);
            end

            $fclose(fd);
    endtask : fwrite_bmp


    task fwrite_raw (
                   input string filename
                 , input [31:0] bit_count //24, 16, 8
                 , input [31:0] img_width
                 , input [31:0] img_height
                  );
            int idx;

            if ((img_width <= 0) & (img_height <= 0)) begin
                $display("\t Error: img_width, img_height - bad value !");
                $stop;
            end

            if ((bit_count != 24) & (bit_count != 16) & (bit_count != 8)) begin
                $display("\t Error: bit_count - bad value !");
                $stop;
            end

            //------------------------------
            //write image data:
            //------------------------------
            fd = $fopen(filename,"wb");
            if (fd == 0) begin
                $display("\t Error: filename - bad value !");
                $stop;
            end
            idx = 0;

            for (fr_ycnt = 0; fr_ycnt < img_height; fr_ycnt++) begin
                for (fr_xcnt = 0; fr_xcnt < img_width; fr_xcnt++) begin
                    //write pixel value
                    if (bit_count == 24) begin
                        $fwrite(fd, "%c", img_data[idx++]);
                        $fwrite(fd, "%c", img_data[idx++]);
                        $fwrite(fd, "%c", img_data[idx++]);
                    end else if (bit_count == 16) begin
                        $fwrite(fd, "%c", img_data[idx++]);
                        $fwrite(fd, "%c", img_data[idx++]);
                    end else if (bit_count == 8) begin
                        $fwrite(fd, "%c", img_data[idx++]);
                    end
                end
            end

            $display("WriteRAW:   %s  ", filename  );
            $display("\tbit_count:  %d  ", bit_count );
            $display("\timg_height: %d  ", img_height);
            $display("\timg_width:  %d  ", (bit_count == 24) ? img_width/3 : (bit_count == 16) ? img_width/2 : img_width);

            $fclose(fd);

    endtask : fwrite_raw

endclass : BMP_IO
