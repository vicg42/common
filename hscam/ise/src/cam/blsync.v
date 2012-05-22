//Блок синхронизации
module blsync(fr,IN,clk,inv,extsyn,midsyn,iexp,ah,av,ahlvds,avlvds,th,tv,e1sec,esyn,isyn);
	 input [1:0] fr;//частота кадров: 00-60Гц; 01-120Гц; 10-240Гц; 11-480Гц
    input IN;//120 герц
    input clk;//65.625MHz
    input inv;//Инверсия внешней синхронизации
    input extsyn;//Разрешение внешней синхронизации
    input midsyn;//Привязка к середине экспозиции
    input [10:0] iexp;//Текущая экспозиция	    
    output reg [10:0] ah;//Адрес столбца
    output reg [10:0] av;//Адрес строки
	 output reg [10:0] ahlvds;//Адрес столбца для вывода в lvds
    output reg [10:0] avlvds;//Адрес строки для вывода в lvds
    output reg th;//Конец строки
    output reg tv;//Конец кадра
    output e1sec,esyn,isyn;    
//Внутренние переменные      
    wire uph;//Увеличение длительности строки +1
    wire downh;//Уменьшение длительности строки -1
    wire beginsyn;//Привязка синхронизации
    wire gate;//Ворота для строк
//Компоненты
blextsyn blextsyn(.clk(clk),.fr(fr),.inv(inv),.tv(tv),.th(th),.midsyn(midsyn),.in(IN),.ah(ah),.av(av),.iexp(iexp),.extsyn(extsyn),
                  .uph(uph),.downh(downh),.beginsyn(beginsyn),.e1sec(e1sec),.esyn(esyn),.isyn(isyn),.tv60(tv60));

always @(posedge clk)
  begin begin  tv <= (av==0&&ah==1)? 1: 0;
               th <= (ah==1)? 1: 0; 
					avlvds <= (ahlvds==0&&avlvds==0||tv60)? 1027: (ahlvds==0)? avlvds-1: avlvds;
					ahlvds <= (ahlvds==0||tv60)? 1063: ahlvds-1; end
    begin if (extsyn)
          begin if (beginsyn)
		      begin if (midsyn)
				  begin if (iexp[0]) begin av <= {1'b0,iexp[10:1]};
                          				   ah <= (fr==0)? 531: (fr==1)? 265: (fr==2)? 132: 66; end//iexp[0]==1
				                else begin av <= ({1'b0,iexp[10:1]}-1);
            									ah <= (fr==0)? 1063: (fr==1)? 531: (fr==2)? 265: 132; end//iexp[0]==0
				  end
			   	  else begin av <= 1027; 
					             ah <= (fr==0)? 1063: (fr==1)? 531: (fr==2)? 265: 132; end//endsyn
			   end
			  //Нет beginsyn
			  else begin av <= (tv&th)? 1027: (th)? av-1: av;
			             ah <= (uph&&th&&fr==0)? 1064:(uph&&th&&fr==1)? 532:(uph&&th&&fr==2)? 266:(uph&&th&&fr==3)? 133:
							       (downh&&th&&fr==0)? 1062:(downh&&th&&fr==1)? 530:(downh&&th&&fr==2)? 264:(downh&&th&&fr==3)? 131:
									 (th&&fr==0)? 1063:(th&&fr==1)? 531:(th&&fr==2)? 265:(th&&fr==3)? 132: ah-1; end//Нет beginsyn
		   end
			else begin av <= (tv&th)? 1027: (th)? av-1: av;
		 		        ah <= (th&&fr==0)? 1063:(th&&fr==1)? 531:(th&&fr==2)? 265:(th&&fr==3)? 132: ah-1; end//Нет extsyn
    end
  end
endmodule					  