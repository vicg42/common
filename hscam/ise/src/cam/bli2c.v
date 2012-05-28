module bli2c(
    input clk,
    input init,
	 input tv,
	 input [1:0] fr,
    input [5:0] igain,
    input [7:0] oneg,
    input [7:0] opos,
    input [7:0] ocompen,
    inout sda,
    output reg scl,
    output reg endet,
	 output reg tecp,
	 output reg tecn,
	 output reg in,
	 output reg resdet,
	 output reg [9:0] itemp,
	 output reg otest	
    );
//FSM i2c
    parameter s_wait = 0;//Ожидание tv или tvt
    parameter s_start = 1;//Пуск 
	 parameter s_receive = 2;//Прием данных от термометра(8бит передача 16 бит прием), ответ мастера
    parameter s_trans = 3;//Передача 24 битов,проверка ответа(нет то ошибка)
    parameter s_stop = 4;//Отработка стопа
	 parameter s_pause = 5;//Пауза между обменами с внешними успройствами	
    parameter s_err = 6;//Обнуление всех счетчиков и переход на сброс
//FSM анализа температуры	 
    parameter t_wait = 0;//Ожидание разрешения начала измерения температуры для TEC
	 parameter t_mes1 = 1;//1-ое измерение(8192)
	 parameter t_mes2 = 2;//2-ое измерение(4096)
	 parameter t_mes3 = 3;//3-ое измерение(2048)
	 parameter t_mes4 = 4;//4-ое измерение(1024)
	 parameter t_mes5 = 5;//5-ое измерение(512)
	 parameter t_mes6 = 6;//6-ое измерение(256)
	 parameter t_mes = 7;//Постоянное измерение(64)
	 
	 parameter tmin = 991;//Ниже этой(-8(991))температуры детектор выключается t=tx4+512(для отриц. темпер.)
	 parameter tmax = 300;//Выше этой(+75(300))температуры детектор выключается t=tx4(для полож. темпер.
//Внутренние переменные
	 reg [2:0] statet;//FSM анализа температуры
    reg [2:0] state;//FSM i2c 
    reg [7:0] cbsync;//Счетчик импульсов    
	 reg [4:0] cbbit;//Счетчик битов
	 reg [3:0] cbdata;//Счетчик обменов с внешними успройствами
    reg [27:0] odata;//Передаваемые сдвигаемые данные   
    reg [9:0] idata;//Принимаемые данные
//    reg in;//Входной регистр sda
    reg ent;//Разрешает измерение температуры
	 reg [9:0] cbtv;//Счетчик интервала между измерениями температуры
	 reg zsda;//Переключение sda в третье состояние(прием данных от внешних устройств)
	 reg od;
	 reg [9:0] iitemp;//Предыдущее значение температуры
	 reg imes,mes;//Измерения температуры для TEC
	 reg [5:0] cbmes;//Счетчик  времени измерения температуры для TEC max=128
	 reg [13:0] cbtec;//ШИМ для TEC
	 reg [13:0] entec;//Точка включения TEC
	 reg iresdet,iiresdet;
	 
assign sda = (zsda)? 1'bz: od;
assign tw = (itemp<1023&&itemp>512)? 1: 0;//Увеличить нагрев, если меньше 0 градусов
assign tc = (itemp>0&&itemp<511)? 1: 0;//Уменьшить нагрев, если больще 0 градусов
//assign tw = (itemp<240)? 1: 0;//<60
//assign tc = (itemp>=240)? 1: 0;//>60

always @(posedge clk)
begin if (init) begin scl <= 1; endet <= 0; tecp <= 0; tecn <= 0; state <= s_wait; cbsync <= 0; 
                      cbbit <= 0; od <= 1; zsda <= 0; cbdata <= 0; ent <= 0; cbtv <= 0; itemp <= 10'h3ff;
							 cbmes <= 0; cbtec <=0; entec <=0; statet <= t_wait; iresdet <= 0; resdet <= 0; end
  
  else begin begin in <= sda;
                   iresdet <= (endet&&mes&&iresdet==0)? 1: iresdet; iiresdet <= (endet&&mes&&iresdet==0)? 1: 0;
						 resdet <= (endet&&mes&&iresdet==0||iiresdet)? 1: 0;
                   cbtv <= (ent)? 0: (tv)? cbtv+1: cbtv;
						 ent <= ((fr==0&&cbtv==60)||(fr==1&&cbtv==120)||(fr==2&&cbtv==240)||(fr==3&&cbtv==480))? 1:
							     (state==s_receive)? 0: ent;//измерение температуры раз в 1сек 
						 cbtec <= (cbtec==0)? 16383: cbtec-1;
						 tecp <= (cbtec==0||itemp>tmax-20)? 0: (cbtec==entec)? 1: tecp; tecn<= 1'b0; 
						 imes <= (state==s_receive&&cbbit==28&&cbsync==100)? 1: 0; mes <= imes;//Контроль и установка темп. 1 раз в cbmes сек
						 otest <= (statet==t_mes)? 1: 0;	end	
