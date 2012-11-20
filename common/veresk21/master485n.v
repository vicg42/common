`timescale 1ns / 1ps
//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    :
//--
//-- Create Date : 16.11.2012 8:55:58
//-- Module Name :
//--
//-- Назначение/Описание :
//--  Обмен - запрос/ответ
//--           -----------------------------------------------------------------
//--             Byte0                 | Byte1               |  Byte2           |... ByteN
//--           -----------------------------------------------------------------
//--  Request: SOF+DEV_ADR[7:0]+Parity | DEV_CMD[7:0]+Parity | DATA[7:0]+Parity |...
//--           -----------------------------------------------------------------
//--  ACK    : SOF+DEV_ADR[7:0]+Parity | DEV_CMD[7:0]+Parity | DATA[7:0]+Parity |...
//--           -----------------------------------------------------------------
//--  + Манчестер!!! + первый бит в байте приема/передачи = Bit[7]!!!
//--  Кол-во передоваемых/принимаемых байт зависит от команды(т.е. !const)!!!
//------------------------------------------------------------------------------
module master485n(
input            p_in_phy_rx,  //FPGA<-PHY
output reg       p_out_phy_tx, //FPGA->PHY
output reg       p_out_phy_dir,

input            p_in_txd_rdy,
input [7:0]      p_in_txd,     //FPGA->PHY
output           p_out_txd_rd,

output reg [7:0] p_out_rxd,    //FPGA<-PHY
output           p_out_rxd_wr,

output reg [2:0] p_out_status, //статус модуля

input  [31:0]    p_in_tst,
output [31:0]    p_out_tst,

input p_in_bitclk, //Выбор baudrate: 1/0 - 1MHz/250kHz
input p_in_clk,    //128MHz!!!!!
input p_in_rst
);

//MAIN

parameter CI_PHY_DIR_RX=0; //FPGA<-PHY
parameter CI_PHY_DIR_TX=1; //FPGA->PHY

parameter [2:0] CI_STATUS_RX_OK=3'h01;
parameter [2:0] CI_STATUS_RX_ERR=3'h02; //Ошибка четности

parameter S_TX_WAIT=0;
parameter S_TX_0=1;
parameter S_TX_1=2;
parameter S_TX_DONE=3;
parameter S_RX_WAIT=4;
parameter S_RX_0=5;
parameter S_RX_1=6;
parameter S_RX_2=7;
parameter S_RX_DONE=8;
parameter S_RX_DONE2=9;

reg [3:0] i_fsm_cs;
reg [5:0] i_clkx4_cnt;

reg [0:1] sr_phy_rx;
reg i_rxd_wr;
reg i_txd_rd;
reg i_rcv_err;

reg i_parity;
reg i_rcv_detect;
reg i_clk4x_en;
reg [6:0] i_clkdiv_cnt;
reg i_clkdiv_rst;


assign p_out_tst[3:0] = i_fsm_cs;
assign p_out_tst[4] = i_clk4x_en;
assign p_out_tst[5] = 0;

assign p_out_rxd_wr = i_rxd_wr && i_clk4x_en;
assign p_out_txd_rd = i_txd_rd && i_clk4x_en;

//входной сдвиговый регистр + детектор приема данных
always @(posedge p_in_rst, posedge p_in_clk)
begin
  if (p_in_rst) begin
    sr_phy_rx <= 0;
    i_rcv_detect <= 0;
  end
  else begin
    sr_phy_rx <= {p_in_phy_rx, sr_phy_rx[0:0]};

    if (p_out_phy_dir == CI_PHY_DIR_RX) begin
      if (!sr_phy_rx[0] && sr_phy_rx[1])
        i_rcv_detect <= 1;
    end
    else begin
      i_rcv_detect <= 0;
    end
  end
end //always @


//Делитель частоты
always @(posedge p_in_rst, posedge p_in_clk)
begin
  if (p_in_rst) begin
    i_clkdiv_cnt <= 0;
    i_clk4x_en <= 0;
  end
  else begin

      if (i_clkdiv_rst) begin
        i_clkdiv_cnt <= 0;
        i_clk4x_en <= 0;
      end
      else begin
          //В случае Манчестерского кодирования
          //при приеме данных производим подсинхривание
          //счетчика i_clkdiv_cnt передним/задним фронтами сингала p_in_phy_rx
          //(выделение фронтов - (^sr_phy_rx))
          if ( (p_out_phy_dir==CI_PHY_DIR_RX) &&
               ((^sr_phy_rx) || !i_rcv_detect) )
            i_clkdiv_cnt <= 0;
          else
            i_clkdiv_cnt <= i_clkdiv_cnt + 1;

          if ( ((i_clkdiv_cnt[4:0] == 5'h10) && p_in_bitclk) ||
               ((i_clkdiv_cnt[6:0] == 7'h40) && !p_in_bitclk) )
            i_clk4x_en <= 1;
          else
            i_clk4x_en <= 0;

      end

  end
end //always @


//FSM обмена данными
always @(posedge p_in_rst, posedge p_in_clk)
begin
  if (p_in_rst) begin
    i_fsm_cs <= S_TX_WAIT;
    i_clkx4_cnt <= 0;
    i_parity <= 0;
    i_txd_rd <= 0;
    i_rxd_wr <= 0;
    i_rcv_err <= 0;
    p_out_phy_tx <= 1;
    p_out_phy_dir <= CI_PHY_DIR_RX;
    p_out_status <= 0;
    i_clkdiv_rst <= 0;
  end
  else begin
      case (i_fsm_cs)

          S_TX_WAIT:
            begin

                if (p_in_txd_rdy) begin
                  i_clkdiv_rst <= 0;
                  p_out_status <= 0;
                  p_out_phy_dir <= CI_PHY_DIR_TX;
                  i_fsm_cs <= S_TX_0;
                end

            end //S_TX_WAIT

          S_TX_0:
            begin
              if (i_clk4x_en) begin
                if (i_clkx4_cnt == 39)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case (i_clkx4_cnt)
                  //Старт бит
                  0,1:   begin p_out_phy_tx <= 1; end
                  2,3:   begin p_out_phy_tx <= 0; end
                  //Данные
                  4,5:   begin p_out_phy_tx <= !p_in_txd[7]; end
                  6,7:   begin p_out_phy_tx <=  p_in_txd[7]; end
                  8,9:   begin p_out_phy_tx <= !p_in_txd[6]; end
                  10,11: begin p_out_phy_tx <=  p_in_txd[6]; end
                  12,13: begin p_out_phy_tx <= !p_in_txd[5]; end
                  14,15: begin p_out_phy_tx <=  p_in_txd[5]; end
                  16,17: begin p_out_phy_tx <= !p_in_txd[4]; end
                  18,19: begin p_out_phy_tx <=  p_in_txd[4]; end
                  20,21: begin p_out_phy_tx <= !p_in_txd[3]; end
                  22,23: begin p_out_phy_tx <=  p_in_txd[3]; end
                  24,25: begin p_out_phy_tx <= !p_in_txd[2]; end
                  26,27: begin p_out_phy_tx <=  p_in_txd[2]; end
                  28,29: begin p_out_phy_tx <= !p_in_txd[1]; end
                  30,31: begin p_out_phy_tx <=  p_in_txd[1]; end
                  32,33: begin p_out_phy_tx <= !p_in_txd[0]; end
                  34,35: begin p_out_phy_tx <=  p_in_txd[0]; i_parity <= ^p_in_txd[7:0]; end
                  //бит четности
                  36:    begin p_out_phy_tx <= !i_parity; end
                  37:    begin p_out_phy_tx <= !i_parity; i_txd_rd <= 1; end
                  38:    begin p_out_phy_tx <=  i_parity; i_txd_rd <= 0; end
                  39:    begin p_out_phy_tx <=  i_parity;
                           if ( !p_in_txd_rdy )
                             i_fsm_cs <= S_TX_DONE;
                           else
                             i_fsm_cs <= S_TX_1;
                         end
                endcase
              end
            end //S_TX_0

          S_TX_1:
            begin
              if (i_clk4x_en) begin
                if (i_clkx4_cnt == 35)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case (i_clkx4_cnt)
                  //Старт бит - Нету!!!!
                  //Данные
                  0,1:   begin p_out_phy_tx <= !p_in_txd[7]; end
                  2,3:   begin p_out_phy_tx <=  p_in_txd[7]; end
                  4,5:   begin p_out_phy_tx <= !p_in_txd[6]; end
                  6,7:   begin p_out_phy_tx <=  p_in_txd[6]; end
                  8,9:   begin p_out_phy_tx <= !p_in_txd[5]; end
                  10,11: begin p_out_phy_tx <=  p_in_txd[5]; end
                  12,13: begin p_out_phy_tx <= !p_in_txd[4]; end
                  14,15: begin p_out_phy_tx <=  p_in_txd[4]; end
                  16,17: begin p_out_phy_tx <= !p_in_txd[3]; end
                  18,19: begin p_out_phy_tx <=  p_in_txd[3]; end
                  20,21: begin p_out_phy_tx <= !p_in_txd[2]; end
                  22,23: begin p_out_phy_tx <=  p_in_txd[2]; end
                  24,25: begin p_out_phy_tx <= !p_in_txd[1]; end
                  26,27: begin p_out_phy_tx <=  p_in_txd[1]; end
                  28,29: begin p_out_phy_tx <= !p_in_txd[0]; end
                  30,31: begin p_out_phy_tx <=  p_in_txd[0]; i_parity <= ^p_in_txd[7:0]; end
                  //Бит четности
                  32:    begin p_out_phy_tx <= !i_parity; end
                  33:    begin p_out_phy_tx <= !i_parity; i_txd_rd <= 1; end
                  34:    begin p_out_phy_tx <=  i_parity; i_txd_rd <= 0; end
                  35:    begin p_out_phy_tx <=  i_parity;
                           if ( !p_in_txd_rdy )
                             i_fsm_cs <= S_TX_DONE;
                         end
                endcase
              end
            end //S_TX_1

          S_TX_DONE:
            begin
              if (i_clk4x_en) begin
                p_out_phy_tx <= 1;

                if (i_clkx4_cnt == 3) begin
                  i_clkdiv_rst <= 1;
                  i_clkx4_cnt <= 0;
                  p_out_phy_dir <= CI_PHY_DIR_RX;
                  i_fsm_cs <= S_RX_WAIT;
                end
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;
              end
            end //S_TX_DONE


          S_RX_WAIT:
            begin

              i_clkdiv_rst <= 0;

              if (i_rcv_detect) begin
                if (i_clk4x_en) begin
                  i_fsm_cs <= S_RX_0;
                  i_clkx4_cnt <= 0;
                end
              end
              else begin
                  if (p_in_txd_rdy)
                    i_fsm_cs <= S_TX_WAIT;
              end
            end //S_RX_WAIT

          S_RX_0:
            begin
              if (i_clk4x_en) begin
                if (i_clkx4_cnt == 36)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case (i_clkx4_cnt)
                  //Старт бит - пропускаем
//                  0,1,2:   p_out_rxd[7] <= sr_phy_rx[0];
                  //Данные
                  3:  begin p_out_rxd[7] <= sr_phy_rx[0]; end //4,5,6
                  7:  begin p_out_rxd[6] <= sr_phy_rx[0]; end //8,9,10
                  11: begin p_out_rxd[5] <= sr_phy_rx[0]; end //12,13,14
                  15: begin p_out_rxd[4] <= sr_phy_rx[0]; end //16,17,18
                  19: begin p_out_rxd[3] <= sr_phy_rx[0]; end //20,21,22
                  23: begin p_out_rxd[2] <= sr_phy_rx[0]; end //24,25,26
                  27: begin p_out_rxd[1] <= sr_phy_rx[0]; end //28,29,30
                  31: begin p_out_rxd[0] <= sr_phy_rx[0]; end //32,33,34
                  //Бит четности
                  35: begin
                        if (^p_out_rxd[7:0] != sr_phy_rx[0]) begin
                          i_rcv_err <= 1;
                          i_fsm_cs <= S_RX_DONE;
                        end
                        else
                          i_rxd_wr <= 1;
                      end
                  36: begin
                        i_rxd_wr <= 0;
                        i_fsm_cs <= S_RX_1;
                      end
                endcase
              end
            end //S_RX_0

          S_RX_1:
            begin
              if (i_clk4x_en) begin
                if (i_clkx4_cnt == 36)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case (i_clkx4_cnt)
                  //Старт бит - Нету!!!
                  //Данные
                  0:  begin p_out_rxd[7] <= sr_phy_rx[0]; end //сохраняем уровень линии для проверки
                                                              //наличия следующего байта
                  2:  begin
                        if (p_out_rxd[7] && sr_phy_rx[0]) begin
                          i_fsm_cs <= S_RX_DONE;
                        end
                      end
                  3:  begin p_out_rxd[7] <= sr_phy_rx[0]; end
                  7:  begin p_out_rxd[6] <= sr_phy_rx[0]; end
                  11: begin p_out_rxd[5] <= sr_phy_rx[0]; end
                  15: begin p_out_rxd[4] <= sr_phy_rx[0]; end
                  19: begin p_out_rxd[3] <= sr_phy_rx[0]; end
                  23: begin p_out_rxd[2] <= sr_phy_rx[0]; end
                  27: begin p_out_rxd[1] <= sr_phy_rx[0]; end
                  31: begin p_out_rxd[0] <= sr_phy_rx[0]; end
                  //Бит четности
                  35: begin
                      if (^p_out_rxd[7:0] != sr_phy_rx[0]) begin
                        i_rcv_err <= 1;
                        i_fsm_cs <= S_RX_DONE;
                      end
                      else
                        i_rxd_wr <= 1;
                     end
                  36: begin
                        i_rxd_wr <= 0;
                        p_out_rxd[7] <= sr_phy_rx[0]; //сохраняем уровень линии для проверки
                                                      //наличия следующего байта
                        i_fsm_cs <= S_RX_2;
                      end
                endcase
              end
            end //S_RX_1

          S_RX_2:
            begin
              if (i_clk4x_en) begin
                if (i_clkx4_cnt == 34)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case (i_clkx4_cnt)
                  //Старт бит - Нету!!!
                  //Данные
                  1:  begin
                        if (p_out_rxd[7] != sr_phy_rx[0])
                          p_out_rxd[7] <= sr_phy_rx[0];
                        else begin
                          i_fsm_cs <= S_RX_DONE;
                        end
                      end
                  5:  begin p_out_rxd[6] <= sr_phy_rx[0]; end
                  9:  begin p_out_rxd[5] <= sr_phy_rx[0]; end
                  13: begin p_out_rxd[4] <= sr_phy_rx[0]; end
                  17: begin p_out_rxd[3] <= sr_phy_rx[0]; end
                  21: begin p_out_rxd[2] <= sr_phy_rx[0]; end
                  25: begin p_out_rxd[1] <= sr_phy_rx[0]; end
                  29: begin p_out_rxd[0] <= sr_phy_rx[0]; end
                  //Бит четности
                  33: begin
                      if (^p_out_rxd[7:0] != sr_phy_rx[0]) begin
                        i_rcv_err <= 1;
                        i_fsm_cs <= S_RX_DONE;
                      end
                      else
                        i_rxd_wr <= 1;
                      end
                  34: begin
                        i_rxd_wr <= 0;
                        p_out_rxd[7] <= sr_phy_rx[0]; //сохраняем уровень линии для проверки
                                                      //наличия следующего байта
                        i_fsm_cs <= S_RX_1;
                      end
                endcase
              end
            end //S_RX_2

          S_RX_DONE:
            begin
              if (i_clk4x_en) begin
                i_clkx4_cnt <= 0;
                i_txd_rd <= 0;
                i_rxd_wr <= 0;
                p_out_phy_tx <= 1;
                p_out_phy_dir <= CI_PHY_DIR_RX;
                i_rcv_err <= 0;
                if (i_rcv_err)
                  p_out_status <= CI_STATUS_RX_ERR;
                else
                  p_out_status <= CI_STATUS_RX_OK;

                i_fsm_cs <= S_RX_DONE2; //S_TX_WAIT;
              end
            end //S_RX_DONE

          S_RX_DONE2:
            begin
              if (i_clk4x_en) begin
                i_clkdiv_rst <= 1;
                i_fsm_cs <= S_TX_WAIT;
              end
            end //S_RX_DONE2
      endcase
  end
end //always @


endmodule
