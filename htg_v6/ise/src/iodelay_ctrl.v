//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: 3.4
//  \   \         Application: MIG
//  /   /         Filename: iodelay_ctrl.v
// /___/   /\     Date Last Modified: $Date: 2010/02/26 08:58:33 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose:
//   This module instantiates the IDELAYCTRL primitive, which continously 
//   calibrates the IODELAY elements in the region to account for varying
//   environmental conditions. A 200MHz or 300MHz reference clock (depending 
//   on the desired IODELAY tap resolution) must be supplied
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ps/1ps

module iodelay_ctrl #
  (
   parameter TCQ         = 100,           // clk->out delay (sim only)   
   parameter IODELAY_GRP = "IODELAY_MIG", // May be assigned unique name when
                                          // multiple IP cores used in design
   parameter INPUT_CLK_TYPE  = "DIFFERENTIAL", // input clock type 
                                               // "DIFFERENTIAL","SINGLE_ENDED"
   parameter RST_ACT_LOW  = 1             // Reset input polarity
                                          // (0 = active high, 1 = active low)
   )
  (
   input  clk_ref_p,
   input  clk_ref_n,
   input  clk_ref,
   input  sys_rst,
   output iodelay_ctrl_rdy,
   input pll_lock // HTG
   );

  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on DCM lock status)
  // COMMENTED, RC, 01/13/09 - causes pack error in MAP w/ larger #
  localparam RST_SYNC_NUM = 15;
  //  localparam RST_SYNC_NUM = 25;
  
  wire                   clk_ref_bufg;  
  wire                   clk_ref_ibufg;
  wire                   rst_ref;
  reg [RST_SYNC_NUM-1:0] rst_ref_sync_r /* synthesis syn_maxfan = 10 */;  
  wire                   rst_tmp_idelay;
  wire                   sys_rst_act_hi;
  
  //***************************************************************************
  
  // Possible inversion of system reset as appropriate
  assign  sys_rst_act_hi = RST_ACT_LOW ? ~sys_rst: sys_rst;
  
  //***************************************************************************
  // Input buffer for IDELAYCTRL reference clock - handle either a 
  // differential or single-ended input
  //***************************************************************************
  //OD removing this portion - signal already buffered.
/*   generate
    if (INPUT_CLK_TYPE == "DIFFERENTIAL") begin: diff_clk_ref
      IBUFGDS #
        (
         .DIFF_TERM ("TRUE"),
         .IBUF_LOW_PWR ("FALSE")         
         )
        u_ibufg_clk_ref
          (
           .I  (clk_ref_p),
           .IB (clk_ref_n),
           .O  (clk_ref_ibufg)
           );      
    end else if (INPUT_CLK_TYPE == "SINGLE_ENDED") begin : se_clk_ref 
      IBUFG #
        (
         .IBUF_LOW_PWR ("FALSE")
         )
        u_ibufg_clk_ref
          (
           .I (clk_ref),
           .O (clk_ref_ibufg)
           );      
    end
  endgenerate

  //***************************************************************************
  // Global clock buffer for IDELAY reference clock
  //***************************************************************************

  BUFG u_bufg_clk_ref
    (
     .O (clk_ref_bufg),
     .I (clk_ref_ibufg)
     );
*/
  //*****************************************************************
  // IDELAYCTRL reset
  // This assumes an external clock signal driving the IDELAYCTRL
  // blocks. Otherwise, if a PLL drives IDELAYCTRL, then the PLL
  // lock signal will need to be incorporated in this.
  //*****************************************************************

// OD Add assignment for clock signal already buffered in design.
 assign clk_ref_bufg = clk_ref;

  // Add PLL lock if PLL drives IDELAYCTRL in user design  
  
  assign rst_tmp_idelay = (sys_rst_act_hi | ~pll_lock);

  always @(posedge clk_ref_bufg or posedge rst_tmp_idelay)
    if (rst_tmp_idelay)
      rst_ref_sync_r <= #TCQ {RST_SYNC_NUM{1'b1}};
    else
      rst_ref_sync_r <= #TCQ rst_ref_sync_r << 1;

  assign rst_ref  = rst_ref_sync_r[RST_SYNC_NUM-1];
  
  //*****************************************************************
  
  (* IODELAY_GROUP = IODELAY_GRP *) IDELAYCTRL u_idelayctrl
    (
     .RDY    (iodelay_ctrl_rdy),
     .REFCLK (clk_ref_bufg),
     .RST    (rst_ref)
     );

endmodule
