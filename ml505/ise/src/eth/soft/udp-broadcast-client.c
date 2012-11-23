 /* udp-broadcast-client.c
  * udp datagram client
  * Get datagram stock market quotes from UDP broadcast:
  * see below the step by step explanation
  */
  #include <stdio.h>
  #include <unistd.h>
  #include <stdlib.h>
  #include <errno.h>
  #include <string.h>
  #include <time.h>
  #include <signal.h>
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>

  #ifndef TRUE
  #define TRUE 1
  #define FALSE 0
  #endif

  extern int mkaddr(
                    void *addr,
                    int *addrlen,
                    char *str_addr,
                    char *protocol);

/*
 * This function reports the error and
 * exits back to the shell:
 */
 static void
 displayError(const char *on_what) {
     fputs(strerror(errno),stderr);
     fputs(": ",stderr);
     fputs(on_what,stderr);
     fputc('\n',stderr);
     exit(1);
}

 int
 main(int argc,char **argv) {
     int z;
     int x;
     struct sockaddr_in adr;  /* AF_INET */
     int len_inet;            /* length */
     int s;                   /* Socket */
     char dgram[2048];         /* Recv buffer */
     static int so_reuseaddr = TRUE;
     static char
     *bc_addr = "10.1.7.232:3000";

     unsigned short *vpkt;
     unsigned char err = 0;
     unsigned char vrow_chk = 0;
     unsigned short vrow_clc = 0;
     unsigned char vfr_chk = 0;
     unsigned short vfr_clc = 0;
     unsigned short rcv_cnt = 0;
     unsigned short err_cnt = 0;

    /*
     * Use a server address from the command
     * line, if one has been provided.
     * Otherwise, this program will default
     * to using the arbitrary address
     * 127.0.0.:
     */
     if ( argc > 1 )
     /* Broadcast address: */
        bc_addr = argv[1];

    /*
     * Create a UDP socket to use:
     */
     s = socket(AF_INET,SOCK_DGRAM,0);
     if ( s == -1 )
        displayError("socket()");

    /*
     * Form the broadcast address:
     */
     len_inet = sizeof adr;

     z = mkaddr(&adr,
                &len_inet,
                bc_addr,
                "udp");

     if ( z == -1 )
        displayError("Bad broadcast address");

    /*
     * Allow multiple listeners on the
     * broadcast address:
     */
     z = setsockopt(s,
                    SOL_SOCKET,
                    SO_REUSEADDR,
                    &so_reuseaddr,
                    sizeof so_reuseaddr);

     if ( z == -1 )
        displayError("setsockopt(SO_REUSEADDR)");

    /*
     * Bind our socket to the broadcast address:
     */
     z = bind(s,
             (struct sockaddr *)&adr,
             len_inet);

     if ( z == -1 )
        displayError("bind(2)");

	 printf("Testing......\n");
	 
     while (1) {
        /*
         * Wait for a broadcast message:
         */
         z = recvfrom(s,      /* Socket */
                      dgram,  /* Receiving buffer */
                      sizeof dgram,/* Max rcv buf size */
                      0,      /* Flags: no options */
                      (struct sockaddr *)&adr, /* Addr */
                      &x);    /* Addr len, in & out */

         if ( z < 0 )
           printf("recvfrom err: %d ",z); //displayError("recvfrom(2)"); /* else err */

//         fwrite(dgram,z,1,stdout);
//         putchar('\n');
//
//         fflush(stdout);
     if (z > 0){
        vpkt = (unsigned short *)dgram;
        //vpkt[0]-pkt_type
        //vpkt[1]-vfr_num
        //vpkt[2]-vpix_count
        //vpkt[3]-vrow_count
        //vpkt[4]-vrow_num

        if (vpkt[0]!=0x301){
            printf("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: pkt type\n",rcv_cnt, z, vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt);
            err = 1;
        }
        if (((vpkt[1]&0x0F)!=vfr_clc) && vfr_chk){
            printf("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vfr_clc=%02d\n",rcv_cnt, z, vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt, vfr_clc);
            err = 1; vfr_chk = 0;
        }
        if (vpkt[2]!=0x400){
            printf("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vpix_count\n",rcv_cnt, z, vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt);
            err = 1;
        }
        if (vpkt[3]!=0x400){
            printf("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vrow_count\n",rcv_cnt, z, vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt);
            err = 1;
        }
        if ((vpkt[4]!=vrow_clc) && vrow_chk){
            printf("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vrow_clc=%04d\n",rcv_cnt, z, vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt, vrow_clc);
            err = 1;
        }

        if (err){
            err = 0;
            err_cnt++;
        }

        vrow_chk = 1;
        if ((vpkt[4]+1)==0x400)
        vrow_clc = 0;
        else
        vrow_clc = vpkt[4] + 1;

        if (vpkt[4]==(vpkt[3]-1)){
            vfr_chk = 1;
            if ((vpkt[1]+1)==16)
            vfr_clc = 0;
            else
            vfr_clc = vpkt[1] + 1;
        }

//        if (rcv_cnt == 24)
//          break;
        rcv_cnt++;
    }
  } //while (1)
  
  printf("....completed!\n");
  return 0;
 }

