`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Engineer: ST
//
// Module Name:  prog_flash
// Description:  low level P30 BPI PROM prog_flash
//
// xapp518
// usr_ctrl[31:0] + data[]
//
// usr_ctrl[7 :0] - usr cmd
// usr_ctrl[31:8] - adr start/end
//
//////////////////////////////////////////////////////////////////////////////////

`define CI_USR_CMD_ADR_START 8'h00
`define CI_USR_CMD_ADR_END   8'h01
`define CI_USR_CMD_UNLOCK    8'h02
`define CI_USR_CMD_ERASE     8'h03
`define CI_USR_CMD_WRITE     8'h04
//`define End_Program  32'h446F6E65 //Done
`define CI_UNLOCK_POLLCNT_MAX 9'h100
//`define unlock_wait_count 15'h0004
`define CI_ERASE_POLLCNT_MAX 24'hF42400 //800ms
`define CI_BUFFER_READY_CHK_COUNT_MAX 15'h4650 //900us
`define addr_increment_64kW 17'h10000
`define addr_increment_16kW 15'h4000
//`define max_64kW_blk_count       8'hFF
`define start_16kW_blk_address   24'hFF0000
`define max_16kW_blk_count       3'h4
`define prog_word_count 16'h0020


module prog_flash(
output            p_out_usr_rd,
input      [31:0] p_in_usr_txd,
input             p_in_usr_txrdy_n,

output     [23:0] p_out_phy_adr,
input      [15:0] p_in_phy_d,
output reg [15:0] p_out_phy_d,
output reg        p_out_phy_dio_t,
output reg        p_out_phy_oe_n,
output reg        p_out_phy_we_n, // latches addr and data on rising edge
output reg        p_out_phy_cs_n,
input             p_in_phy_wait,

output            p_out_rdy,
output     [3:0]  p_out_status,

output     [31:0] p_out_tst,
input      [31:0] p_in_tst,

input             p_in_clk,
input             p_in_rst
);

reg [5:0]   i_fsm_cs, i_fsm_ns;
reg         rst_reg;
reg         rst_SR_reg;
reg         rst_poll_cnt;
reg         rst_data_cnt;

reg [23:0]  A_reg;
reg [15:0]  DQ_O_reg;
reg         WE_N_reg;
reg         OE_N_reg;
reg         CS_N_reg;
reg         FIFO_RD_EN_reg;
reg         start_addr_reg_en;
reg [7:0]   start_addr_reg;
reg [23:0]  end_addr_reg;
reg         end_addr_reg_en;
reg [23:0]  A_inc;
reg         A_reg_en;
reg         SR_reg_en;
reg         blk_cnt_en;
reg [7:0]   SR_reg;
reg [8:0]   unlck_cnt;
reg         unlck_cnt_en;
reg [2:0]   error_flag;
reg [2:0]   error_reg;
reg         error_reg_en;
reg         load_blk_cnt;
reg [8:0]   blk_cnt;
reg [23:0]  poll_cnt;
reg         poll_cnt_en;
reg [8:0]   data_cnt;
reg         data_cnt_en;
reg [1:0]   test_cnt;
reg         test_cnt_en;
reg         byte_sel_reg, byte_sel_en;
reg         prog_ready;
reg         prog_done;
reg         i_irq;
reg         i_irq_out;

wire        last_blk;
wire [7:0]  end_blk, start_blk;
wire [24:1] A_inc_blk_unlk; // block lock read identifier address - offset 0x02
wire [24:1] start_addr;
wire [23:0] end_addr;
wire        end_addr_reached;
wire [15:0] data_sel;
//`ifdef ChipScope
//wire  [35:0]  CONTROL;
//wire  [64:0]  TRIG;
//`endif

