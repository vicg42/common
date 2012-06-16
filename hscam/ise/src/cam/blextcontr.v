module blextcontr(RCIN,clk,init,endet,igain,iexp,itemp,rdstat,istat,rdcfg,icfg,RCOUT,oregime,ogain,oexp,oneg,opos,ocompen,korr,wrcfg,ocfg,testser);
    input RCIN;//Вход последовательных данных
    input clk;//65.625MHz
    input init;//Инициализация
	 input endet;//0 - детектор выключен по температуре
    input [7:0] igain;//Входные данные усиления
    input [10:0] iexp;//Экспозиция
	 input [9:0] itemp;//Температура детектора
	 output reg rdstat;//Сигнал чтения из FIFO регистра статуса
	 input [7:0] istat;//Данные из FIFO регистра статуса
	 output reg rdcfg;//Сигнал чтения из FIFO регистра конфигурации
	 input [15:0] icfg;//Данные из FIFO регистра конфигурации
    output reg RCOUT;//Выход последовательных данных
    output reg [15:0] oregime;//Принятые данные режим(9-raid;8-endark;7-test;6-negsyn;5-extgain;4-extexp;3-midsyn;2-extsyn;1,0-60,120,240,480)
    output reg [7:0] ogain;//Принятые данные усиления
    output reg [10:0] oexp;//Принятые данные экспозиция
	 output reg [7:0] oneg;//Принятые данные отрицательный сдвиг
	 output reg [7:0] opos;//Принятые данные положительный сдвиг
	 output reg [7:0] ocompen;//Принятые данные компенсации экспозиции
    output reg korr;//Запуск коррекция пикселов
	 output reg wrcfg;//Сигнал записи в FIFO регистра конфигурации
	 output reg [15:0] ocfg;//Данные записываемые в FIFO регистра конфигурации
    output [3:0] testser;
//управление-[11:8]контраст;[7:0]яркость
//Состояние FSM
    parameter s_wait = 0;//Ожидание стартовой посылки(переход 1-0)
    parameter s_start = 1;//Подсинхронизация к принимаемым данным cb_sync=0.5b
    parameter s_data = 2;//Прием данных
    parameter s_stop = 3;////Прием стоповой посылки
    parameter s_proc = 4;//Анализ полученных данных
	 parameter s_begin = 5;//Пауза cb0_5b, запись первого передаваемого(ident) байта и запись пришедших данных в соответствуюший регистр
    parameter s_trans = 6;//Передача байта адреса, команды, данных
    parameter s_end = 7;//Анализ передаваемых данных
    parameter s_err = 8;//Состояние аварии. Выход по таймауту.
//Команды
	 parameter c_korr = 8'h00;//Запуск коррекции.Прием 2байта,передача 2байта. 2такта.Самосброс.
	 parameter c_rdtemp = 8'h40;//Чтение температуры детектора.Прием 2байта,передача 4байта
    parameter c_wrmode = 8'h10;//Установка режима.Прием 4байта,передача 2байта
    parameter c_rdmode = 8'h50;//Чтение режима.Прием 2байта,передача 4байта
    parameter c_wrexp = 8'h12;//Установка экспозиции.Прием 4байта,передача 2байта
    parameter c_rdexp = 8'h52;//Чтение экспозиции.Прием 2байта,передача 4байта
    parameter c_wrgain = 8'h14;//Установка усиления.Прием 3байта,передача 2байта
	 parameter c_rdgain = 8'h54;//Чтение усиления.Прием 2байта,передача 3байта
	 parameter c_wrcompen = 8'h16;//Установка компенсации экспозиции.Прием 3байта,передача 2байта
	 parameter c_rdcompen = 8'h56;//Чтение компенсации экспозиции.Прием 2байта,передача 3байта
    parameter c_wrnegoff = 8'h18;//Установка негативного сдвига.Прием 3байта,передача 2байта
	 parameter c_rdnegoff = 8'h58;//Чтение негативного сдвига.Прием 2байта,передача 3байта
	 parameter c_wrposoff = 8'h19;//Установка позитивного сдвига.Прием 3байта,передача 2байта
	 parameter c_rdposoff = 8'h59;//Чтение позитивного сдвига.Прием 2байта,передача 3байта
	 parameter c_rdstatus = 8'h60;//Чтение статуса FIFO.Прием 2байта,передача 3байта.Выдаем rd для FIFO(3-й байт)
	 parameter c_wrcfg = 8'h22;//Установка конфигурации FIFO.Прием 4байта,передача 2байта.Выдаем wr для FIFO(4-й байт)
	 parameter c_rdcfg = 8'h62;//Чтение конфигурации FIFO.Прием 2байта,передача 4байта.Выдаем rd для FIFO(4-й байт)
