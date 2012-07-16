`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    08:56:04 03/12/2012
// Design Name:
// Module Name:    test_top
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module test_top(
//--------------------------------------------------
//--SATA
//--------------------------------------------------
output   [1:0]  pin_out_sata_txn      ,//output   [3:0]  pin_out_sata_txn      ,//output   [0:0]  pin_out_sata_txn      ,//
output   [1:0]  pin_out_sata_txp      ,//output   [3:0]  pin_out_sata_txp      ,//output   [0:0]  pin_out_sata_txp      ,//
input    [1:0]  pin_in_sata_rxn       ,//input    [3:0]  pin_in_sata_rxn       ,//input    [0:0]  pin_in_sata_rxn       ,//
input    [1:0]  pin_in_sata_rxp       ,//input    [3:0]  pin_in_sata_rxp       ,//input    [0:0]  pin_in_sata_rxp       ,//
input    [0:0]  pin_in_sata_clk_n     ,//input    [1:0]  pin_in_sata_clk_n     ,//input    [0:0]  pin_in_sata_clk_n     ,//
input    [0:0]  pin_in_sata_clk_p     ,//input    [1:0]  pin_in_sata_clk_p     ,//input    [0:0]  pin_in_sata_clk_p     ,//

//--------------------------------------------------
//--RAM
//--------------------------------------------------
output   [12:0] pin_out_mcb5_a        ,
output   [2:0]  pin_out_mcb5_ba       ,
output          pin_out_mcb5_ras_n    ,
output          pin_out_mcb5_cas_n    ,
output          pin_out_mcb5_we_n     ,
output          pin_out_mcb5_odt      ,
output          pin_out_mcb5_cke      ,
output          pin_out_mcb5_dm       ,
output          pin_out_mcb5_udm      ,
output          pin_out_mcb5_ck       ,
output          pin_out_mcb5_ck_n     ,
inout    [15:0] pin_inout_mcb5_dq     ,
inout           pin_inout_mcb5_udqs   ,
inout           pin_inout_mcb5_udqs_n ,
inout           pin_inout_mcb5_dqs    ,
inout           pin_inout_mcb5_dqs_n  ,
inout           pin_inout_mcb5_rzq    ,
inout           pin_inout_mcb5_zio    ,

output   [12:0] pin_out_mcb1_a        ,
output   [2:0]  pin_out_mcb1_ba       ,
output          pin_out_mcb1_ras_n    ,
output          pin_out_mcb1_cas_n    ,
output          pin_out_mcb1_we_n     ,
output          pin_out_mcb1_odt      ,
output          pin_out_mcb1_cke      ,
output          pin_out_mcb1_dm       ,
output          pin_out_mcb1_udm      ,
output          pin_out_mcb1_ck       ,
output          pin_out_mcb1_ck_n     ,
inout    [15:0] pin_inout_mcb1_dq     ,
inout           pin_inout_mcb1_udqs   ,
inout           pin_inout_mcb1_udqs_n ,
inout           pin_inout_mcb1_dqs    ,
inout           pin_inout_mcb1_dqs_n  ,
inout           pin_inout_mcb1_rzq    ,
inout           pin_inout_mcb1_zio    ,


//--------------------------------------------------
//--Технологический порт
//--------------------------------------------------
inout    [7:0] pin_inout_ftdi_d       ,
output         pin_out_ftdi_rd_n      ,
output         pin_out_ftdi_wr_n      ,
input          pin_in_ftdi_txe_n      ,
input          pin_in_ftdi_rxf_n      ,
input          pin_in_ftdi_pwren_n    ,

output   [7:0] pin_out_led            ,

    input [9:0] D0,
    input [9:0] D1,
    input [9:0] D2,
    input [9:0] D3,
    input [9:0] D4,
    input [9:0] D5,
    input [9:0] D6,
    input [9:0] D7,
    input [9:0] D8,
    input [9:0] D9,
    output [9:0] A,
//    input CALDONE,
//    input ROWDONE,
//    input CLKOUT,
    output CAL_IN,
    output LRST_IN,
    output PG_IN,
    output TX_IN,
    output CLK_IN,
    output DATA_READ_IN,
    output LD_SHIFT_IN,
    output ROW_STRT_IN,
    output DARK_OFF_IN,
    output STANDBY_IN,
    output EN,
    output TECP,
    output TECN,
    inout SDA,
    output SCL,
    output TP3_0,
    output TP3_1,
    output TP3_2,
    output TP3_3,
    output TP3_4,
    output TP3_5,
    output TP3_6,
    output TP3_7,
    output X0_P,
    output X0_N,
    output X1_P,
    output X1_N,
    output X2_P,
    output X2_N,
    output X3_P,
    output X3_N,
    output XCLK_P,
    output XCLK_N,
    input SERTC_P,
    input SERTC_N,
    output SERTFG_P,
    output SERTFG_N,
    input CC1_P,
    input CC1_N,
	 output CC4_P,
    output CC4_N,
	 input REFCLK_P,
	 input REFCLK_N
    );

wire [7:0] istat;
wire [15:0] icfg;
wire [15:0] ocfg;
wire [7:0] od0;//Видеоданные с детектора
wire [7:0] od1;
wire [7:0] od2;
wire [7:0] od3;
wire [7:0] od4;
wire [7:0] od5;
wire [7:0] od6;
wire [7:0] od7;
wire [7:0] od8;
wire [7:0] od9;
wire [15:0] idn;
wire [15:0] oregime;

//Компоненты
	gen_base u0(.CLK_IN1_P(REFCLK_P),.CLK_IN1_N(REFCLK_N),.CLK_OUT1(clk),.CLK_OUT2(CLK_OUT2));//CLK_OUT1-65.625MHz

   gen_work u1(.CLK_IN1(CLK_OUT2),.CLK_OUT1(clk1x),.CLK_OUT2(clk7x),.LOCKED(LOCKED));//CLK_OUT2-41.015625MHz


	camera camera(.D0(D0),.D1(D1),.D2(D2),.D3(D3),.D4(D4),.D5(D5),.D6(D6),.D7(D7),.D8(D8),.D9(D9),.A(A),/*.CALDONE(CALDONE),
	          .ROWDONE(ROWDONE),.CLKOUT(CLKOUT),*/.CAL_IN(CAL_IN),.LRST_IN(LRST_IN),.PG_IN(PG_IN),.TX_IN(TX_IN),.CLK_IN(CLK_IN),
				 .DATA_READ_IN(DATA_READ_IN),.LD_SHIFT_IN(LD_SHIFT_IN),.ROW_STRT_IN(ROW_STRT_IN),.DARK_OFF_IN(DARK_OFF_IN),
				 .STANDBY_IN(STANDBY_IN),.EN(EN),.TECP(TECP),.TECN(TECN),.SDA(SDA),.SCL(SCL),/*.TP3_0(TP3_0),.TP3_1(TP3_1),
				 .TP3_2(TP3_2),.TP3_3(TP3_3),.TP3_4(TP3_4),.TP3_5(TP3_5),.TP3_6(TP3_6),.TP3_7(TP3_7),*/.X0_P(X0_P),.X0_N(X0_N),
				 .X1_P(X1_P),.X1_N(X1_N),.X2_P(X2_P),.X2_N(X2_N),.X3_P(X3_P),.X3_N(X3_N),.XCLK_P(XCLK_P),.XCLK_N(XCLK_N),
				 .SERTC_P(SERTC_P),.SERTC_N(SERTC_N),.SERTFG_P(SERTFG_P),.SERTFG_N(SERTFG_N),.CC1_P(CC1_P),.CC1_N(CC1_N),
				 .CC4_P(CC4_P),.CC4_N(CC4_N),.clk(clk),.clk1x(clk1x),.clk7x(clk7x),.LOCKED(LOCKED),
				 //Накопитель
				 .rdstat(rdstat),//Чтение регистра статуса
	          .istat(istat),//Данные от регистра статуса
	          .rdcfg(rdcfg),//Чтение регистра конфигурации
	          .icfg(icfg),//Данные от регистра конфигурации
	          .wrcfg(wrcfg),//Запись в регистр конфигурации
	          .ocfg(ocfg),//Данные записываемые в регистр конфигурации
				 .oid({od9,od8,od7,od6,od5,od4,od3,od2,od1,od0}),//Видеоданные с детектора
	          .wrl(wrl),//Бланковый линии для накопителя
	          .wrf(wrf),//Бланковый кадра для накопителя
	          .idn(idn),//Данные для LVDS
	          .lval(lval),//Бланковый линии для LVDS накопителю
	          .fval(fval),//Бланковый кадра для LVDS накопителю
	          .e1sec(e1sec),//Сигнал секунды при внешней синхронизации, tv(60HZ) если нет внешней синхронизации
				 .oregime(oregime)//Регистр управления камеры
             );

//assign istat = 8'h20;
//assign icfg = 16'h52;
//assign idn = 16'h853a;


//--***********************************************************
//-- Модуль HDD:
//--***********************************************************
wire [7:0] i_out_TP; //add vicg

hdd_main m_hdd(
//--------------------------------------------------
//--VideoIN
//--------------------------------------------------
.p_in_vd             ({od9,od8,od7,od6,od5,od4,od3,od2,od1,od0}),//(i_vin_d   ),
.p_in_vin_vs         (wrf)                                      ,//(i_vin_vs  ),//--tst_in(0),--
.p_in_vin_hs         (wrl)                                      ,//(i_vin_hs  ),//--tst_in(1),--
.p_in_vin_clk        (clk)                                      ,//(i_vin_clk ),
.p_in_ext_syn        (e1sec)                                    ,//('1'       ),

//--------------------------------------------------
//--VideoOUT
//--------------------------------------------------
.p_out_vd            (idn)  ,//(i_vout_d  ),
.p_in_vout_vs        (fval) ,//(i_vout_vs ),
.p_in_vout_hs        (lval) ,//(i_vout_hs ),
.p_in_vout_clk       (clk1x),//(i_vout_clk),

//--------------------------------------------------
//--RAM
//--------------------------------------------------
.p_out_mcb5_a        (pin_out_mcb5_a       ),
.p_out_mcb5_ba       (pin_out_mcb5_ba      ),
.p_out_mcb5_ras_n    (pin_out_mcb5_ras_n   ),
.p_out_mcb5_cas_n    (pin_out_mcb5_cas_n   ),
.p_out_mcb5_we_n     (pin_out_mcb5_we_n    ),
.p_out_mcb5_odt      (pin_out_mcb5_odt     ),
.p_out_mcb5_cke      (pin_out_mcb5_cke     ),
.p_out_mcb5_dm       (pin_out_mcb5_dm      ),
.p_out_mcb5_udm      (pin_out_mcb5_udm     ),
.p_out_mcb5_ck       (pin_out_mcb5_ck      ),
.p_out_mcb5_ck_n     (pin_out_mcb5_ck_n    ),
.p_inout_mcb5_dq     (pin_inout_mcb5_dq    ),
.p_inout_mcb5_udqs   (pin_inout_mcb5_udqs  ),
.p_inout_mcb5_udqs_n (pin_inout_mcb5_udqs_n),
.p_inout_mcb5_dqs    (pin_inout_mcb5_dqs   ),
.p_inout_mcb5_dqs_n  (pin_inout_mcb5_dqs_n ),
.p_inout_mcb5_rzq    (pin_inout_mcb5_rzq   ),
.p_inout_mcb5_zio    (pin_inout_mcb5_zio   ),

.p_out_mcb1_a        (pin_out_mcb1_a       ),
.p_out_mcb1_ba       (pin_out_mcb1_ba      ),
.p_out_mcb1_ras_n    (pin_out_mcb1_ras_n   ),
.p_out_mcb1_cas_n    (pin_out_mcb1_cas_n   ),
.p_out_mcb1_we_n     (pin_out_mcb1_we_n    ),
.p_out_mcb1_odt      (pin_out_mcb1_odt     ),
.p_out_mcb1_cke      (pin_out_mcb1_cke     ),
.p_out_mcb1_dm       (pin_out_mcb1_dm      ),
.p_out_mcb1_udm      (pin_out_mcb1_udm     ),
.p_out_mcb1_ck       (pin_out_mcb1_ck      ),
.p_out_mcb1_ck_n     (pin_out_mcb1_ck_n    ),
.p_inout_mcb1_dq     (pin_inout_mcb1_dq    ),
.p_inout_mcb1_udqs   (pin_inout_mcb1_udqs  ),
.p_inout_mcb1_udqs_n (pin_inout_mcb1_udqs_n),
.p_inout_mcb1_dqs    (pin_inout_mcb1_dqs   ),
.p_inout_mcb1_dqs_n  (pin_inout_mcb1_dqs_n ),
.p_inout_mcb1_rzq    (pin_inout_mcb1_rzq   ),
.p_inout_mcb1_zio    (pin_inout_mcb1_zio   ),

//--------------------------------------------------
//--SATA Driver
//--------------------------------------------------
.p_out_sata_txn      (pin_out_sata_txn     ),
.p_out_sata_txp      (pin_out_sata_txp     ),
.p_in_sata_rxn       (pin_in_sata_rxn      ),
.p_in_sata_rxp       (pin_in_sata_rxp      ),
.p_in_sata_clk_n     (pin_in_sata_clk_n    ),
.p_in_sata_clk_p     (pin_in_sata_clk_p    ),

//-------------------------------------------------
//--Порт управления модулем + Статусы
//--------------------------------------------------
//--Управление от модуля camemra.v
.p_in_cam_ctrl       (oregime),
//--Интерфейс управления модулем
.p_in_usr_clk        (clk)  ,
.p_in_usr_tx_wr      (wrcfg),//(pin_in_SW(2)   ),
.p_in_usr_rx_rd      (rdcfg),//(pin_in_SW(3)   ),
.p_in_usr_txd        (ocfg) ,//(i_usr_txd      ),
.p_out_usr_rxd       (icfg) ,//(i_usr_rxd      ),
.p_out_usr_status    (istat),//(i_usr_status   ),

//--------------------------------------------------
//--Технологический порт
//--------------------------------------------------
.p_inout_ftdi_d      (pin_inout_ftdi_d   ),
.p_out_ftdi_rd_n     (pin_out_ftdi_rd_n  ),
.p_out_ftdi_wr_n     (pin_out_ftdi_wr_n  ),
.p_in_ftdi_txe_n     (pin_in_ftdi_txe_n  ),
.p_in_ftdi_rxf_n     (pin_in_ftdi_rxf_n  ),
.p_in_ftdi_pwren_n   (pin_in_ftdi_pwren_n),

.p_out_TP            (i_out_TP           ),
.p_out_led           (pin_out_led        )
);

assign TP3_0 = i_out_TP[0];
assign TP3_1 = i_out_TP[1];
assign TP3_2 = i_out_TP[2];
assign TP3_3 = i_out_TP[3];
assign TP3_4 = i_out_TP[4];
assign TP3_5 = i_out_TP[5];
assign TP3_6 = i_out_TP[6];
assign TP3_7 = i_out_TP[7];

endmodule