parameter [5:0]
S_IDLE    = 6'h00,
S_CMD   = 6'h01,
S_CMD_BLOCK_LOCK_SETUP   = 6'h02,
S_CMD_UNLOCK   = 6'h03,
S_CMD_UNLOCK1   = 6'h04,
S_RD_ID     = 6'h05,
S_RD_ID1   = 6'h06,
S_UNLCK_RD_SR   = 6'h07,
S_UNLCK_RD_SR1   = 6'h08,
S_UNLCK_RD_SR2   = 6'h1E,
S_UNLCK_CHK_ID  = 6'h09,
S_UNLCK_CHK_POLLCNT   = 6'h0A,
S_ERASE_CLR_SR   = 6'h24,
S_ERASE_CLR_SR1 = 6'h25,
S_ERASE_SETUP  = 6'h0B,
S_ERASE_CONFIRM  = 6'h0C,
S_ERASE_CONFIRM1  = 6'h0D,
S_ERASE_RD_SR  = 6'h0E,
S_ERASE_RD_SR1  = 6'h0F,
S_ERASE_RD_SR2  = 6'h20,
S_ERASE_CHK_SR   = 6'h10,
S_ERASE_CHK_POLLCNT= 6'h11,
S_PROG_SETUP  = 6'h12,
S_PROG_RD_SR  = 6'h13,
S_PROG_RD_SR1  = 6'h14,
S_PROG_RD_SR2  = 6'h21,
S_PROG_CHK_SR = 6'h15,
S_PROG_CHK_POLLCNT= 6'h16,
S_PROG_LD_ADR  = 6'h17,
S_PROG_LD_ADR1  = 6'h26,
S_PROG_LD_ADR2  = 6'h27,
S_PROG_CHK_DCOUNT = 6'h18,
S_PROG_LD_BUFFER  = 6'h22,
S_PROG_LD_BUFFER_UNDERRUN = 6'h28,
S_PROG_LD_BUFFER_UNDERRUN1 = 6'h29,
S_PROG_LD_BUFFER_UNDERRUN2 = 6'h2A,
S_PROG_BUF  = 6'h19,
S_PROG_BUF1      = 6'h2B,
S_PROG_BUFPROG_RD_SR  = 6'h1A,
S_PROG_BUFPROG_RD_SR1  = 6'h1B,
S_PROG_BUFPROG_CHK_SR = 6'h1C,
S_PROG_BUFPROG_CHK_POLLCNT= 6'h1D,
S_ERR     = 6'h1F;


