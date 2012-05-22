`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:11:01 05/12/2012 
// Design Name: 
// Module Name:    bldata 
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
module bldata(
    input clk,
    input clk1x,
	 input test,
    input [10:0] ah,
    input [10:0] av,
	 input [10:0] ahlvds,
    input [10:0] avlvds,
    input [79:0] id,
    output reg [15:0] outd,//Данные для LVDS
    output reg lval,//Бланковый линии для LVDS
    output reg fval,//Бланковый кадра для LVDS
	 output reg wel,//Бланковый линии для накопителя
	 output reg wef,//Бланковый кадра для накопителя
	 output [79:0] dina
    );
	 
parameter firstpix = 126;//Первый пиксел с матрицы	 
//Компоненты

reg [6 : 0] addra,addrb;
wire [79:0] dina;
reg enb;
wire [79:0] doutb;
reg [2:0] rgmux;
reg enmux;
reg [7:0] avtest;
ramdata dual(.clka(clk),.wea(wel),.addra(addra),.dina(dina),.clkb(clk1x),.enb(enb),.addrb(addrb),.doutb(doutb));

assign dina = (test&&av<515)?{avtest,avtest,avtest,avtest,avtest,avtest,avtest,avtest,avtest,avtest}: 
              (test&&av>=515)?{addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0,addra,1'b0}:
							id;

always @(posedge clk)
begin wel <= (ah==firstpix&&av<=1026&&av>=3)? 1: (addra==127)? 0: wel;
		addra <= (addra==127||~wel)? 0: addra+1;
		wef <= (ah==firstpix&&av==1026)? 1: (addra==127&&av==3)? 0: wef;
		avtest <= (av<=1||av>1026)? 0: (addra==127)? avtest+1: avtest;
end

always @(posedge clk1x)
begin enb <= (ahlvds==1061||ahlvds==1060)? 1: (addrb==127&&rgmux==3)? 0: enb;
		addrb <= (~enb||(addrb==127&&rgmux==3))? 0: (rgmux==3)? addrb+1: addrb;
		enmux <= (enb&&avlvds<=1025&&avlvds>=2)? 1: 0;
		rgmux <= (~enmux||rgmux==4)? 0: rgmux+1;
		outd <= (rgmux==0)? doutb[15:0]: (rgmux==1)? doutb[31:16]: (rgmux==2)? doutb[47:32]: (rgmux==3)? doutb[63:48]: doutb[79:64];
		lval <= (enmux&&avlvds<=1025&&avlvds>=1)? 1: 0;
		fval <= (avlvds==1025&&enmux==1&&lval==0)? 1: (avlvds==2&&enmux==0&&lval==1)? 0: fval;
end
endmodule
