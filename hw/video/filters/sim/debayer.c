#define _WIN32_WINNT 0x0600
#include <stdio.h>
#include <conio.h>
#include <windows.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>

/************************** Constant Definitions *****************************/
#define OUTPUT_FILE "_debayer_sw.bmp"

#define BGGR    (0)
#define RGGB    (1)
#define GBRG    (2)
#define GRBG    (3)

/**************************** Type Definitions *******************************/
typedef struct {
    char name[64];

    UINT32 filesize;//Size of the BMP file
    UINT32 data_offset;
    UINT32 width;
    UINT32 height;
    UINT16 planes;
    UINT16 bit_count;
    UINT32 compression;
    UINT32 image_size;
    UINT32 colors_used;
} img_t;


/***************** Macros (Inline Functions) Definitions *********************/

/************************** Variable Definitions *****************************/
img_t img_in;
img_t img_out;

UINT8 bayer_pttern;
UINT8 align;
UINT8 padding;
UINT8 mode;
UINT8 create_bmp_file;


/************************** Function Prototypes ******************************/
static int image_param(FILE *fi, img_t *img_in);
static int image_header_edit (FILE *fi, img_t *img_in);
static int write_bmp_file (img_t img_in, UINT8 *img_data);

static void debayer_bilinear(UINT8 **din, UINT32 din_width, UINT32 din_height, UINT8 bayer_pttern
                    , UINT8 **r_plane, UINT8 **g_plane, UINT8 **b_plane);

static void debayer_hq01(UINT8 **din, UINT32 din_width, UINT32 din_height, UINT8 bayer_pttern
                    , UINT8 **r_plane, UINT8 **g_plane, UINT8 **b_plane);

static void debayer_hq02(UINT8 **din, UINT32 din_width, UINT32 din_height, UINT8 bayer_pttern
                    , UINT8 **r_plane, UINT8 **g_plane, UINT8 **b_plane);


/******************************** main ***************************************/
int main(int argc, char const *argv[])
{
    UINT32 x,y;
    char local_str[64];

    if ((argc == 1) || (strcmp(argv[1], "-h") == 0) || (argc > 6)) {
        printf("Usage: filter_debayer.exe <input image> [option]\n");
        printf("Mandatory option:\n");
        printf("    -h          help \n");
        printf("    -c          create bmp file from raw: \n");
        printf("    -b          baeyr pattern: \n");
        printf("                  0 - BGGR: [B G]  (default)\n");
        printf("                            [G R] \n");
        printf("                                  \n");
        printf("                  1 - RGGB: [R G] \n"); //lighthouse.bmp
        printf("                            [G B] \n");
        printf("                                  \n");
        printf("                  2 - GBRG: [G B] \n"); //testimage_2.bmp
        printf("                            [R G] \n");
        printf("                                  \n");
        printf("                  3 - GRBG: [G R] \n");
        printf("                            [B G] \n");
        printf("                                  \n");
        printf("                                  \n");
        printf("    -m          mode:             \n");
        printf("                  0  - bilinear (default)  \n");
        printf("                  1  - hq         \n");
        return 0;
    }

    bayer_pttern = 0;
    align = sizeof(UINT32);
    padding = 0;

    memset((UINT8 *)&img_in, 0, sizeof(img_in));
    memset((UINT8 *)&img_out, 0, sizeof(img_out));

    if (argc >= 2) {
        memset(local_str, 0, sizeof(local_str));
        strncpy(img_in.name, argv[1], sizeof(local_str));
    }

    create_bmp_file = 0;
    mode = 0;
    bayer_pttern = 0;
    memset((UINT8 *)&local_str, 0, sizeof(local_str));
    if (argc >= 3) {
        if (strcmp(argv[2], "-b") == 0) {
            bayer_pttern = (UINT8) strtol(argv[3], NULL, 10);
            printf("\nbayer_pttern - %d\n", bayer_pttern);
            if (bayer_pttern > GRBG) {
                printf("Bad argument. View help (-h)\n");
                return 0;
            }
        } else if (strcmp(argv[2], "-m") == 0) {
            mode = (UINT8) strtol(argv[3], NULL, 10);
            printf("\nmode - %d\n", mode);
            if (mode > 1) {
                printf("Bad argument. View help (-h)\n");
                return 0;
            }

        } else if (strcmp(argv[2], "-c") == 0) {
//            mode = (UINT8) strtol(argv[3], NULL, 10);
            create_bmp_file = 1;

        } else {
            printf("Bad argument. View help (-h)\n");
            return 0;
        }
    }

    memset((UINT8 *)&local_str, 0, sizeof(local_str));
    if (argc > 4) { //printf("111\n");
        if (strcmp(argv[4], "-m") == 0) {
            mode = (UINT8) strtol(argv[5], NULL, 10);
            printf("\nmode - %d\n", mode);
            if (mode > 1) {
                printf("Bad argument. View help (-h)\n");
                return 0;
            }
        } else if (strcmp(argv[4], "-b") == 0) {
            bayer_pttern = (UINT8) strtol(argv[5], NULL, 10);
            printf("\nbayer_pttern - %d\n", bayer_pttern);
            if (bayer_pttern > GRBG) {
                printf("Bad argument. View help (-h)\n");
                return 0;
            }
        } else {
            printf("Bad argument. View help (-h)\n");
            return 0;
        }
    }

    //Open working files
    FILE *fi = fopen(img_in.name,"rb");
    if (fi == NULL) {
        printf ("fi - open file error\n");
        return 0;
    }

    img_t bmp_param;
    if (create_bmp_file) {

        memset((UINT8 *)&bmp_param, 0, sizeof(bmp_param));

        fseek(fi, 0L, SEEK_END);
        UINT32 sz = ftell(fi);
        fseek(fi, 0, SEEK_SET);
        UINT8 *raw_data = (UINT8*) calloc(sz, sizeof(UINT8));

        fread(raw_data, sizeof(UINT8), sz, fi);

        if (strcspn(img_in.name, "r") == 0) {
            printf ("can't file with extantion .raw\n");
            return -1;
        }
        strncpy(bmp_param.name, img_in.name, strcspn(img_in.name, "r"));
        strcat(bmp_param.name, "bmp");

        bmp_param.width = 2688;
        bmp_param.height = 1520;
        bmp_param.bit_count = 8;

        write_bmp_file (bmp_param, raw_data);

        free(raw_data);

        return 0;
    }


    FILE *fo = fopen(OUTPUT_FILE,"wb+");
    if (fo == NULL) {
        printf ("fo - open file error\n");
        return 0;
    }


    //Get param image from input file
    printf ("Input data:\n");
    image_param(fi, &img_in);

    //copy data header bmp
    UINT8 rbuf[2048];
    fseek(fi, 0, SEEK_SET);
    fread(rbuf, 1, img_in.data_offset, fi);
    fwrite(rbuf, 1, img_in.data_offset, fo);

    img_out = img_in;
    strncpy(img_out.name, OUTPUT_FILE, sizeof(local_str));
    img_out.data_offset = 54;
////    img_out.width = 128;
////    img_out.height = 128;
    img_out.planes = 1;
    img_out.bit_count = 24;
////    img_out.compression = ;
////    img_out.image_size = 16;
    img_out.colors_used = 0;

    //
    UINT8 **data_in = (UINT8**) calloc(img_in.height, sizeof(UINT8*));
    for (y=0; y < img_in.height; y++) {
        data_in[y] = (UINT8*) calloc(img_in.width, sizeof(UINT8));
        memset(data_in[y], 0, img_in.width);
    }

    //
    UINT8 **bufr = (UINT8**) calloc(img_out.height, sizeof(UINT8*));
    UINT8 **bufg = (UINT8**) calloc(img_out.height, sizeof(UINT8*));
    UINT8 **bufb = (UINT8**) calloc(img_out.height, sizeof(UINT8*));
    for (y=0; y < img_in.height; y++) {
        bufr[y] = (UINT8*) calloc(img_out.width, sizeof(UINT8));
        bufg[y] = (UINT8*) calloc(img_out.width, sizeof(UINT8));
        bufb[y] = (UINT8*) calloc(img_out.width, sizeof(UINT8));
        memset(bufr[y], 0, img_out.width);
        memset(bufg[y], 0, img_out.width);
        memset(bufb[y], 0, img_out.width);
    }

    printf("\n");
    printf("Read input image to working buffer:\n");
    fseek (fi, img_in.data_offset, 0);
    padding = align - (img_in.width & (align - 1));
    UINT32 tmp;
    for (y=0; y < img_in.height; y++) {
        fread(data_in[y], sizeof(UINT8), img_in.width, fi);
        if (padding < align) {
            fread(&tmp, sizeof(UINT8), padding, fi);
        }
    }



if (mode == 0) {
    debayer_bilinear(data_in, img_in.width, img_in.height, bayer_pttern, bufr, bufg, bufb);
} else if (mode == 1) {
    debayer_hq01(data_in, img_in.width, img_in.height, bayer_pttern, bufr, bufg, bufb);
}
//debayer_hq02(data_in, img_in.width, img_in.height, bayer_pttern, bufr, bufg, bufb);


//--- REV5-------------------------------------------------------

    printf ("\n");
    printf ("Output data(save result to file):\n");
    fseek (fo, img_out.data_offset, 0);
    img_out.image_size = 0;
    img_out.filesize = 0;
    padding = align - ((img_out.width * (img_out.bit_count/8)) & (align - 1));
    for (y = 0; y < img_out.height; y++) {
        for (x = 0; x < (img_out.width); x++) {
            //write pixel value
            fwrite(&bufb[y][x], sizeof(UINT8), 1, fo);
            fwrite(&bufg[y][x], sizeof(UINT8), 1, fo);
            fwrite(&bufr[y][x], sizeof(UINT8), 1, fo);

            img_out.image_size += (img_out.bit_count/8);
            img_out.filesize += (img_out.bit_count/8);
        }
        if (padding < align) {
            fwrite(&padding, sizeof(UINT8), padding, fo);
            img_out.filesize += padding;
            img_out.image_size += padding;
        }
    }

    img_out.filesize += img_out.data_offset;
    image_header_edit(fo, &img_out);
    printf("\n");


    fclose(fi);
    fclose(fo);

    for (y=0; y < img_in.height; y++) {
        free(data_in[y]);
    }
    free(data_in);


    for (y=0; y < img_out.height; y++) {
        free(bufr[y]);
        free(bufg[y]);
        free(bufb[y]);
    }
    free(bufr);
    free(bufg);
    free(bufb);

    return 0;
}