//Байт идентификации камеры
	 parameter ident = 8'he7;
//Интервалы времени
    parameter cb0_5b = 3418;
    parameter cb1b = 6836;
    parameter cb10b = 76000;
//Регистры и переменные
    reg [3:0] state;//Состояние FSM
    reg [12:0] cbsync;//Счетчик синхронизации
    reg [16:0] cbtout;//Счетчик таймаута
	 reg tout;//Регистр таймаута
    reg [7:0] com;//Регистр команд
    reg [15:0] data;//Регистр промежуточных данных
    reg rc_in,irc_in,rc_out;
    reg [7:0] sdata;//Принимаемые данные
    reg [8:0] odata;//Передаваемые данные
    reg [3:0] cbbit;//Счетчик битов
	 reg [2:0] cbbyte;//Счетчик байтов
    reg [7:0] iregime;
    reg [7:0] br;//Яркость
	 reg rkorr;

    assign testser[0] = state[0];
    assign testser[1] = state[1];
    assign testser[2] = state[2];
    assign testser[3] = state[3];
//Работа
  always @(posedge clk)
  begin if (init)//Проводим инициализацию
	                begin state <= s_wait; cbsync <= 0; cbbit <= 0; cbbyte <= 0; com <= 0;
						       cbtout <= 0; tout <= 0; odata <= 9'h1ff; oregime <= 10'h120; oexp <= 1;
								 ogain <= 8'h0; oneg <= 8'h40; opos <= 128; ocompen <= 8'h40; end
		  else if (tout) begin state <= s_wait; cbsync <= 0; cbbit <= 0; cbbyte <= 0; com <= 0;
						       cbtout <= 0; tout <= 0; end
        else begin begin rc_in <= irc_in; irc_in <= RCIN; RCOUT <= rc_out;
                         cbtout <= (rc_in==0||cbtout==cb10b||odata[0]==0)? 0: cbtout+1;//Работа таймаута
					          tout <= (cbtout==cb10b)? 1: 0;
		                   rc_out <= odata[0];
								 rkorr <= korr;
								 korr <= (rkorr)? 0: korr;