always @ (*)
begin : SM_mux
  prog_ready = 1'b0;
  FIFO_RD_EN_reg = 1'b0;
  i_fsm_ns = S_IDLE;
  p_out_phy_dio_t = 1'b0;
  rst_reg = 1'b0;
  rst_SR_reg = 1'b0;
  rst_poll_cnt = 1'b0;
  rst_data_cnt = 1'b0;
  WE_N_reg = 1'b1;
  OE_N_reg= 1'b1;
  CS_N_reg= 1'b0;
  start_addr_reg_en = 1'b0;
  end_addr_reg_en = 1'b0;
  A_reg_en = 1'b0;
  A_inc = 17'b0;
  SR_reg_en = 1'b0;
  load_blk_cnt = 1'b0;
  blk_cnt_en = 1'b0;
  data_cnt_en = 1'b0;
  DQ_O_reg = 16'h0000;
  unlck_cnt_en = 1'b0;
  poll_cnt_en = 1'b0;
  test_cnt_en = 1'b0;
  error_flag = 3'b0;
  error_reg_en = 1'b0;
  byte_sel_en = 1'b0;
  i_irq = 1'b0;

  case (i_fsm_cs)

    //------------------------------------------
    //ѕрием и выбор USR CMD
    //------------------------------------------
    S_IDLE :
      begin
          rst_reg = 1'b1;
          rst_poll_cnt = 1'b1;
          rst_data_cnt = 1'b1;
          rst_SR_reg = 1'b1;
          CS_N_reg = 1'b1;
          prog_ready = 1'b1;

          if (~p_in_usr_txrdy_n) begin
            FIFO_RD_EN_reg = 1'b1;
            i_fsm_ns = S_CMD;
          end
          else begin
            i_fsm_ns = S_IDLE;
          end
      end //S_IDLE

    S_CMD :
      begin
          prog_ready = 1'b1;
          if (p_in_usr_txd[7:0] == `CI_USR_CMD_UNLOCK) begin
            WE_N_reg = 1'b0;
            DQ_O_reg = 16'h60;
            A_reg_en = 1'b1;
            A_inc = start_addr + 2;
            load_blk_cnt = 1'b1;
            i_fsm_ns = S_CMD_BLOCK_LOCK_SETUP;
          end
          else if (p_in_usr_txd[7:0] == `CI_USR_CMD_ERASE) begin
            WE_N_reg = 1'b0;
            DQ_O_reg = 16'h50;
            A_reg_en = 1'b1;
            A_inc = start_addr;
            load_blk_cnt = 1'b1;
            i_fsm_ns = S_ERASE_CLR_SR;
          end
          else if (p_in_usr_txd[7:0] == `CI_USR_CMD_WRITE) begin
            WE_N_reg = 1'b0;
            DQ_O_reg = 16'hE8;
            load_blk_cnt = 1'b1;
            A_reg_en = 1'b1;
            A_inc = start_addr;
            i_fsm_ns = S_PROG_SETUP;
          end
          else if (p_in_usr_txd[7:0] == `CI_USR_CMD_ADR_START) begin
            start_addr_reg_en = 1'b1;
            i_fsm_ns = S_IDLE; //ADR_START DONE!!!!
            i_irq = 1'b1;
          end
          else if (p_in_usr_txd[7:0] == `CI_USR_CMD_ADR_END) begin
            end_addr_reg_en = 1'b1;
            i_fsm_ns = S_IDLE; //ADR_END DONE!!!!
            i_irq = 1'b1;
          end
          else begin
            CS_N_reg= 1'b1;
            i_fsm_ns = S_IDLE;
          end
      end //S_CMD


    //------------------------------------------
    //FLASH UNLOCKED
    //------------------------------------------
    S_CMD_BLOCK_LOCK_SETUP :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'h60;
        A_inc = A_inc_blk_unlk;
        i_fsm_ns = S_CMD_UNLOCK;
      end
    S_CMD_UNLOCK :
      begin
        WE_N_reg = 1'b0;
        DQ_O_reg = 16'hD0;
        A_inc = A_inc_blk_unlk;
        i_fsm_ns = S_CMD_UNLOCK1;
      end
    S_CMD_UNLOCK1 :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'hD0;
        A_inc = A_inc_blk_unlk;
        rst_poll_cnt = 1'b1;
        i_fsm_ns = S_RD_ID;
      end //S_CMD_UNLOCK1

    S_RD_ID :
      begin
        WE_N_reg = 1'b0;
        DQ_O_reg = 16'h90;
        A_inc = A_inc_blk_unlk;
        i_fsm_ns = S_RD_ID1;
      end
    S_RD_ID1 :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'h90;
        A_inc = A_inc_blk_unlk;
        i_fsm_ns = S_UNLCK_RD_SR;
      end
    S_UNLCK_RD_SR :
      begin
        WE_N_reg = 1'b1;
        A_inc = A_inc_blk_unlk;
        i_fsm_ns = S_UNLCK_RD_SR1;
      end
    S_UNLCK_RD_SR1 :
      begin
        SR_reg_en =  1'b1;
        A_inc = A_inc_blk_unlk;
        OE_N_reg= 1'b0;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_UNLCK_RD_SR2;
      end
    S_UNLCK_RD_SR2 :
      begin
        SR_reg_en =  1'b1;
        A_inc = A_inc_blk_unlk;
        OE_N_reg= 1'b1;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_UNLCK_CHK_ID;
      end
    S_UNLCK_CHK_ID :
      begin
        A_inc = A_inc_blk_unlk;
        if (SR_reg[0] == 1'b0)
        begin
          if (last_blk)
          begin
            WE_N_reg = 1'b1;
            CS_N_reg= 1'b1;
            i_fsm_ns = S_IDLE; //UNLOCK DONE!!!!
            i_irq = 1'b1;
          end
          else
          begin
            DQ_O_reg = 16'h60;
            WE_N_reg = 1'b0;
            blk_cnt_en = 1'b1;
            A_reg_en = 1'b1;
            i_fsm_ns = S_CMD_BLOCK_LOCK_SETUP;
          end
        end
        else
        begin
          unlck_cnt_en = 1'b1;
          i_fsm_ns = S_UNLCK_CHK_POLLCNT;
        end
      end
    S_UNLCK_CHK_POLLCNT :
      begin
        if (unlck_cnt == `CI_UNLOCK_POLLCNT_MAX)
        begin
          error_flag = 3'b001;
          error_reg_en = 1'b1;
          i_fsm_ns = S_ERR; //UNLOCK ERROR!!!!
        end
        else
        begin
          WE_N_reg = 1'b0;
          DQ_O_reg = 16'h60;
          i_fsm_ns = S_CMD_BLOCK_LOCK_SETUP;
        end
      end


    //------------------------------------------
    //FLASH ERASE
    //------------------------------------------
    S_ERASE_CLR_SR :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'h50;
        i_fsm_ns = S_ERASE_CLR_SR1;
      end
    S_ERASE_CLR_SR1 :
      begin
        WE_N_reg = 1'b0;
        DQ_O_reg = 16'h20;
        i_fsm_ns = S_ERASE_SETUP;
      end
    S_ERASE_SETUP :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'h20;
        i_fsm_ns = S_ERASE_CONFIRM;
      end
    S_ERASE_CONFIRM :
      begin
        WE_N_reg = 1'b0;
        DQ_O_reg = 16'hD0;
        i_fsm_ns = S_ERASE_CONFIRM1;
      end
    S_ERASE_CONFIRM1 :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'hD0;
        i_fsm_ns = S_ERASE_RD_SR;
      end
    S_ERASE_RD_SR :
      begin
        WE_N_reg = 1'b1;
        i_fsm_ns = S_ERASE_RD_SR1;
      end
    S_ERASE_RD_SR1 :
      begin
        SR_reg_en =  1'b1;
        OE_N_reg= 1'b0;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_ERASE_RD_SR2;
      end
    S_ERASE_RD_SR2 :
      begin
        SR_reg_en =  1'b1;

        OE_N_reg= 1'b1;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_ERASE_CHK_SR;
      end
    S_ERASE_CHK_SR :
      begin
          `ifdef SIMULATION
          if (SR_reg[7] == 1'b1) //SR.7 = 1
          `else
          if (SR_reg == 8'h80)
          `endif
          begin
            A_reg_en = 1'b1;
            A_inc = A_inc_blk_unlk;
            if (last_blk)
            begin
              WE_N_reg = 1'b1;
              CS_N_reg= 1'b1;
              blk_cnt_en = 1'b0;
              i_fsm_ns = S_IDLE; //ERASE DONE!!!!
              i_irq = 1'b1;
            end
            else
            begin
              WE_N_reg = 1'b0;
              DQ_O_reg = 16'h50;
              blk_cnt_en = 1'b1;
              rst_poll_cnt = 1'b1;
              i_fsm_ns = S_ERASE_CLR_SR;
            end
          end
          else
          if (SR_reg[7] == 1'b1) //SR.7 = 1
          begin
            error_flag = 3'b010;
            error_reg_en = 1'b1;
            i_fsm_ns = S_ERR;  //ERASE ERROR!!!!
          end
          else
          begin
            poll_cnt_en = 1'b1;
            i_fsm_ns = S_ERASE_CHK_POLLCNT;
          end
      end
    S_ERASE_CHK_POLLCNT :
      begin
        if (poll_cnt == `CI_ERASE_POLLCNT_MAX)
        begin
          error_flag = 3'b011;
          error_reg_en = 1'b1;
          i_fsm_ns = S_ERR;  //ERASE ERROR!!!!
        end
        else
        begin
          i_fsm_ns = S_ERASE_RD_SR;
        end
      end


    //------------------------------------------
    //FLASH WRITE DATA
    //------------------------------------------
    S_PROG_SETUP :
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'hE8;
        i_fsm_ns = S_PROG_RD_SR;
      end
    S_PROG_RD_SR : //13
      begin
        WE_N_reg = 1'b1;
        i_fsm_ns = S_PROG_RD_SR1;
      end
    S_PROG_RD_SR1 : //14
      begin
        SR_reg_en =  1'b1;
        OE_N_reg= 1'b0;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_PROG_RD_SR2;
      end
    S_PROG_RD_SR2 : //21
      begin
        SR_reg_en =  1'b1;
        OE_N_reg= 1'b1;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_PROG_CHK_SR;
      end
    S_PROG_CHK_SR : //15
      begin
        if (SR_reg[7] == 1'b1) //SR.7 = 1
        begin
          WE_N_reg = 1'b0;
          DQ_O_reg = `prog_word_count - 1; //max word count = 512
          rst_poll_cnt = 1'b1;
          i_fsm_ns = S_PROG_LD_ADR;
        end
        else
        begin
          poll_cnt_en = 1'b1;
          i_fsm_ns = S_PROG_CHK_POLLCNT;
        end
      end
    S_PROG_CHK_POLLCNT : // 16
      begin
        if (poll_cnt[7:0] == `CI_BUFFER_READY_CHK_COUNT_MAX)
        begin
          error_flag = 3'b100;
          error_reg_en = 1'b1;
          i_fsm_ns = S_ERR; //WRITE ERROR!!!!
        end
        else
        begin
          WE_N_reg = 1'b0;
          DQ_O_reg = 16'h20;
          i_fsm_ns = S_PROG_SETUP;
        end
      end

    //Set Write Word Count:
    S_PROG_LD_ADR : //17
      begin
          WE_N_reg = 1'b1;
          DQ_O_reg = `prog_word_count - 1;
          if (~p_in_usr_txrdy_n) // The FIFO may underrun if the host data feeds too slowly
          begin
            FIFO_RD_EN_reg = 1'b1;
            i_fsm_ns = S_PROG_LD_ADR1 ;
          end
          else
          begin
            FIFO_RD_EN_reg = 1'b0;
            i_fsm_ns = S_PROG_LD_ADR ;
          end
      end
    //Set Block Address:
    S_PROG_LD_ADR1 : //26
      begin
        WE_N_reg = 1'b0;
        DQ_O_reg = data_sel;
        i_fsm_ns = S_PROG_LD_ADR2;
      end
    S_PROG_LD_ADR2 : //27
      begin
          WE_N_reg = 1'b1;
          DQ_O_reg = data_sel;
          byte_sel_en = 1'b1;
          if (~p_in_usr_txrdy_n)
          begin
            i_fsm_ns = S_PROG_CHK_DCOUNT;
          end
          else
          begin
            FIFO_RD_EN_reg = 1'b0;
            i_fsm_ns = S_PROG_LD_BUFFER_UNDERRUN;
          end
      end
    //Write data
    S_PROG_CHK_DCOUNT : //18
      begin
        if (data_cnt == `prog_word_count - 1)
        begin
          DQ_O_reg = 16'hD0;
          WE_N_reg = 1'b0;
          rst_data_cnt = 1'b1;
          i_fsm_ns = S_PROG_BUF;
        end
        else
        begin
          WE_N_reg = 1'b0;
          A_reg_en = 1'b1;
          A_inc = 17'h00001;
          DQ_O_reg = data_sel;
          i_fsm_ns = S_PROG_LD_BUFFER;
        end
      end
    S_PROG_LD_BUFFER : //22
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = data_sel;
        byte_sel_en = 1'b1;
        if (~p_in_usr_txrdy_n)
        begin
          i_fsm_ns = S_PROG_CHK_DCOUNT;
          data_cnt_en = 1'b1; //ведем подсчет записаных данных (data_cnt)
          if (data_cnt == 9'h1FE)
            FIFO_RD_EN_reg = 1'b0;
          else if (byte_sel_reg)
            FIFO_RD_EN_reg = 1'b1;
            else FIFO_RD_EN_reg = 1'b0;
        end
        else
        begin // check for FIFO underrun condition
            FIFO_RD_EN_reg = 1'b0;
            data_cnt_en = 1'b1;
            i_fsm_ns = S_PROG_LD_BUFFER_UNDERRUN;
        end
      end
    S_PROG_LD_BUFFER_UNDERRUN : //28
      begin
        WE_N_reg = 1'b0;
        A_reg_en = 1'b1;
        A_inc = 17'h00001;
        DQ_O_reg = data_sel;
        data_cnt_en = 1'b1;
        i_fsm_ns = S_PROG_LD_BUFFER_UNDERRUN1;
      end
    S_PROG_LD_BUFFER_UNDERRUN1 : //29
      begin
        DQ_O_reg = data_sel;
        if (data_cnt == `prog_word_count - 1)
        begin
          i_fsm_ns = S_PROG_LD_BUFFER_UNDERRUN2;
        end
        else
        begin
          if (~p_in_usr_txrdy_n)
          begin
            FIFO_RD_EN_reg = 1'b1;
            byte_sel_en = 1'b1;
            i_fsm_ns = S_PROG_CHK_DCOUNT;
          end
          else
          begin
            if (prog_done && (data_cnt == `prog_word_count - 1)) // CI_USR_CMD_WRITE if last address has been reached
            begin

              WE_N_reg = 1'b1;
              i_fsm_ns = S_PROG_CHK_DCOUNT;
            end
            else
              i_fsm_ns = S_PROG_LD_BUFFER_UNDERRUN1;
          end
        end
      end
    S_PROG_LD_BUFFER_UNDERRUN2 : //2A
      begin
        DQ_O_reg = 16'hD0;
        WE_N_reg = 1'b0;
        rst_data_cnt = 1'b1;
        byte_sel_en = 1'b1;
        i_fsm_ns = S_PROG_BUF;
      end
    //Write Confirm
    S_PROG_BUF : //19
      begin
        WE_N_reg = 1'b1;
        DQ_O_reg = 16'hD0;
        i_fsm_ns = S_PROG_BUF1;
      end
    S_PROG_BUF1 : //2B
      begin
        i_fsm_ns = S_PROG_BUFPROG_RD_SR;
      end
    //Read Status Register
    S_PROG_BUFPROG_RD_SR : //1A
      begin
        WE_N_reg = 1'b1;
        OE_N_reg= 1'b0;
        p_out_phy_dio_t = 1'b1;
        SR_reg_en =  1'b1;
        i_fsm_ns = S_PROG_BUFPROG_RD_SR1;
      end
    S_PROG_BUFPROG_RD_SR1 : //1B
      begin
        SR_reg_en =  1'b1;
        OE_N_reg= 1'b1;
        p_out_phy_dio_t = 1'b1;
        i_fsm_ns = S_PROG_BUFPROG_CHK_SR;
      end
    S_PROG_BUFPROG_CHK_SR : //1C
      begin
        `ifdef SIMULATION
          if (SR_reg[7] == 1'b1) //SR.7 = 1
        `else
          if (SR_reg == 8'h80) //
        `endif
          begin
            blk_cnt_en = 1'b1;
            if (prog_done) begin
              WE_N_reg = 1'b1;
              CS_N_reg= 1'b1;
              i_fsm_ns = S_IDLE; //WRITE DONE!!!!
              i_irq = 1'b1;
            end
            else begin
              A_inc = 17'h00001;
              A_reg_en = 1'b1;
              WE_N_reg = 1'b0;
              DQ_O_reg = 8'hE8;
              rst_poll_cnt = 1'b1;
              i_fsm_ns = S_PROG_SETUP;
            end
          end
          else begin
            poll_cnt_en = 1'b1;
            i_fsm_ns = S_PROG_BUFPROG_CHK_POLLCNT;
          end
      end

    S_PROG_BUFPROG_CHK_POLLCNT : //1D
      begin
        if (poll_cnt[14:0] == `CI_BUFFER_READY_CHK_COUNT_MAX) begin
          error_flag = 3'b101;
          error_reg_en = 1'b1;
          i_fsm_ns = S_ERR; //WRITE ERROR!!!!
        end
        else begin
          i_fsm_ns = S_PROG_BUFPROG_RD_SR;
        end
      end

    S_ERR : //1F
      i_fsm_ns = S_ERR;

    default :
      begin
        CS_N_reg= 1'b1;
        i_fsm_ns = S_IDLE;
      end

  endcase