int image_param (FILE *fi, img_t *img_in)
{
    //Get param image from input file
    printf ("filename: %s\n",img_in->name);
    fseek (fi, 2, 0);
    fread(&(img_in->filesize), sizeof(img_in->filesize), 1, fi);
    printf ("\t filesize = %d;(0x%X)\n", (img_in->filesize), (img_in->filesize));

    fseek (fi, 10, 0);
    fread(&(img_in->data_offset), sizeof(img_in->data_offset), 1, fi);
    printf ("\t data_offset = %d\n", (img_in->data_offset));

    fseek (fi, 18, 0);
    fread(&(img_in->width), sizeof(img_in->width), 1, fi);
    printf ("\t width = %d\n", (img_in->width));

    fseek (fi, 22, 0);
    fread(&(img_in->height), sizeof(img_in->height), 1, fi);
    printf ("\t height = %d\n", (img_in->height));

    fseek (fi, 26, 0);
    fread(&(img_in->planes), sizeof(img_in->planes), 1, fi);
    printf ("\t planes = %d\n", (img_in->planes));

    fseek (fi, 28, 0);
    fread(&(img_in->bit_count), sizeof(img_in->bit_count), 1, fi);
    printf ("\t bit_count = %d\n", (img_in->bit_count));

    fseek (fi, 30, 0);
    fread(&(img_in->compression), sizeof(img_in->compression), 1, fi);
    printf ("\t compression = %d\n", (img_in->compression));

    fseek (fi, 34, 0);
    fread(&(img_in->image_size), sizeof(img_in->image_size), 1, fi);
    printf ("\t image_size = %d\n", (img_in->image_size));

    fseek (fi, 46, 0);
    fread(&(img_in->colors_used), sizeof(img_in->colors_used), 1, fi);
    printf ("\t colors_used = %d\n", (img_in->colors_used));

    return 0;
}

