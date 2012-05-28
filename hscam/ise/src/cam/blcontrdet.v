`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:18:21 05/12/2012 
// Design Name: 
// Module Name:    blcontrdet 
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
module blcontrdet(
    input clk,
    input endet,//Разрешение по температуре
	 input resdet,
    input [10:0] ah,
    input [10:0] av,
	 input [10:0] iexp,
    input korr,//Запуск калибровки АЦП детектора
    output reg [9:0] arow,//Адрес строки считываемой из детектора
    output reg rstrt,//Старт преобразования АЦП строки
    output reg ldshft,//Ноль размещает данные на выходах детектора
    output reg enrd,//Ноль разрешает обновление данных на выходах детектора по переднему фронту clk
    output ipg,//Ноль сбрасывает все пикселы детектора
    output reg itx,//Ноль переносит заряд пикселов во внутреннюю память детектора
	 output reg lrst,//Глобальный логический сброс(асинхронный) детектора
	 output reg oint//Экспозиция
    );
//Компоненты
reg pg1,pg2;

assign ipg = (pg1&pg2);

always @(posedge clk)
  begin if (~endet) begin arow <= 0; rstrt <= 0; ldshft <= 0; enrd <= 0; pg1 <= 0; pg2 <= 0; itx <= 0; lrst <= 0; end
        else begin lrst <= (korr||resdet)? 0: 1;
						 arow <= (av<=2&&ah==0)? 0: (ah==0)? arow+1: arow;
						 rstrt <= (av>2&&ah==129)? 0: (ah==127)? 1: rstrt;
						 ldshft <= (ah==131)? 0: (ah==0)? 1: ldshft;
						 enrd <= (ah==131)? 0: (ah==0)? 1: enrd;
						 pg1 <= (av>iexp&&ah==1)? 0: 1;
						 pg2 <= (av==iexp&&ah<=65&&ah>1)? 0: 1;
						 itx <= (av==0&&ah<=65&&ah>1)? 0: 1;
						 oint <= (av==iexp&&ah==1)? 1:(av==0&&ah==1)? 0: oint;	
				 end
  end
endmodule