end //always @



always@(posedge p_in_clk or posedge p_in_rst)
begin : SEQ
  if (p_in_rst)
    i_fsm_cs = S_IDLE;
  else
    i_fsm_cs = i_fsm_ns;
end //always@

always@(posedge p_in_clk)
begin : test_counter
  if (p_in_rst)
    test_cnt = 2'b0;
  else
  if (test_cnt_en)
    test_cnt = test_cnt + 1;
end //always@

always@(posedge p_in_clk)
begin : err_reg
  if (p_in_rst)
    error_reg = 3'b0;
  else
  if (error_reg_en)
    error_reg = error_flag;
end //always@

always@(posedge p_in_clk)
begin : unlck_counter
  if (rst_reg)
    unlck_cnt = 9'b0;
  else
  if (unlck_cnt_en)
    unlck_cnt = unlck_cnt + 1;
end //always@

always@(negedge p_in_clk)
begin : SR_register
  if (rst_SR_reg)
  begin
    SR_reg = 8'b0;
    p_out_phy_oe_n = 1'b1;
  end
  else
  if (SR_reg_en)
  begin
    SR_reg = p_in_phy_d;
    p_out_phy_oe_n = OE_N_reg;
  end
end //always@

always@(posedge p_in_clk)
begin : data_counter
  if (rst_data_cnt)
    data_cnt = 9'b0;
  else
  if (data_cnt_en)
    data_cnt = data_cnt + 1;
