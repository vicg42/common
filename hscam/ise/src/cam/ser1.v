// file: ser.v
// (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//----------------------------------------------------------------------------
// User entered comments
//----------------------------------------------------------------------------
// None
//----------------------------------------------------------------------------

`timescale 1ps/1ps

(* CORE_GENERATION_INFO = "ser,selectio_wiz_v3_1,{component_name=ser,bus_dir=OUTPUTS,bus_sig_type=DIFF,bus_io_std=LVDS_33,use_serialization=true,use_phase_detector=false,serialization_factor=7,enable_bitslip=false,enable_train=false,system_data_width=4,bus_in_delay=NONE,bus_out_delay=FIXED,clk_sig_type=SINGLE,clk_io_std=LVCMOS18,clk_buf=BUFPLL,active_edge=RISING,clk_delay=NONE,v6_bus_in_delay=NONE,v6_bus_out_delay=NONE,v6_clk_buf=BUFIO,v6_active_edge=NOT_APP,v6_ddr_alignment=SAME_EDGE_PIPELINED,v6_oddr_alignment=SAME_EDGE,ddr_alignment=C0,v6_interface_type=NETWORKING,interface_type=NETWORKING,v6_bus_in_tap=0,v6_bus_out_tap=0,v6_clk_io_std=LVCMOS18,v6_clk_sig_type=DIFF}" *)

module ser1
   // width of the data for the system
 #(parameter sys_w = 4,
   // width of the data for the device
   parameter dev_w = 28)
 (
  // From the device out to the system
  input  [dev_w-1:0] DATA_OUT_FROM_DEVICE,
  output [sys_w-1:0] DATA_OUT_TO_PINS_P,
  output [sys_w-1:0] DATA_OUT_TO_PINS_N,
  output  CLK_TO_PINS_P,
  output  CLK_TO_PINS_N,
  input              CLK_IN,        // Fast clock input from PLL/MMCM
  input              CLK_DIV_IN,    // Slow clock input from PLL/MMCM
  input              LOCKED_IN,
  output             LOCKED_OUT,
  input              CLK_RESET,
  input              IO_RESET);
  localparam         num_serial_bits = dev_w/sys_w;
  // Signal declarations
  ////------------------------------
  wire               clock_enable = 1'b1;
  wire clk_fwd_out;
  // Before the buffer
  wire   [sys_w-1:0] data_out_to_pins_int;
  // Between the delay and serdes
  wire   [sys_w-1:0] data_out_to_pins_predelay;
  // Array to use intermediately from the serdes to the internal
  //  devices. bus "0" is the leftmost bus
  wire [sys_w-1:0]  oserdes_d[0:7];   // fills in starting with 7
  // Create the clock logic
   BUFPLL
    #(.DIVIDE        (7))
    bufpll_inst
      (.IOCLK        (clk_in_int_buf),
       .LOCK         (LOCKED_OUT),
       .SERDESSTROBE (serdesstrobe),
       .GCLK         (CLK_DIV_IN), // GCLK must be driven by BUFG
       .LOCKED       (LOCKED_IN),
       .PLLIN        (CLK_IN));

  // We have multiple bits- step over every bit, instantiating the required elements
  genvar pin_count;
  genvar slice_count;
  generate for (pin_count = 0; pin_count < sys_w; pin_count = pin_count + 1) begin: pins
    // Instantiate the buffers
    ////------------------------------
    // Instantiate a buffer for every bit of the data bus
    OBUFDS
      #(.IOSTANDARD ("LVDS_33"))
     obufds_inst
       (.O          (DATA_OUT_TO_PINS_P  [pin_count]),
        .OB         (DATA_OUT_TO_PINS_N  [pin_count]),
        .I          (data_out_to_pins_int[pin_count]));

    // Instantiate the delay primitive
    ////-------------------------------
/*    IODELAY2
     #(.DATA_RATE                  ("SDR"),
       .ODELAY_VALUE               (0),
       .COUNTER_WRAPAROUND         ("STAY_AT_LIMIT"),
       .DELAY_SRC                  ("ODATAIN"),
       .SERDES_MODE                ("NONE"),
       .SIM_TAPDELAY_VALUE         (75))
     iodelay2_bus
      (
       // required datapath
       .T                      (1'b0),
       .DOUT                   (data_out_to_pins_int     [pin_count]),
       .ODATAIN                (data_out_to_pins_predelay[pin_count]),
       // inactive data connections
       .IDATAIN                (1'b0),
       .TOUT                   (),
       .DATAOUT                (),
       .DATAOUT2               (),
       // connect up the clocks
       .IOCLK0                 (1'b0),                 // No calibration needed
       .IOCLK1                 (1'b0),                 // No calibration needed
       // Tie of the variable delay programming
       .CLK                    (1'b0),
       .CAL                    (1'b0),
       .INC                    (1'b0),
       .CE                     (1'b0),
       .BUSY                   (),
       .RST                    (1'b0));*/


     // Instantiate the serdes primitive
     ////------------------------------
     // local wire only for use in this generate loop
     wire cascade_ms_d;
     wire cascade_ms_t;
     wire cascade_sm_d;
     wire cascade_sm_t;

     // declare the oserdes
     OSERDES2
       #(.DATA_RATE_OQ   ("SDR"),
         .DATA_RATE_OT   ("SDR"),
         .TRAIN_PATTERN  (0),
         .DATA_WIDTH     (num_serial_bits),
         .SERDES_MODE    ("MASTER"),
         .OUTPUT_MODE    ("SINGLE_ENDED"))
      oserdes2_master
       (.D1         (oserdes_d[3][pin_count]),
        .D2         (oserdes_d[2][pin_count]),
        .D3         (oserdes_d[1][pin_count]),
        .D4         (oserdes_d[0][pin_count]),
        .T1         (1'b0),
        .T2         (1'b0),
        .T3         (1'b0),
        .T4         (1'b0),
        .SHIFTIN1   (1'b1),
        .SHIFTIN2   (1'b1),
        .SHIFTIN3   (cascade_sm_d),
        .SHIFTIN4   (cascade_sm_t),
        .SHIFTOUT1  (cascade_ms_d),
        .SHIFTOUT2  (cascade_ms_t),
        .SHIFTOUT3  (),
        .SHIFTOUT4  (),
        .TRAIN      (1'b0),
        .OCE        (clock_enable),
        .CLK0       (clk_in_int_buf),
        .CLK1       (1'b0),
        .CLKDIV     (CLK_DIV_IN),
        .OQ         (data_out_to_pins_int[pin_count]),
        .TQ         (),
        .IOCE       (serdesstrobe),
        .TCE        (clock_enable),
        .RST        (IO_RESET));


     OSERDES2
       #(.DATA_RATE_OQ   ("SDR"),
         .DATA_RATE_OT   ("SDR"),
         .DATA_WIDTH     (num_serial_bits),
         .SERDES_MODE    ("SLAVE"),
         .TRAIN_PATTERN  (1),
         .OUTPUT_MODE    ("SINGLE_ENDED"))
      oserdes2_slave
       (.D1         (oserdes_d[7][pin_count]),
        .D2         (oserdes_d[6][pin_count]),
        .D3         (oserdes_d[5][pin_count]),
        .D4         (oserdes_d[4][pin_count]),
        .T1         (1'b0),
        .T2         (1'b0),
        .T3         (1'b0),
        .T4         (1'b0),
        .SHIFTIN1   (cascade_ms_d),
        .SHIFTIN2   (cascade_ms_t),
        .SHIFTIN3   (1'b1),
        .SHIFTIN4   (1'b1),
        .SHIFTOUT1  (),
        .SHIFTOUT2  (),
        .SHIFTOUT3  (cascade_sm_d),
        .SHIFTOUT4  (cascade_sm_t),
        .TRAIN      (1'b0),
        .OCE        (clock_enable),
        .CLK0       (clk_in_int_buf),
        .CLK1       (1'b0),
        .CLKDIV     (CLK_DIV_IN),
        .OQ         (),
        .TQ         (),
        .IOCE       (serdesstrobe),
        .TCE        (clock_enable),
        .RST        (IO_RESET));
     // Concatenate the serdes outputs together. Keep the timesliced
     //   bits together, and placing the earliest bits on the right
     //   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     //       the output will be 3210, 7654, ...
     ////---------------------------------------------------------
     for (slice_count = 0; slice_count < num_serial_bits; slice_count = slice_count + 1) begin: out_slices
        // This places the first data in time on the right
        assign oserdes_d[8-slice_count-1] =
           DATA_OUT_FROM_DEVICE[slice_count*sys_w+:sys_w];
        // To place the first data in time on the left, use the
        //   following code, instead
        // assign oserdes_d[slice_count] =
        //    DATA_OUT_FROM_DEVICE[slice_count*sys_w+:sys_w];
     end
  end
  endgenerate
   // clock forwarding logic



     OSERDES2
       #(.DATA_RATE_OQ   ("SDR"),
         .DATA_RATE_OT   ("SDR"),
         .TRAIN_PATTERN  (0),
         .DATA_WIDTH     (num_serial_bits),
         .SERDES_MODE    ("MASTER"),
         .OUTPUT_MODE    ("SINGLE_ENDED"))
      oserdes2_master_clk
       (.D1         (1'b0),
        .D2         (1'b1),
        .D3         (1'b1),
        .D4         (1'b1),
        .T1         (1'b0),
        .T2         (1'b0),
        .T3         (1'b0),
        .T4         (1'b0),
        .SHIFTIN1   (1'b1),
        .SHIFTIN2   (1'b1),
        .SHIFTIN3   (sm_d),
        .SHIFTIN4   (sm_t),
        .SHIFTOUT1  (ms_d),
        .SHIFTOUT2  (ms_t),
        .SHIFTOUT3  (),
        .SHIFTOUT4  (),
        .TRAIN      (1'b0),
        .OCE        (clock_enable),
        .CLK0       (clk_in_int_buf),
        .CLK1       (1'b0),
        .CLKDIV     (CLK_DIV_IN),
        .OQ         (clk_fwd_out),
        .TQ         (),
        .IOCE       (serdesstrobe),
        .TCE        (clock_enable),
        .RST        (IO_RESET));


     OSERDES2
       #(.DATA_RATE_OQ   ("SDR"),
         .DATA_RATE_OT   ("SDR"),
         .DATA_WIDTH     (num_serial_bits),
         .SERDES_MODE    ("SLAVE"),
         .TRAIN_PATTERN  (1),
         .OUTPUT_MODE    ("SINGLE_ENDED"))
      oserdes2_slave_clk
       (.D1         (1'b1),
        .D2         (1'b1),
        .D3         (1'b0),
        .D4         (1'b0),
        .T1         (1'b0),
        .T2         (1'b0),
        .T3         (1'b0),
        .T4         (1'b0),
        .SHIFTIN1   (ms_d),
        .SHIFTIN2   (ms_t),
        .SHIFTIN3   (1'b1),
        .SHIFTIN4   (1'b1),
        .SHIFTOUT1  (),
        .SHIFTOUT2  (),
        .SHIFTOUT3  (sm_d),
        .SHIFTOUT4  (sm_t),
        .TRAIN      (1'b0),
        .OCE        (clock_enable),
        .CLK0       (clk_in_int_buf),
        .CLK1       (1'b0),
        .CLKDIV     (CLK_DIV_IN),
        .OQ         (),
        .TQ         (),
        .IOCE       (serdesstrobe),
        .TCE        (clock_enable),
        .RST        (IO_RESET));
/*    ODDR2
     #(.DDR_ALIGNMENT  ("C0"),
       .INIT           (1'b0),
       .SRTYPE         ("ASYNC"))
     oddr2_inst
      (.D0             (1'b1),
       .D1             (1'b0),
        .C0            (CLK_DIV_IN),
        .C1            (clk_fwd_int_n),
       .CE             (clock_enable),
       .Q              (clk_fwd_out),
       .R              (CLK_RESET),
       .S              (1'b0));*/

// Clock Output Buffer
    OBUFDS
      #(.IOSTANDARD ("LVDS_33"))
     obufds_inst
       (.O          (CLK_TO_PINS_P),
        .OB         (CLK_TO_PINS_N),
        .I          (clk_fwd_out));
endmodule
