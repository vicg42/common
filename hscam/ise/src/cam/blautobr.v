`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:18 05/13/2012 
// Design Name: 
// Module Name:    blautobr 
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
module blautobr(
    input clk,
    input init,
	 input endet,
	 input tv,
	 input [4:0] id,//—тарший разр€д четных пикселей с матрицы 
	 input extgain,
	 input extexp,
    input [10:0] ah,
    input [10:0] av,
    input [7:0] igain,
    input [10:0] iexp,    
    output reg [7:0] ogain,
    output reg [10:0] oexp
    );

reg gate;
reg [2:0] idsum;
reg [16:0] add;


always @(posedge clk)
begin gate <= (av<=769&&av>=258&&ah<=89&&ah>=40)? 1: 0;
		idsum <= id[4]+id[3]+id[2]+id[1]+id[0];
		add <=(tv)? 0: (gate)? add+idsum: add;      
		oexp <= (init||~endet)? 1: (extexp&&tv)? iexp: 
		        (tv&&add[16:12]<15&&oexp<1027)? oexp+1:
				  (tv&&add[16:12]>20&&oexp>1&&~extgain&&ogain==0)? oexp-1:
		        (tv&&add[16:12]>20&&oexp>1&&extgain)? oexp-1: oexp;
      ogain <= (init||~endet)? 0: (extgain&&tv)? igain: 
		         (tv&&add[16:12]>20&&ogain>0)? ogain-1:
					(tv&&add[16:12]<15&&ogain<255&&~extexp&&oexp==1027)? ogain+1:
		         (tv&&add[16:12]<15&&ogain<255&&extexp)? ogain+1: ogain;
end
endmodule