int image_header_edit (FILE *fi, img_t *img_in)
{
    //Get param image from input file
    printf ("filename: %s\n",img_in->name);
    fseek (fi, 2, 0);
    fwrite(&(img_in->filesize), sizeof(img_in->filesize), 1, fi);
    printf ("\t filesize = %d;(0x%X)\n", (img_in->filesize), (img_in->filesize));

    fseek (fi, 10, 0);
    fwrite(&(img_in->data_offset), sizeof(img_in->data_offset), 1, fi);
    printf ("\t data_offset = %d\n", (img_in->data_offset));

    fseek (fi, 18, 0);
    fwrite(&(img_in->width), sizeof(img_in->width), 1, fi);
    printf ("\t width = %d\n", (img_in->width));

    fseek (fi, 22, 0);
    fwrite(&(img_in->height), sizeof(img_in->height), 1, fi);
    printf ("\t height = %d\n", (img_in->height));

    fseek (fi, 26, 0);
    fwrite(&(img_in->planes), sizeof(img_in->planes), 1, fi);
    printf ("\t planes = %d\n", (img_in->planes));

    fseek (fi, 28, 0);
    fwrite(&(img_in->bit_count), sizeof(img_in->bit_count), 1, fi);
    printf ("\t bit_count = %d\n", (img_in->bit_count));

    fseek (fi, 30, 0);
    fwrite(&(img_in->compression), sizeof(img_in->compression), 1, fi);
    printf ("\t compression = %d\n", (img_in->compression));

    fseek (fi, 34, 0);
    fwrite(&(img_in->image_size), sizeof(img_in->image_size), 1, fi);
    printf ("\t image_size = %d\n", (img_in->image_size));

    fseek (fi, 46, 0);
    fwrite(&(img_in->colors_used), sizeof(img_in->colors_used), 1, fi);
    printf ("\t colors_used = %d\n", (img_in->colors_used));

    return 0;
}


