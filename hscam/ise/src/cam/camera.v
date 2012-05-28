module camera(
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
    output reg [9:0] A,
//    input CALDONE,
//    input ROWDONE,
//    input CLKOUT,
    output CAL_IN,
    output reg LRST_IN,
    output reg PG_IN,
    output reg TX_IN,
    output CLK_IN,
    output reg DATA_READ_IN,
    output reg LD_SHIFT_IN,
    output reg ROW_STRT_IN,
    output DARK_OFF_IN,
    output STANDBY_IN,
    output reg EN,
    output reg TECP,
    output reg TECN,
    inout SDA,
    output SCL,
    output TP3_0,
    output reg TP3_1,
    output reg TP3_2,
    output reg TP3_3,
    output reg TP3_4,
    output reg TP3_5,
    output reg TP3_6,
    output reg TP3_7,
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
	 input clk,
	 input clk1x,
	 input clk7x,
	 input LOCKED,
//	 input REFCLK_P,//125MHz
//	 input REFCLK_N,
//Накопитель
	 output rdstat,//Чтение регистра статуса
	 input [7:0] istat,//Данные регистра статуса
	 output rdcfg,//Чтение регистра конфигурации
	 input [15:0] icfg,//Данные от регистра конфигурации
	 output wrcfg,//Запись в регистр конфигурации
	 output [15:0] ocfg,//Данные записываемые в регистр конфигурации
	 output reg [79:0] oid,//Видеоданные с детектора	 
	 output reg wrl,//Бланковый линии для накопителя
	 output reg wrf,//Бланковый кадра для накопителя
	 input [15:0] idn,//Данные для LVDS
	 output lval,//Бланковый линии для LVDS накопителю
	 output fval,//Бланковый кадра для LVDS накопителю
	 output e1sec//Сигнал секунды при внешней синхронизации, tv(60HZ) если нет внешней синхронизации
//    output clkn,//Частота для накопителя при записи
//	 output clklvds//Частота чтения для вывода в LVDS
	 );
//Переменные
wire [7:0] igain;
wire [10:0] iexp,oexp;
wire [9:0] itemp;
wire [9:0] oregime;
wire [7:0] ogain;
wire [7:0] oneg,opos,ocompen;
wire [3:0] testser;
reg [9:0] id0,id1,id2,id3,id4,id5,id6,id7,id8,id9;
//reg [7:0] od0,od1,od2,od3,od4,od5,od6,od7,od8,od9;
reg init;
reg [3:0] cbinitframe;//Счетчик инициализации
wire [9:0] arow;
wire [15:0] outd;
wire [10:0] ah,av,ahlvds,avlvds;
reg [27:0] d;
reg [6:0]cbtest;
reg [7:0] od9,od8,od7,od6,od5,od4,od3,od2,od1,od0;
wire [79:0] dina;
//Имитация 120Гц
reg [19:0] cbpix120hz;
reg [10:0] cb10us;
reg [7:0] cb120hz;
reg out120hz;
reg in120hz;
wire [2:0] otestextsyn;
  
//Компоненты
blsync u2(.fr(oregime[1:0]),.IN(in120hz),.clk(clk),.inv(oregime[6]),.extsyn(oregime[2]),.midsyn(oregime[3]),.iexp(iexp),
          .ah(ah),.av(av),.ahlvds(ahlvds),.avlvds(avlvds),.th(th),.tv(tv),.e1sec(e1sec),.esyn(esyn),.isyn(isyn),.otest(otestsyn),
			 .otestextsyn(otestextsyn));

blextcontr u3(.RCIN(RC_IN),.clk(clk),.init(init),.endet(endet),.igain(igain),.iexp(iexp),.itemp(itemp),.rdstat(rdstat),.istat(istat),
              .rdcfg(rdcfg),.icfg(icfg),.RCOUT(RC_OUT),.oregime(oregime),.ogain(ogain),.oexp(oexp),.oneg(oneg),.opos(opos),
				  .ocompen(ocompen),.korr(korr),.wrcfg(wrcfg),.ocfg(ocfg),.testser(testser));