case (state)	   
			s_wait : begin  state <= (tv)? s_start: state; 
		                   zsda <= 0; cbsync <= 0; cbbit <= 0; cbdata <= 0; end	    			   
			s_start : begin state <= (ent&&cbsync==50)? s_receive: (cbsync==50)? s_trans: state;
                         scl <= (cbsync==50)? 0: 1;
								 od <= 0;
								 cbsync <= (cbsync==50)? 0: cbsync+1; 
								 odata <= (ent&&cbsync==50)? {7'h48,2'b10,19'h0}:
								          (cbdata==0&&cbsync==50)? {7'h2c,2'b00,9'h0,~igain,4'b0}:
											 (cbdata==1&&cbsync==50)? {7'h2c,2'b00,9'h100,opos,2'b0}:
											 (cbdata==2&&cbsync==50)? {7'h2d,2'b00,9'h0,oneg,2'b0}: {7'h2d,2'b00,9'h100,ocompen,2'b0}; end
			s_receive: begin state <= (cbbit==9&&cbsync==150&&in!=0)? s_err: (cbbit==28&&cbsync==100)? s_stop: state;
								  scl <= (cbsync==100)? 1: (cbsync==200)? 0: scl;
								  od <= (cbsync==50)? odata[27]: od;
								  odata <= (cbsync==50)? {odata[26:0],1'b1}: odata;
								  zsda <= (cbbit>=9&&cbbit<=17||cbbit>=19&&cbbit<=27)? 1: 0;
								  idata <= (cbsync==150&&(cbbit>=10&&cbbit<=17||cbbit>=19&&cbbit<=20))? {idata[8:0],in}: idata;
								  itemp <= (cbbit==28&&cbsync==100)? idata: itemp;
								  iitemp <= (cbbit==28&&cbsync==100)? itemp: iitemp;
								  cbbit <= (cbbit==28&&cbsync==100)? 0: (cbsync==50)? cbbit+1: cbbit;
								  cbsync <= ((cbbit==28&&cbsync==100)||cbsync==200)? 0: cbsync+1; end		
			s_trans : begin  state <= ((cbbit==9||cbbit==18||cbbit==27)&&cbsync==150&&in!=0)? s_err: (cbbit==28&&cbsync==100)? s_stop: state;
								  scl <= (cbsync==100)? 1: (cbsync==200)? 0: scl;
								  od <= (cbsync==50)? odata[27]: od;
								  odata <= (cbsync==50)? {odata[26:0],1'b1}: odata;
								  zsda <= (cbbit==9||cbbit==18||cbbit==27)? 1: 0;
								  cbbit <= (cbbit==28&&cbsync==100)? 0: (cbsync==50)? cbbit+1: cbbit;
								  cbsync <= ((cbbit==28&&cbsync==100)||cbsync==200)? 0: cbsync+1; 
								  cbdata <= (cbbit==28&&cbsync==100)? cbdata+1: cbdata; end
	      s_stop :  begin  state <= (cbsync==50)? s_pause: state;
								  scl <= 1;
								  od <= (cbsync==50)? 1: 0;
								  zsda <= 0; 
								  cbsync <= (cbsync==50)? 0: cbsync+1; end		   
			s_pause : begin  state <= (cbsync==200&&cbdata==4)? s_wait: (cbsync==200)? s_start: state;
								  cbsync <= (cbsync==200)? 0: cbsync+1; end	
	      s_err : begin  state <= s_wait; scl <= 1; od <= 1; zsda <= 0; cbsync <= 0; cbbit <= 0; cbdata <= 0; end         
	   endcase
		
case (statet)
			t_wait : begin statet <= (mes)? t_mes1: statet;
               			entec <= 0;
                        cbmes <= 0; end
			t_mes1 : begin statet <= (tw&&mes)? t_mes3:
			                         ((itemp>tmin&&itemp<tmax)&&mes)? t_mes:
			                         (mes)? t_mes: statet;
								entec <= (mes&&tw)? 6144: 0;
								cbmes <= 0;	end
/*			t_mes2 : begin statet <= (tc&&mes)? t_mes3: statet;
								entec <= (tc&&mes&&entec>=4096)? entec-4096: (tc&&mes)? 0: entec;
                        cbmes <= 0; end */
			t_mes3 : begin statet <= (tw&&mes&&cbmes==64)? t_mes4:
                          			 (tc&&mes)? t_mes4: statet;
								entec <= (tw&&mes&&cbmes==64)? entec+4096:
         								(tc&&mes)? entec-4096: entec;
                        cbmes <= ((tc&&mes)||cbmes==64&&mes)? 0: (mes)? cbmes+1: cbmes; end
			t_mes4 : begin statet <= (mes&&cbmes==15)? t_mes5: statet;
								entec <= (tw&&mes&&cbmes==15)? entec+1024:
         								(tc&&mes&&cbmes==15)? entec-1024: entec;
                        cbmes <= (mes&&cbmes==15)? 0: (mes)? cbmes+1: cbmes; end
			t_mes5 : begin statet <= (mes&&cbmes==15)? t_mes6: statet;
								entec <= (tw&&mes&&cbmes==15)? entec+512:
         								(tc&&mes&&cbmes==15)? entec-512: entec;
                        cbmes <= (mes&&cbmes==15)? 0: (mes)? cbmes+1: cbmes; end
			t_mes6 : begin statet <= (mes&&cbmes==15)? t_mes: statet;
								entec <= (tw&&mes&&cbmes==15)? entec+256:
         								(tc&&mes&&cbmes==15)? entec-256: entec;
                        cbmes <= (mes&&cbmes==15)? 0: (mes)? cbmes+1: cbmes; end
			t_mes  : begin statet <= statet; 
			               endet <= ((itemp>tmin||itemp<tmax)&&mes)? 1: ((itemp>=512&&itemp<tmin-8||itemp>tmax+8&&itemp<=511)&&mes)? 0: endet;
								         //(itemp<tmin-8||itemp>tmax+8)? 0: (itemp>tmin&&itemp<tmax)? 1: endet;
								entec <= (cbmes==5&&tw&&mes&&entec>=16319)? 16383: (cbmes==5&&tw&&mes)? entec+64:
         								(cbmes==5&&tc&&mes&&entec<=64)? 0: (cbmes==5&&tc&&mes)? entec-64: entec;
											cbmes <= (cbmes==5&&mes)? 0: (mes)? cbmes+1: cbmes; end					
		endcase						
	   end
	   end 


endmodule