int write_bmp_file (img_t img_in, UINT8 *img_data)
{
    UINT8 img_hdr [4096];
    memset(img_hdr, 0, sizeof(img_hdr));

    UINT8 zero = 0;
    UINT32 idx = 0;
    UINT32 filesize = 0;
    UINT32 padding = 0;

    //------------------------------
    //pepare data for header of BMP file:
    //------------------------------
    UINT16 BMP_signature = 0x4D42;
    UINT32 info_size = 40;//byte
    UINT32 data_offset = 54;//byte
    UINT32 info_width = img_in.width;
    UINT32 info_height = img_in.height;
    UINT32 info_planes = 1;
    UINT32 info_bit_count = img_in.bit_count;
    UINT32 info_compression = 0;
    UINT32 info_image_size = 0;
    UINT32 info_x_pixels_pre_meter = 0;
    UINT32 info_y_pixels_pre_meter = 0;
    UINT32 info_colors_used = 0;

    if (info_bit_count == 24) {
        info_colors_used = 0;
    } else {
        info_colors_used = 256;
    }

    //write color table
    UINT32 fr_xcnt = 0;
    UINT32 fr_ycnt = 0;
    UINT32 i = 0;
    if (info_bit_count == 8) {
        fr_xcnt = 0;
        for (i = 0; i < (info_colors_used * 4); i++) {
            if (fr_xcnt < 3) {
                img_hdr[(data_offset + i)] = (i >> 2) & 0xFF;
            } else {
                img_hdr[(data_offset + i)] = 0;
            }

            if (fr_xcnt == 3) fr_xcnt = 0;
            else fr_xcnt++;
        }

        data_offset += (info_colors_used * 4);
    }

    //------------------------------
    //write data to BMP file:
    //------------------------------
    FILE *fd = fopen(img_in.name,"wb+");
    if (fd == 0) {
        printf("\t Error: filename - bad value !");
        return - 1;
    }

    if (fseek(fd, data_offset, SEEK_SET) < 0) {
        printf("\t Error: seek !");
        return -1;
    }

    idx = 0;
    info_image_size = 0;
    filesize = 0;
    padding = align - ((info_width * (info_bit_count/8)) & (align - 1));
    for (fr_ycnt = 0; fr_ycnt < info_height; fr_ycnt++) {
        for (fr_xcnt = 0; fr_xcnt < info_width; fr_xcnt++) {
            //write pixel value
            if (info_bit_count == 24) {
                fwrite(&img_data[idx++], 1, 1, fd);
                fwrite(&img_data[idx++], 1, 1, fd);
                fwrite(&img_data[idx++], 1, 1, fd);
            } else {
                fwrite(&img_data[idx++], 1, 1, fd);
            }
            info_image_size += (info_bit_count/8);
            filesize += (info_bit_count/8);
        }
        if (padding < align) {
            for (i = 0; i < padding; i++) {
                fwrite(&zero, 1, 1, fd);
            }
            info_image_size += padding;
            filesize += padding;
        }
    }

    filesize += data_offset;

    //------------------------------
    //write header BMP:
    //------------------------------
    if (fseek(fd, 0, SEEK_SET) < 0) {
        printf("\t Error: seek !");
        return -1;
    }

    for (i = 0; i < 2; i++) img_hdr[0  + i] = (BMP_signature >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[2  + i] = (filesize >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[10 + i] = (data_offset >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[14 + i] = (info_size >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[18 + i] = (info_width >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[22 + i] = (info_height >> (8*i)) & 0xFF;
    for (i = 0; i < 2; i++) img_hdr[26 + i] = (info_planes >> (8*i)) & 0xFF;
    for (i = 0; i < 2; i++) img_hdr[28 + i] = (info_bit_count >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[30 + i] = (info_compression >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[34 + i] = (info_image_size >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[38 + i] = (info_x_pixels_pre_meter >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[42 + i] = (info_y_pixels_pre_meter >> (8*i)) & 0xFF;
    for (i = 0; i < 4; i++) img_hdr[46 + i] = (info_colors_used >> (8*i)) & 0xFF;

    printf("");
    printf("WriteBMP: %s\n                    ", img_in.name           );
    printf("\tFileSize: \t\t\t%04d\n          ", filesize               );
    printf("\tDataOffset: \t\t\t%04d\n        ", data_offset            );
    printf("\tInfoHeaderSize: \t\t\t%04d\n    ", info_size              );
    printf("\tWidth: \t\t\t%04d\n             ", info_width             );
    printf("\tHeight: \t\t\t%04d\n            ", info_height            );
    printf("\tPlanes: \t\t\t%04d\n            ", info_planes            );
    printf("\tBitCount: \t\t\t%04d\n          ", info_bit_count         );
    printf("\tCompresion: \t\t\t%04d\n        ", info_compression       );
    printf("\tImageSize: \t\t\t%04d\n         ", info_image_size        );
    printf("\tXpixelPreM: \t\t\t%04d\n        ", info_x_pixels_pre_meter);
    printf("\tYpixelPreM: \t\t\t%04d\n        ", info_y_pixels_pre_meter);
    printf("\tColor: \t\t\t%04d\n             ", info_colors_used       );

    fwrite(img_hdr, data_offset, 1, fd);

    fclose(fd);

    return 0;
}


void debayer_bilinear(UINT8 **din, UINT32 din_width, UINT32 din_height, UINT8 bayer_pttern
                    , UINT8 **r_plane, UINT8 **g_plane, UINT8 **b_plane) {
    UINT32 y;
    UINT32 x;

    UINT8 b1379 = 0;
    UINT8 b2846 = 0;
    UINT8 b46 = 0;
    UINT8 b28 = 0;
    UINT8 b5 = 0;

    printf ("\n\t ########### \n");
    printf ("\n\t %s.\n", __func__);
    printf ("\n\t ########### \n");

    for (y = 0; y < (din_height - 3); y++) {
        for (x = 0; x < (din_width - 3); x++) {
                //X 0 X
                //0 0 0
                //X 0 X
                b1379 = (din[y][x] + din[y][x+2] + din[y+2][x] + din[y+2][x+2]) / 4;

                //0 X 0
                //X 0 X
                //0 X 0
                b2846 = (din[y][x+1] + din[y+1][x] + din[y+1][x+2] + din[y+2][x+1]) / 4;

                //0 0 0
                //X 0 X
                //0 0 0
                b46 = (din[y+1][x] + din[y+1][x+2]) / 2;

                //0 X 0
                //0 0 0
                //0 X 0
                b28 = (din[y][x+1] + din[y+2][x+1]) / 2;

                //0 0 0
                //0 X 0
                //0 0 0
                b5 = (din[y+1][x+1]);

                if        ((!(y & 0x01)) && (!(x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR
                            //[B G B]G B
                            //[G R G]R G
                            //[B G B]G B
                            // G R G R G
                            r_plane[y+1][x+1] = b5;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b1379;
                        }
                        else if (bayer_pttern == RGGB) {
                            //RGGB
                            //[R G R]G R
                            //[G B G]B G
                            //[R G R]G R
                            // G B G B G
                            r_plane[y+1][x+1] = b1379;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b5;

                        } else if (bayer_pttern == GBRG) {  //testimage_2.bmp
                            //GBRG
                            //[G B G]B G
                            //[R G R]G R
                            //[G B G]B G
                            // R G R G R
                            r_plane[y+1][x+1] = b46;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b28;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG
                            //[G R G]R G
                            //[B G B]G B
                            //[G R G]R G
                            // B G B G B
                            r_plane[y+1][x+1] = b28;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b46;

                        }

                } else if ((!(y & 0x01)) && ( (x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR
                            // B[G B G]B
                            // G[R G R]G
                            // B[G B G]B
                            // G R G R G
                            r_plane[y+1][x+1] = b46;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b28;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB
                            // R[G R G]R
                            // G[B G B]G
                            // R[G R G]R
                            // G B G B G
                            r_plane[y+1][x+1] = b28;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b46;

                        } else if (bayer_pttern == GBRG) { //testimage_2.bmp
                            //GBRG
                            // G[B G B]G
                            // R[G R G]R
                            // G[B G B]G
                            // R G R G R
                            r_plane[y+1][x+1] = b5;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b1379;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG
                            // G[R G R]G
                            // B[G B G]B
                            // G[R G R]G
                            // B G B G B
                            r_plane[y+1][x+1] = b1379;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b5;

                        }

                } else if (( (y & 0x01)) && (!(x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR
                            // B G B G B
                            //[G R G]R G
                            //[B G B]G B
                            //[G R G]R G
                            r_plane[y+1][x+1] = b28;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b46;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB
                            // R G R G R
                            //[G B G]B G
                            //[R G R]G R
                            //[G B G]B G
                            r_plane[y+1][x+1] = b46;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b28;

                        } else if (bayer_pttern == GBRG) { //testimage_2.bmp
                            //GBRG
                            // G B G B G
                            //[R G R]G R
                            //[G B G]B G
                            //[R G R]G R
                            r_plane[y+1][x+1] = b1379;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b5;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG
                            // G R G R G
                            //[B G B]G B
                            //[G R G]R G
                            //[B G B]G B
                            r_plane[y+1][x+1] = b5;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b1379;

                        }

                } else if (( (y & 0x01)) && ( (x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR
                            // B G B G B
                            // G[R G R]G
                            // B[G B G]B
                            // G[R G R]G
                            r_plane[y+1][x+1] = b1379;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b5;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB
                            // R G R G R
                            // G[B G B]G
                            // R[G R G]R
                            // G[B G B]G
                            r_plane[y+1][x+1] = b5;
                            g_plane[y+1][x+1] = b2846;
                            b_plane[y+1][x+1] = b1379;

                        } else if (bayer_pttern == GBRG) { //testimage_2.bmp
                            //GBRG
                            // G B G B G
                            // R[G R G]R
                            // G[B G B]G
                            // R[G R G]R
                            r_plane[y+1][x+1] = b28;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b46;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG
                            // G R G R G
                            // B[G B G]B
                            // G[R G R]G
                            // B[G B G]B
                            r_plane[y+1][x+1] = b46;
                            g_plane[y+1][x+1] = b5;
                            b_plane[y+1][x+1] = b28;

                        }
                }
        }//for x
    }//for y

}


void debayer_hq01(UINT8 **din, UINT32 din_width, UINT32 din_height, UINT8 bayer_pttern
                    , UINT8 **r_plane, UINT8 **g_plane, UINT8 **b_plane) {
    UINT32 y;
    UINT32 x;


    float u38DIN_BCDEF_ = 0;
    UINT8 u38DIN_BCDEF = 0;

    float u3DN_BCDEF_79_HJ_ = 0;
    UINT8 u3DN_BCDEF_79_HJ = 0;

    float u38DIN_BDF_789_HIJ_ = 0;
    UINT8 u38DIN_BDF_789_HIJ = 0;

    float u3DN_BDF_79_HJ_ = 0;
    UINT8 u3DN_BDF_79_HJ = 0;

    UINT8 uD = 0;

    printf ("\n\t ########### \n");
    printf ("\n\t %s.\n", __func__);
    printf ("\n\t ########### \n");

    for (y = 0; y < (din_height - 5); y++) {
        for (x = 0; x < (din_width - 5); x++) {
                //0 0 X 0 0
                //0 0 X 0 0
                //X X X X X
                //0 0 X 0 0
                //0 0 X 0 0
                u38DIN_BCDEF_ = (
                               (float) (din[y+0][x+2] * (-1))
                             + (float) (din[y+1][x+2] * ( 2))

                             + (float) (din[y+2][x+2] * ( 4))

                             + (float) (din[y+3][x+2] * ( 2))
                             + (float) (din[y+4][x+2] * (-1))

                             + (float) (din[y+2][x+0] * (-1))
                             + (float) (din[y+2][x+1] * ( 2))

                             + (float) (din[y+2][x+3] * ( 2))
                             + (float) (din[y+2][x+4] * (-1))
                            ) / 8;
                if (u38DIN_BCDEF_ > 255) {
                    u38DIN_BCDEF = 255;
                } else if (u38DIN_BCDEF_ < 0) {
                    u38DIN_BCDEF = 0;
                } else {
                    u38DIN_BCDEF = (UINT8) u38DIN_BCDEF_;
                }

                //0 0 X 0 0
                //0 X X X 0
                //X 0 X 0 X
                //0 X X X 0
                //0 0 X 0 0
                u38DIN_BDF_789_HIJ_ = (
                               (float) (din[y+0][x+2] * (-1))

                             + (float) (din[y+1][x+1] * (-1))
                             + (float) (din[y+1][x+2] * ( 4))
                             + (float) (din[y+1][x+3] * (-1))

                             + (float) (din[y+2][x+0] * (0.5))
                             + (float) (din[y+2][x+2] * ( 5))
                             + (float) (din[y+2][x+4] * (0.5))

                             + (float) (din[y+3][x+1] * (-1))
                             + (float) (din[y+3][x+2] * ( 4))
                             + (float) (din[y+3][x+3] * (-1))

                             + (float) (din[y+4][x+2] * (-1))
                            ) / 8;
                if (u38DIN_BDF_789_HIJ_ > 255) {
                    u38DIN_BDF_789_HIJ = 255;
                } else if (u38DIN_BDF_789_HIJ_ < 0) {
                    u38DIN_BDF_789_HIJ = 0;
                } else {
                    u38DIN_BDF_789_HIJ = (UINT8) u38DIN_BDF_789_HIJ_;
                }


                //0 0 X 0 0
                //0 X 0 X 0
                //X X X X X
                //0 X 0 X 0
                //0 0 X 0 0
                u3DN_BCDEF_79_HJ_ = (
                               (float) (din[y+0][x+2] * (0.5))

                             + (float) (din[y+1][x+1] * (-1))
                             + (float) (din[y+1][x+3] * (-1))

                             + (float) (din[y+2][x+0] * (-1))
                             + (float) (din[y+2][x+1] * ( 4))
                             + (float) (din[y+2][x+2] * ( 5))
                             + (float) (din[y+2][x+3] * ( 4))
                             + (float) (din[y+2][x+4] * (-1))

                             + (float) (din[y+3][x+1] * (-1))
                             + (float) (din[y+3][x+2] * (-1))

                             + (float) (din[y+4][x+2] * (0.5))
                            ) / 8;
                if (u3DN_BCDEF_79_HJ_ > 255) {
                    u3DN_BCDEF_79_HJ = 255;
                } else if (u3DN_BCDEF_79_HJ_ < 0) {
                    u3DN_BCDEF_79_HJ = 0;
                } else {
                    u3DN_BCDEF_79_HJ = (UINT8) u3DN_BCDEF_79_HJ_;
                }


                //0 0 X 0 0
                //0 X 0 X 0
                //X 0 X 0 X
                //0 X 0 X 0
                //0 0 X 0 0
                u3DN_BDF_79_HJ_ = (
                               (float) (din[y+0][x+2] * (-1.5))

                             + (float) (din[y+1][x+1] * ( 2))
                             + (float) (din[y+1][x+3] * ( 2))

                             + (float) (din[y+2][x+0] * (-1.5))
                             + (float) (din[y+2][x+2] * ( 6))
                             + (float) (din[y+2][x+4] * (-1.5))

                             + (float) (din[y+3][x+1] * ( 2))
                             + (float) (din[y+3][x+3] * ( 2))

                             + (float) (din[y+4][x+2] * (-1.5))
                            ) / 8;
                if (u3DN_BDF_79_HJ_ > 255) {
                    u3DN_BDF_79_HJ = 255;
                } else if (u3DN_BDF_79_HJ_ < 0) {
                    u3DN_BDF_79_HJ = 0;
                } else {
                    u3DN_BDF_79_HJ = (UINT8) u3DN_BDF_79_HJ_;
                }


                //0 0 0 0 0
                //0 0 0 0 0
                //0 0 X 0 0
                //0 0 0 0 0
                //0 0 0 0 0
                uD = din[y+2][x+2];

                if        ((!(y & 0x01)) && (!(x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR   (B row, B column)
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            // G R G R G R G R G
                            r_plane[y+2][x+2] = u3DN_BDF_79_HJ;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = uD;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB   (R row, R column)
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            // G B G B G B G B G
                            r_plane[y+2][x+2] = uD;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = u3DN_BDF_79_HJ;

                        } else if (bayer_pttern == GBRG) {  //testimage_2.bmp
                            //GBRG   (B row, R column)
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            // R G R G R G R G R
                            r_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG   (R row, B column)
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            // B G B G B G B G B
                            r_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;
                        }


                } else if ((!(y & 0x01)) && ( (x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR   (B row, R column)
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G R G R G R G R G
                            r_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB   (R row, B column)
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G B G B G B G B G
                            r_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;

                        } else if (bayer_pttern == GBRG) {
                            //GBRG   (B row, B column)
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R G R G R G R G R
                            r_plane[y+2][x+2] = u3DN_BDF_79_HJ;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = uD;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG   (R row, R column)
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B G B G B G B G B
                            r_plane[y+2][x+2] = uD;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = u3DN_BDF_79_HJ;
                        }

                } else if (( (y & 0x01)) && (!(x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR   (R row, B column)
                            // B G B G B G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            r_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB   (B row, R column)
                            // R G R G R G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            r_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;

                        } else if (bayer_pttern == GBRG) {
                            //GBRG   (R row, R column)
                            // G B G B G B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            r_plane[y+2][x+2] = uD;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = u3DN_BDF_79_HJ;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG   (B row, B column)
                            // G R G R G R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            //[G R G R G]R G R G
                            //[B G B G B]G B G B
                            r_plane[y+2][x+2] = u3DN_BDF_79_HJ;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = uD;
                        }

                } else if (( (y & 0x01)) && ( (x & 0x01))) {

                        if (bayer_pttern == BGGR) {
                            //BGGR   (R row, R column)
                            // B G B G B G B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            r_plane[y+2][x+2] = uD;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = u3DN_BDF_79_HJ;

                        } else if (bayer_pttern == RGGB) {
                            //RGGB   (B row, B column)
                            // R G R G R G R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            r_plane[y+2][x+2] = u3DN_BDF_79_HJ;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = uD;

                        } else if (bayer_pttern == GBRG) {
                            //GBRG   (R row, B column)
                            // G B G B G B G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            r_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;

                        } else if (bayer_pttern == GRBG) {
                            //GRBG   (B row, R column)
                            // G R G R G R G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            // G[R G R G R]G R G
                            // B[G B G B G]B G B
                            r_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;
                        }
                }
        }//for x
    }//for y
}



void debayer_hq02(UINT8 **din, UINT32 din_width, UINT32 din_height, UINT8 bayer_pttern
                    , UINT8 **r_plane, UINT8 **g_plane, UINT8 **b_plane) {
    UINT32 y;
    UINT32 x;


    UINT8 u38DIN_BCDEF_h0 = 0;
    UINT8 u38DIN_BCDEF_h1 = 0;
    UINT8 u38DIN_BCDEF_h = 0;
    UINT8 u38DIN_BCDEF_v0 = 0;
    UINT8 u38DIN_BCDEF_v1 = 0;
    UINT8 u38DIN_BCDEF_v = 0;
    UINT8 u38DIN_BCDEF = 0;

    float u3DN_BCDEF_79_HJ_ = 0;
    UINT8 u3DN_BCDEF_79_HJ = 0;

    float u38DIN_BDF_789_HIJ_ = 0;
    UINT8 u38DIN_BDF_789_HIJ = 0;

    float u3DN_BDF_79_HJ_ = 0;
    UINT8 u3DN_BDF_79_HJ = 0;

    UINT8 uD = 0;

    for (y = 0; y < (din_height - 5); y++) {
        for (x = 0; x < (din_width - 5); x++) {
                //0 0 X 0 0
                //0 0 X 0 0
                //X X X X X
                //0 0 X 0 0
                //0 0 X 0 0
                u38DIN_BCDEF_h0 = (din[y+2][x+0] + din[y+2][x+4]) /2;
                u38DIN_BCDEF_h1 = din[y+2][x+2];
                if (u38DIN_BCDEF_h0 > u38DIN_BCDEF_h1) {
                    u38DIN_BCDEF_h = u38DIN_BCDEF_h0 - u38DIN_BCDEF_h1;
                } else {
                    u38DIN_BCDEF_h = u38DIN_BCDEF_h1 - u38DIN_BCDEF_h0;
                }

                u38DIN_BCDEF_v0 = (din[y+0][x+2] + din[y+4][x+2]) /2;
                u38DIN_BCDEF_v1 = din[y+2][x+2];
                if (u38DIN_BCDEF_v0 > u38DIN_BCDEF_v1) {
                    u38DIN_BCDEF_v = u38DIN_BCDEF_v0 - u38DIN_BCDEF_v1;
                } else {
                    u38DIN_BCDEF_v = u38DIN_BCDEF_v1 - u38DIN_BCDEF_v0;
                }

                if (u38DIN_BCDEF_h == u38DIN_BCDEF_h) {
                    u38DIN_BCDEF = (din[y+1][x+2] + din[y+3][x+2] + din[y+2][x+1] + din[y+2][x+3]) / 4;

                } else if (u38DIN_BCDEF_h > u38DIN_BCDEF_h) {
                    u38DIN_BCDEF = (din[y+2][x+1] + din[y+2][x+3]) / 2;

                } else {
                    u38DIN_BCDEF = (din[y+1][x+2] + din[y+3][x+2]) / 2;
                }

//                u38DIN_BCDEF_ = (
//                               (float) (din[y+0][x+2] * (-1))
//                             + (float) (din[y+1][x+2] * ( 2))
//
//                             + (float) (din[y+2][x+2] * ( 4))
//
//                             + (float) (din[y+3][x+2] * ( 2))
//                             + (float) (din[y+4][x+2] * (-1))
//
//                             + (float) (din[y+2][x+0] * (-1))
//                             + (float) (din[y+2][x+1] * ( 2))
//
//                             + (float) (din[y+2][x+3] * ( 2))
//                             + (float) (din[y+2][x+4] * (-1))
//                            ) / 8;
//                if (u38DIN_BCDEF_ > 255) {
//                    u38DIN_BCDEF = 255;
//                } else if (u38DIN_BCDEF_ < 0) {
//                    u38DIN_BCDEF = 0;
//                } else {
//                    u38DIN_BCDEF = (UINT8) u38DIN_BCDEF_;
//                }

                //0 0 X 0 0
                //0 X X X 0
                //X 0 X 0 X
                //0 X X X 0
                //0 0 X 0 0
                u38DIN_BDF_789_HIJ_ = (
                               (float) (din[y+0][x+2] * (-1))

                             + (float) (din[y+1][x+1] * (-1))
                             + (float) (din[y+1][x+2] * ( 4))
                             + (float) (din[y+1][x+3] * (-1))

                             + (float) (din[y+2][x+0] * (0.5))
                             + (float) (din[y+2][x+2] * ( 5))
                             + (float) (din[y+2][x+4] * (0.5))

                             + (float) (din[y+3][x+1] * (-1))
                             + (float) (din[y+3][x+2] * ( 4))
                             + (float) (din[y+3][x+3] * (-1))

                             + (float) (din[y+4][x+2] * (-1))
                            ) / 8;
                if (u38DIN_BDF_789_HIJ_ > 255) {
                    u38DIN_BDF_789_HIJ = 255;
                } else if (u38DIN_BDF_789_HIJ_ < 0) {
                    u38DIN_BDF_789_HIJ = 0;
                } else {
                    u38DIN_BDF_789_HIJ = (UINT8) u38DIN_BDF_789_HIJ_;
                }


                //0 0 X 0 0
                //0 X 0 X 0
                //X X X X X
                //0 X 0 X 0
                //0 0 X 0 0
                u3DN_BCDEF_79_HJ_ = (
                               (float) (din[y+0][x+2] * (0.5))

                             + (float) (din[y+1][x+1] * (-1))
                             + (float) (din[y+1][x+3] * (-1))

                             + (float) (din[y+2][x+0] * (-1))
                             + (float) (din[y+2][x+1] * ( 4))
                             + (float) (din[y+2][x+2] * ( 5))
                             + (float) (din[y+2][x+3] * ( 4))
                             + (float) (din[y+2][x+4] * (-1))

                             + (float) (din[y+3][x+1] * (-1))
                             + (float) (din[y+3][x+2] * (-1))

                             + (float) (din[y+4][x+2] * (0.5))
                            ) / 8;
                if (u3DN_BCDEF_79_HJ_ > 255) {
                    u3DN_BCDEF_79_HJ = 255;
                } else if (u3DN_BCDEF_79_HJ_ < 0) {
                    u3DN_BCDEF_79_HJ = 0;
                } else {
                    u3DN_BCDEF_79_HJ = (UINT8) u3DN_BCDEF_79_HJ_;
                }


                //0 0 X 0 0
                //0 X 0 X 0
                //X 0 X 0 X
                //0 X 0 X 0
                //0 0 X 0 0
                u3DN_BDF_79_HJ_ = (
                               (float) (din[y+0][x+2] * (-1.5))

                             + (float) (din[y+1][x+1] * ( 2))
                             + (float) (din[y+1][x+3] * ( 2))

                             + (float) (din[y+2][x+0] * (-1.5))
                             + (float) (din[y+2][x+2] * ( 6))
                             + (float) (din[y+2][x+4] * (-1.5))

                             + (float) (din[y+3][x+1] * ( 2))
                             + (float) (din[y+3][x+3] * ( 2))

                             + (float) (din[y+4][x+2] * (-1.5))
                            ) / 8;
                if (u3DN_BDF_79_HJ_ > 255) {
                    u3DN_BDF_79_HJ = 255;
                } else if (u3DN_BDF_79_HJ_ < 0) {
                    u3DN_BDF_79_HJ = 0;
                } else {
                    u3DN_BDF_79_HJ = (UINT8) u3DN_BDF_79_HJ_;
                }


                //0 0 0 0 0
                //0 0 0 0 0
                //0 0 X 0 0
                //0 0 0 0 0
                //0 0 0 0 0
                uD = din[y+2][x+2];

                if        ((!(y & 0x01)) && (!(x & 0x01))) {

                        if (bayer_pttern == GBRG) {  //testimage_2.bmp
                            //GBRG   (B row, R column)
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            // R G R G R G R G R
                            r_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;

                        }


                } else if ((!(y & 0x01)) && ( (x & 0x01))) {

                        if (bayer_pttern == GBRG) {
                            //GBRG   (B row, B column)
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R G R G R G R G R
                            r_plane[y+2][x+2] = u3DN_BDF_79_HJ;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = uD;

                        }

                } else if (( (y & 0x01)) && (!(x & 0x01))) {

                        if (bayer_pttern == GBRG) {
                            //GBRG   (R row, R column)
                            // G B G B G B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            //[G B G B G]B G B G
                            //[R G R G R]G R G R
                            r_plane[y+2][x+2] = uD;
                            g_plane[y+2][x+2] = u38DIN_BCDEF;
                            b_plane[y+2][x+2] = u3DN_BDF_79_HJ;

                        }

                } else if (( (y & 0x01)) && ( (x & 0x01))) {
                        if (bayer_pttern == GBRG) {
                            //GRBG   (R row, B column)
                            // G B G B G B G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            // G[B G B G B]G B G
                            // R[G R G R G]R G R
                            r_plane[y+2][x+2] = u3DN_BCDEF_79_HJ;
                            g_plane[y+2][x+2] = uD;
                            b_plane[y+2][x+2] = u38DIN_BDF_789_HIJ;

                        }
                }
        }//for x
    }//for y
}







//    printf("111\n");
//    for (y = 0; y < (img_in.height); y++) {
//        for (x = 0; x < (img_in.width); x++) {
//            data_in[y][x] = x+20;
//        }
//    }
//
//    printf("222\n");
//--- Rotate - REV5 -------------------------------------------------------
//    UINT8 b1379 = 0;
//    UINT8 b2846 = 0;
//    UINT8 b46 = 0;
//    UINT8 b28 = 0;
//    UINT8 b5 = 0;


//    for (y = 0; y < (img_in.height); y++) {
//        for (x = 0; x < (img_in.width); x++) {
//            if (y==0) {
//            bufr[y][x] = 0;
//            bufg[y][x] = 0xFF;
//            bufb[y][x] = 0;
//            } else
//                bufg[y][x] = data_in[y][x];
//        }
//    }

//    for (y = 0; y < (img_in.height); y++) {
//        for (x = 0; x < (img_in.width); x++) {
//            if ((x==0) || (x==(img_in.width-1))) {
//            bufr[y][x] = 0;
//            bufg[y][x] = 0xFF;
//            bufb[y][x] = 0;
//            } else
//                bufg[y][x] = data_in[y][x];
//        }
//    }

//    for (y = 0; y < (img_in.height); y++) {
//        for (x = 0; x < (img_in.width); x++) {
//            if ((x < (img_in.width/2))) {
//            bufr[y][x] = 0;
//            bufg[y][x] = 0xFF;
//            bufb[y][x] = 0;
//            } else {
//            bufr[y][x] = 0;
//            bufg[y][x] = 0;
//            bufb[y][x] = 0xFF;
//            }
//        }
//    }


//data_in[0+0][0+2] = 1;//255;
//data_in[0+1][0+2] = 2;//255;
//data_in[0+2][0+2] = 3;//255;
//data_in[0+3][0+2] = 4;//255;
//data_in[0+4][0+2] = 5;//255;
//
//data_in[0+2][0+0] = 1;//255;
//data_in[0+2][0+1] = 2;//255;
//data_in[0+2][0+2] = 3;//255;
//data_in[0+2][0+3] = 4;//255;
//data_in[0+2][0+4] = 5;//255;
//
//
//printf("data_in[y+0][x+2] = %d\n", (data_in[0+0][0+2]));
//printf("data_in[y+1][x+2] = %d\n", (data_in[0+1][0+2]));
//printf("data_in[y+2][x+2] = %d\n", (data_in[0+2][0+2]));
//printf("data_in[y+3][x+2] = %d\n", (data_in[0+3][0+2]));
//printf("data_in[y+4][x+2] = %d\n", (data_in[0+4][0+2]));
//printf("\n");
//printf("data_in[y+2][x+0] = %d\n", (data_in[0+2][0+0]));
//printf("data_in[y+2][x+1] = %d\n", (data_in[0+2][0+1]));
//printf("data_in[y+2][x+3] = %d\n", (data_in[0+2][0+3]));
//printf("data_in[y+2][x+4] = %d\n", (data_in[0+2][0+4]));
//
//UINT8 u38DIN_BCDEF = 0;
//float u38DIN_BCDEF_ = (
//                       (float) (data_in[0+0][0+2] * (-1))
//                     + (float) (data_in[0+1][0+2] * ( 2))
//
//                     + (float) (data_in[0+2][0+2] * ( 4))
//
//                     + (float) (data_in[0+3][0+2] * ( 2))
//                     + (float) (data_in[0+4][0+2] * (-1))
//
//                     + (float) (data_in[0+2][0+0] * (-1))
//                     + (float) (data_in[0+2][0+1] * ( 2))
//
//                     + (float) (data_in[0+2][0+3] * ( 2))
//                     + (float) (data_in[0+2][0+4] * (-1))
//                     ) / 8;
//if (u38DIN_BCDEF_ > 255) {
//    u38DIN_BCDEF = 255;
//} else if (u38DIN_BCDEF_ < 0) {
//    u38DIN_BCDEF = 0;
//} else {
//    u38DIN_BCDEF = (UINT8) u38DIN_BCDEF_;
//}
//printf("u38DIN_BCDEF: %d\n", u38DIN_BCDEF);
//
//
//
//data_in[0+0][0+2] = 255;//1;//
//                        //
//data_in[0+1][0+1] = 255;//2;//
//data_in[0+1][0+3] = 255;//3;//
//                        //
//data_in[0+2][0+0] = 255;//4;//
//data_in[0+2][0+2] = 255;//5;//
//data_in[0+2][0+4] = 255;//4;//
//                        //
//data_in[0+3][0+1] = 255;//3;//
//data_in[0+3][0+3] = 255;//2;//
//                        //
//data_in[0+4][0+2] = 255;//1;//
//
//
//printf("data_in[0+0][0+2]: %d\n", data_in[0+0][0+2]);
//
//printf("data_in[0+1][0+1]: %d\n", data_in[0+1][0+1]);
//printf("data_in[0+1][0+3]: %d\n", data_in[0+1][0+3]);
//
//printf("data_in[0+2][0+0]: %d\n", data_in[0+2][0+0]);
//printf("data_in[0+2][0+2]: %d\n", data_in[0+2][0+2]);
//printf("data_in[0+2][0+4]: %d\n", data_in[0+2][0+4]);
//
//printf("data_in[0+3][0+1]: %d\n", data_in[0+3][0+1]);
//printf("data_in[0+3][0+3]: %d\n", data_in[0+3][0+3]);
//
//printf("data_in[0+4][0+2]: %d\n", data_in[0+4][0+2]);
//
//
//UINT8 u3DN_BDF_79_HJ = 0;
//float f0 = (float) (data_in[0+0][0+2] * (-1.5));
//float f1 = (float) (data_in[0+1][0+1] * ( 2));
//float f2 = (float) (data_in[0+1][0+3] * ( 2));
//float f3 = (float) (data_in[0+2][0+0] * (-1.5));
//float f4 = (float) (data_in[0+2][0+2] * (6));
//float f5 = (float) (data_in[0+2][0+4] * (-1.5));
//float f6 = (float) (data_in[0+3][0+1] * ( 2));
//float f7 = (float) (data_in[0+3][0+3] * ( 2));
//float f8 = (float) (data_in[0+4][0+2] * (-1.5));
//
//printf("f0: %f\n", f0);
//printf("f1: %f\n", f1);
//printf("f2: %f\n", f2);
//printf("f3: %f\n", f3);
//printf("f4: %f\n", f4);
//printf("f5: %f\n", f5);
//printf("f6: %f\n", f6);
//printf("f7: %f\n", f7);
//printf("f8: %f\n", f8);
//
//float fsum = f0 + f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8;
//printf("sum: %f\n", fsum);
//
//float u3DN_BDF_79_HJ_ = (
//                       (float) (data_in[0+0][0+2] * (-1.5))
//
//                     + (float) (data_in[0+1][0+1] * ( 2))
//                     + (float) (data_in[0+1][0+3] * ( 2))
//
//                     + (float) (data_in[0+2][0+0] * (-1.5))
//                     + (float) (data_in[0+2][0+2] * (6))
//                     + (float) (data_in[0+2][0+4] * (-1.5))
//
//                     + (float) (data_in[0+3][0+1] * ( 2))
//                     + (float) (data_in[0+3][0+3] * ( 2))
//
//                     + (float) (data_in[0+4][0+2] * (-1.5))
//                     ) / 8;
//if (u3DN_BDF_79_HJ_ > 255) {
//    u3DN_BDF_79_HJ = 255;
//} else if (u3DN_BDF_79_HJ_ < 0) {
//    u3DN_BDF_79_HJ = 0;
//} else {
//    u3DN_BDF_79_HJ = (UINT8) u3DN_BDF_79_HJ_;
//}
//p rintf("u3DN_BDF_79_HJ: %d\n", u3DN_BDF_79_HJ);