bli2c u4(.clk(clk),.init(init),.tv(tv),.fr(oregime[1:0]),.igain(igain[5:0]),.oneg(ocompen),.opos(opos),.ocompen(oneg),
         .sda(SDA),.scl(SCL),.endet(endet),.tecp(itecp),.tecn(itecn),.in(insda),.resdet(resdet),.itemp(itemp),.otest(otesti2c));

blcontrdet u5(.clk(clk),.endet(endet),.ah(ah),.av(av),.iexp(iexp),.korr(korr),.arow(arow),.rstrt(rstrt),.ldshft(ldshft),.resdet(resdet),
				  .enrd(enrd),.ipg(ipg),.itx(itx),.lrst(lrst),.oint(oint));

bldata u6(.clk(clk),.clk1x(clk1x),.test(oregime[7]),.ah(ah),.av(av),.id({od9,od8,od7,od6,od5,od4,od3,od2,od1,od0}),
          .ahlvds(ahlvds),.avlvds(avlvds),.outd(outd),.lval(lval),.fval(fval),.wel(wel),.wef(wef),.dina(dina));				  

ser1 u7(.DATA_OUT_FROM_DEVICE({d[27],d[19],d[08],d[00],
									    d[05],d[20],d[09],d[01],
									    d[10],d[21],d[12],d[02],
									    d[11],d[22],d[13],d[03],
									    d[16],d[24],d[14],d[04],
	                            d[17],d[25],d[15],d[06],
	                            d[23],d[26],d[18],d[07]}),
        .DATA_OUT_TO_PINS_P({X3_P,X2_P,X1_P,X0_P}),
        .DATA_OUT_TO_PINS_N({X3_N,X2_N,X1_N,X0_N}),
        .CLK_TO_PINS_P(XCLK_P),
        .CLK_TO_PINS_N(XCLK_N),
        .CLK_IN(clk7x),        // Fast clock input from PLL/MMCM
        .CLK_DIV_IN(clk1x),    // Slow clock input from PLL/MMCM
        .LOCKED_IN(LOCKED),
        .LOCKED_OUT(LOCKED_OUT),
        .CLK_RESET(init),
        .IO_RESET(init));

blautobr u8(.clk(clk),.init(init),.endet(endet),.tv(tv),.id({od8[7],od6[7],od4[7],od2[7],od0[7]}),
            .extgain(oregime[5]),.extexp(oregime[4]),.ah(ah),.av(av),.igain(ogain),.iexp(oexp),.ogain(igain),.oexp(iexp));

//IBUFGDS #(.DIFF_TERM("TRUE"),.IOSTANDARD("LVDS_33")) u9(.O(iclk),.I(REFCLK_P),.IB(REFCLK_N));

OBUFDS #(.IOSTANDARD ("LVDS_33")) u10(.O(SERTFG_P),.OB(SERTFG_N),.I(~RC_OUT));

OBUFDS #(.IOSTANDARD ("LVDS_33")) u11(.O(CC4_P),.OB(CC4_N),.I(oint));

IBUFDS #(.DIFF_TERM("TRUE"),.IOSTANDARD("LVDS_33")) u12(.O(RC_IN),.I(SERTC_P),.IB(SERTC_N));

IBUFDS #(.DIFF_TERM("TRUE"),.IOSTANDARD("LVDS_33")) u13(.O(IN),.I(CC1_P),.IB(CC1_N));