end //always@

always@(posedge p_in_clk)
begin : poll_counter
  if (rst_poll_cnt)
    poll_cnt = 24'b0;
  else
  if (poll_cnt_en)
    poll_cnt = poll_cnt + 1;
end //always@

always@(posedge p_in_clk)
begin : blk_counter
  if (rst_reg)
    blk_cnt = 9'h000;
  else
  if (load_blk_cnt)
    blk_cnt = start_blk;
  else
  if (blk_cnt_en)
    blk_cnt = blk_cnt + 1;
end //always@

always@(posedge p_in_clk)
begin : start_address_reg
  if (p_in_rst)
    start_addr_reg = 8'b0;
  else
  if (start_addr_reg_en)
    start_addr_reg = p_in_usr_txd[15+8 :8+8];
end //always@

always@(posedge p_in_clk)
begin : end_address_reg
  if (p_in_rst)
    end_addr_reg = 24'b0;
  else
  if (end_addr_reg_en)
    end_addr_reg = p_in_usr_txd[23+8 : 0+8];
end //always@

always@(posedge p_in_clk)
begin : prog_done_reg
  if (rst_reg)
    prog_done = 1'b0;
  else
  if (prog_done)
    prog_done = 1'b1;
  else
  if (end_addr_reached)
    prog_done = 1'b1;