//								 ogain <= (oregime[5])? igain: ogain;
// 							    oexp <= (oregime[4])? iexp: oexp;
								 rdstat <= (state==s_end&&com==8'h60&&cbbyte==2)? 1: 0;
								 rdcfg <= (state==s_end&&com==8'h62&&cbbyte==3)? 1: 0;
								 wrcfg <= (state==s_end&&com==8'h22&&cbbyte==1)? 1: 0; end
case (state)
s_wait ://0//Ожидание приема(переход из 1 в 0)
	      begin state <= (rc_in==1&&irc_in==0)? s_start: state;
				   cbsync <= 0; cbbit <= 0; end

s_start ://1//Подсинхронизация к середине стартового бита(если не 0, то ошибка)
	      begin state <= (cbsync==cb0_5b&&rc_in==0)? s_data: (cbsync==cb0_5b&&rc_in==1)? s_err: state;
               cbsync <= (cbsync==cb0_5b)? 0: cbsync + 1; end

s_data ://2//Прием байта
         begin state <= (cbbit==7&&cbsync==cb1b)? s_stop: state;
					cbsync <= (cbsync==cb1b)? 0: cbsync+1;
					cbbit <= (cbbit==7&&cbsync==cb1b)? 0: (cbsync==cb1b)? cbbit+1: cbbit;
					sdata <= (cbsync==cb1b)? {rc_in,sdata[7:1]}: sdata; end

s_stop ://3//Прием стоповой посылки(если не 1 или 0-й байт не ident, то ошибка)
			begin state <= (cbsync==cb1b&&(rc_in==0||(cbbyte==0&&sdata!=ident)))? s_err:
			               (cbsync==cb1b)? s_proc:  state;
					cbsync <= (cbsync==cb1b)? 0: cbsync+1;
					com <= (cbbyte==1&&cbsync==cb1b)? sdata: com; end

s_proc ://4//Анализ полученных данных(количество байт,команда)
		   begin state <= (cbbyte==1&&(com!=8'h0&&com!=8'h10&&com!=8'h50&&com!=8'h12&&com!=8'h52&&
								 com!=8'h14&&com!=8'h54&&com!=8'h16&&com!=8'h56&&com!=8'h40&&com!=8'h18&&
								 com!=8'h58&&com!=8'h19&&com!=8'h59&&com!=8'h60&&com!=8'h22&&com!=8'h62))? s_err:
			               (cbbyte==0||cbbyte==1&&(com==8'h10||com==8'h12||com==8'h14||com==8'h16||com==8'h18||com==8'h19||com==8'h22)||
                         cbbyte==2&&(com==8'h10||com==8'h12||com==8'h22))? s_wait: s_begin;
			      cbbyte <= cbbyte+1;
					data[15:8] <= ((com==8'h10||com==8'h12||com==8'h22)&&cbbyte==2)? sdata[7:0]: data[15:8];
					data[7:0] <= sdata[7:0]; end

s_begin ://5//Пауза cb0_5b, запись первого передаваемого(ident) байта и запись пришедших данных в соответствуюший регистр
			 begin state <= (cbsync==cb0_5b)? s_trans: state;
					 odata <= (cbsync==cb0_5b)? {ident,1'b0}: 9'h1ff;
					 cbsync <= (cbsync==cb0_5b)? 0: cbsync+1;
					 cbbit <= 0; cbbyte <= 0;
					 korr <= (com==8'h0&&cbsync==cb0_5b)? 1: korr;
					 oregime <= (com==8'h10)? data[15:0]: oregime;
					 oexp <= (com==8'h12&&data>1027)? 1027: (com==8'h12&&data==0)? 1: (com==8'h12)? data[10:0]: oexp;
					 ogain <= (com==8'h14)? data[7:0]: ogain;
					 ocompen <= (com==8'h16)? data[7:0]: ocompen;
					 oneg <= (com==8'h18)? data[7:0]: oneg;
					 opos <= (com==8'h19)? data[7:0]: opos;
					 ocfg <= (com==8'h22)? data: ocfg;	end

s_trans ://6//Передача байта адреса, команды, данных
			 begin state <= (cbsync==cb1b&&cbbit==9)? s_end: state;
					 cbsync <= (cbsync==cb1b)? 0: cbsync+1;
					 cbbit <= (cbsync==cb1b&&cbbit==9)? 0: (cbsync==cb1b)? cbbit+1: cbbit;
					 odata <= (cbsync==cb1b)? {1'b1,odata[8:1]}: odata; end

s_end ://7//Анализ передаваемых данных
		  begin state <= (cbbyte==1&&(com==8'h0||com==8'h10||com==8'h12||com==8'h14||com==8'h16||com==8'h18||com==8'h19||com==8'h22)||
		                  cbbyte==2&&(com==8'h54||com==8'h56||com==8'h58||com==8'h59||com==8'h60)||
								cbbyte==3&&(com==8'h40||com==8'h50||com==8'h52||com==8'h62))? s_wait: s_trans;
				  cbbyte <= (cbbyte==1&&(com==8'h0||com==8'h10||com==8'h12||com==8'h14||com==8'h16||com==8'h18||com==8'h19||com==8'h22)||
		                   cbbyte==2&&(com==8'h54||com==8'h56||com==8'h58||com==8'h59||com==8'h60)||
								 cbbyte==3&&(com==8'h40||com==8'h50||com==8'h52||com==8'h62))? 0: cbbyte+1;
				  odata <= (cbbyte==0)? {com,1'b0}:
							  (cbbyte==1&&com==8'h40)? {6'h0,itemp[9:8],1'b0}:
							  (cbbyte==2&&com==8'h40)? {itemp[7:0],1'b0}:
				           (cbbyte==1&&com==8'h50)? {5'h0,endet,oregime[9:8],1'b0}:
							  (cbbyte==2&&com==8'h50)? {oregime[7:0],1'b0}:
          				  (cbbyte==1&&com==8'h52)? {5'h0,iexp[10:8],1'b0}:
							  (cbbyte==2&&com==8'h52)? {iexp[7:0],1'b0}:
							  (cbbyte==1&&com==8'h54)? {igain,1'b0}:
							  (cbbyte==1&&com==8'h56)? {ocompen,1'b0}:
							  (cbbyte==1&&com==8'h58)? {oneg,1'b0}:
							  (cbbyte==1&&com==8'h59)? {opos,1'b0}:
							  (cbbyte==1&&com==8'h60)? {istat,1'b0}:
							  (cbbyte==1&&com==8'h62)? {icfg[15:8],1'b0}:
							  (cbbyte==2&&com==8'h62)? {icfg[7:0],1'b0}: 9'h1ff; end

s_err ://8//Состояние аварии. Выход по таймауту.
		 begin state <= (tout)? s_wait: state;
				 cbsync <= 0; cbbit <= 0; cbbyte <= 0; com <=0; end
  endcase
    end
  end
endmodule