assign CLK_IN = (~endet)? 0: ~clk;
assign clkn = clk;
assign clklvds = clk1x;
assign DARK_OFF_IN = oregime[8];
assign STANDBY_IN = endet;
assign CAL_IN = endet;
assign TP3_0 = clk;//1 
always @(posedge clk)
begin init <= (cbinitframe<2)? 1: (cbinitframe>9)? 0: init;
		cbinitframe <= (tv&&cbinitframe<12)? cbinitframe+1: cbinitframe;
		id0 <= D0; id1 <= D1; id2 <=D2; id3 <= D3; id4 <= D4; id5 <= D5; id6 <= D6; id7 <= D7; id8 <= D8; id9 <= D9;
		od0 <= (igain[7:6]==0)? id0[9:2]: (igain[7:6]==1&&id0[9])? 255: (igain[7:6]==1)? id0[8:1]: (id0[9:8]>0)? 255: id0[7:0];
		od1 <= (igain[7:6]==0)? id1[9:2]: (igain[7:6]==1&&id1[9])? 255: (igain[7:6]==1)? id1[8:1]: (id1[9:8]>0)? 255: id1[7:0];
		od2 <= (igain[7:6]==0)? id2[9:2]: (igain[7:6]==1&&id2[9])? 255: (igain[7:6]==1)? id2[8:1]: (id2[9:8]>0)? 255: id2[7:0];
	   od3 <= (igain[7:6]==0)? id3[9:2]: (igain[7:6]==1&&id3[9])? 255: (igain[7:6]==1)? id3[8:1]: (id3[9:8]>0)? 255: id3[7:0];
		od4 <= (igain[7:6]==0)? id4[9:2]: (igain[7:6]==1&&id4[9])? 255: (igain[7:6]==1)? id4[8:1]: (id4[9:8]>0)? 255: id4[7:0];
	   od5 <= (igain[7:6]==0)? id5[9:2]: (igain[7:6]==1&&id5[9])? 255: (igain[7:6]==1)? id5[8:1]: (id5[9:8]>0)? 255: id5[7:0];
      od6 <= (igain[7:6]==0)? id6[9:2]: (igain[7:6]==1&&id6[9])? 255: (igain[7:6]==1)? id6[8:1]: (id6[9:8]>0)? 255: id6[7:0];
      od7 <= (igain[7:6]==0)? id7[9:2]: (igain[7:6]==1&&id7[9])? 255: (igain[7:6]==1)? id7[8:1]: (id7[9:8]>0)? 255: id7[7:0];
      od8 <= (igain[7:6]==0)? id8[9:2]: (igain[7:6]==1&&id8[9])? 255: (igain[7:6]==1)? id8[8:1]: (id8[9:8]>0)? 255: id8[7:0];
      od9 <= (igain[7:6]==0)? id9[9:2]: (igain[7:6]==1&&id9[9])? 255: (igain[7:6]==1)? id9[8:1]: (id9[9:8]>0)? 255: id9[7:0];
      oid <= dina; wrl <= wel;	wrf <= wef;
		A <= arow; ROW_STRT_IN <= rstrt; LD_SHIFT_IN <= ldshft; DATA_READ_IN <= enrd; 
		PG_IN <= ipg; TX_IN <= itx; LRST_IN <= lrst; EN <= endet;
//		d <= {outd[6],ihs,ovb,ohb,ivs,16'h0,outd[5],outd[7],outd[4:0]};
		d <= (oregime[1:0]!=0||oregime[9]==1)? {idn[6],1'h0,fval,lval,9'h0,idn[13:11],idn[15:14],idn[10:8],idn[5],idn[7],idn[4:0]}:
		     {outd[6],1'h0,fval,lval,9'h0,outd[13:11],outd[15:14],outd[10:8],outd[5],outd[7],outd[4:0]};
//_______________27__26__25 ___24 _23:15_____14:12_______11:10________9:7_______6_______5_______4:0
//Чтение из памяти и передача в LVDS младший байт младший пиксел старший байт-старший
      TECP <= itecp; TECN <= itecn;
		in120hz <= (oregime[7])? out120hz: IN;
		cbpix120hz <= (cbpix120hz==546874)? 0: cbpix120hz+1;
		cb120hz <= (cbpix120hz==546874&&cb120hz==119)? 0: (cbpix120hz==546874)? cb120hz+1: cb120hz;
		cb10us <= (~out120hz||(cb120hz==119&&cb10us==656)||(cb120hz!=119&&cb10us==328))? 0: cb10us+1;
		out120hz <= (cbpix120hz==546874)? 1: ((cb120hz==119&&cb10us==656)||(cb120hz!=119&&cb10us==328))? 0: out120hz;
		
      TP3_1 <= endet;//2 downh
		TP3_2 <= ipg;//3 err
		TP3_3 <= itecp;//4 frame
		TP3_4 <= isyn;//5
		TP3_5 <= esyn;//6
		TP3_6 <= otestsyn;//7
		TP3_7 <= oint;//8
end  
endmodule