end //always@

always@(posedge p_in_clk)
begin : address_reg
  if (rst_reg)
    A_reg = 24'b0;
  else
  if (A_reg_en)
    A_reg = A_reg + A_inc;
end //always@

always@(posedge p_in_clk)
begin : DQ_reg
  if (rst_reg)
  begin
    p_out_phy_d = 16'b0;
    p_out_phy_cs_n = 1'b1;
    p_out_phy_we_n = 1'b1;
  end
  else
  begin
    p_out_phy_d = DQ_O_reg;
    p_out_phy_cs_n = CS_N_reg;
    p_out_phy_we_n = WE_N_reg;
  end
end //always@


always@(posedge p_in_clk)
begin : byte_selector
  if (rst_reg)
  begin
    byte_sel_reg = 1'b0;
  end
  else
  if (byte_sel_en)
  begin
    byte_sel_reg = ~byte_sel_reg;
  end
end //always@

assign p_out_phy_adr=A_reg;
assign data_sel = (byte_sel_reg) ? {p_in_usr_txd[7:0],p_in_usr_txd[15:8]} : {p_in_usr_txd[23:16],p_in_usr_txd[31:24]} ; // need to do byte swap due to VisualBasic6 byte ordering
assign p_out_usr_rd = FIFO_RD_EN_reg;
assign A_inc_blk_unlk = (blk_cnt[7:0]== 8'hFF || blk_cnt[8] == 1'b1) ? `addr_increment_16kW: `addr_increment_64kW;
assign start_blk = start_addr_reg;
assign end_blk = (end_addr_reg[23:16]); //convert from word to byte
assign last_blk = (p_out_phy_adr[23:16] == end_blk ) ? 1'b1 : 1'b0;
assign start_addr = {start_addr_reg, 16'h0000};
assign end_addr = end_addr_reg; //convert from word to byte
assign end_addr_reached = (p_out_phy_adr == end_addr && (i_fsm_cs == S_PROG_CHK_DCOUNT || i_fsm_cs == S_PROG_LD_BUFFER_UNDERRUN)) ? 1'b1 : 1'b0;
assign p_out_rdy = prog_ready;
//assign PROM_SR = SR_reg;
assign p_out_status[2:0] = error_reg;
assign p_out_status[3] = i_irq_out;



//
assign p_out_tst = 0;

always@(posedge p_in_clk or posedge p_in_rst)
begin
  if (p_in_rst)
    i_irq_out <= 1'b0;
  else
    if (i_irq || error_reg_en)
      i_irq_out <= 1'b1;
    else
      if ((i_fsm_cs == S_IDLE) && (~p_in_usr_txrdy_n))
        i_irq_out <= 1'b0;

end //always@


endmodule