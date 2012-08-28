//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 11/11/2009
//-- Module Name : pcie_off_on.v
//--
//-- Description : Turn-off Control Unit.
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns

module pcie_off_on
(
  req_compl_i,
  compl_done_i,

  cfg_to_turnoff_n_i, //Configuration To Turnoff:
                      //Notifies the user that a PME_TURN_Off message has been received
                      //and the main power will soon be removed.

  cfg_turnoff_ok_n_o, //Подтверждение для Configuration To Turnoff

  rst_n,
  clk
);

//------------------------------------
// Port Declarations
//------------------------------------
input               clk;
input               rst_n;

input               req_compl_i;
input               compl_done_i;

input               cfg_to_turnoff_n_i;
output              cfg_turnoff_ok_n_o;

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
  // Local Registers
reg                 trn_pending;
reg                 cfg_turnoff_ok_n_o;


  /*
   *  Check if completion is pending
   */
  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin
      trn_pending <= 0;
    end
    else
    begin
      if (!trn_pending && req_compl_i)
        trn_pending <= 1'b1;
      else
      if (compl_done_i)
        trn_pending <= 1'b0;
    end
  end

  /*
   *  Turn-off OK if requested and no transaction is pending
   */
  always @ ( posedge clk or negedge rst_n )
  begin
    if (!rst_n )
    begin
      cfg_turnoff_ok_n_o <= 1'b1;
    end
    else
    begin
      if ( !cfg_to_turnoff_n_i && !trn_pending )
        cfg_turnoff_ok_n_o <= 1'b0;
      else
        cfg_turnoff_ok_n_o <= 1'b1;
    end
  end

endmodule // pcie_off_on

