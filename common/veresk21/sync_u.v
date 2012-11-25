//------------------------------------------------------------
// Модуль синхронизации делит входную стабильную частоту для
//  ведения часов, подстраивается под внешние синхронизирующие 
//  импульсы (окно подстройки 3.3мкс). Формируются импульсы
//  для привязки счетчика видеоконтроллера к синхронизации и
//  управления выборкой кадровых буферов
// Формат времени: [31]-overday, [30:26]-часы, [25:20]-минуты,
//  [19:14]-секунды, [13:4]-мс, [3:0]-сотни мкс.
//------------------------------------------------------------
// Автор Латушко А.В.
// 
// V1.0     Date 20.4.5 - 24.4.5
// V1.1     Date 14.5.5 - 15.5.5
// V2.0     Date 23.9.6 - 25.9.6
// V2.1     Date 24.10.6 - 24.10.6
// V2.2     Date 2.11.6
// V2.3     Date 30.06.10 добавил пару выводов для синхрониациивнешних устройств
//------------------------- -----------------------------------
module sync_u(clk,i_pps,i_ext_1s,i_ext_1m,
           sync_iedge,sync_oedge,sync_time_en,mode_set_time,type_of_sync,
           sync_win,
           host_clk,wr_en_time,host_wr_data,
		     stime,n_sync,sync_cou_err,
           sync_out1, sync_out2, out_1s,out_1m,
			  sync_ld, sync_pic
           );
    
   input clk;
   input i_pps,i_ext_1s,i_ext_1m;		 //PPS и внешняя синхронизация
   
   input sync_iedge;       //управляющие фронты входов внешней синхронизации (0-rise)
   input sync_oedge;       //управляющие фронты выходов на внешнюю синхронизацию (0-rise)
   input sync_time_en;     //разрешение работы часов (1-разрешить)
   input mode_set_time;    //установка часов (0-сразу и поехали, 1-по сигналу минутки)
   input [1:0] type_of_sync; //выбор источника внешней синхронизации,
// '10'-внешняя, '01'-PPS, '11','00'-внутренняя синхронизация

   output reg sync_win;         //разрешение передачи синхро пакетов (1 Гц)

   input host_clk;               //тактовая от хоста
   input wr_en_time;             //установка времени
   input [31:0] host_wr_data;    //данные из хоста для записи

   output [31:0] stime;          //внутренний счетчик времени
   output [7:0] n_sync;          //номер синхроимпульса
   output [7:0] sync_cou_err;    //счетчик ошибок внешней синхронизации (не в воротах)

   output sync_out1,out_1s,out_1m;    //синхронизация для внешних устройств
	output sync_out2;
	output sync_ld;  //синхронизация ЛД 
	output sync_pic; //синхронизация PIC 
   
//   output reg sync_piezo;        //синхронизация для компенсатора смаза ТПВ
//   output reg sync_cam_ir;       //синхронизация для камеры ТПВ
   

// Внутренние переменные
   reg pps,p_pps,ext_1s,pext_1s,ext_1m,pext_1m;
   reg rise_pps,fall_pps,rise_ext1s,fall_ext1s,rise_ext1m,fall_ext1m;
   wire rst_pps,rst_ext,breset;

   parameter i_freq=14400000; //входная частота
   reg [6:0] bcounter =0;
   parameter bend=48;         //коэффициент деления 1-го счетчика (до 300кГц)
   reg [11:0] sync_cou;       //счетчик получения частоты прерываний
   parameter len_sync_cou=2500;   //коэффициент деления до синхронизации
   parameter int_gap=len_sync_cou/4;  //интервал между прерываниями
   parameter max_n_sync=i_freq/(bend*len_sync_cou);
   parameter div_100us=i_freq/(bend*2*10000);

   reg sync =0;		         //всеобщая синхронизация
	reg sync_ld=0;             // синхронизация ЛД   
	reg sync_pic=0;            // синхронизация PIC  
   parameter st_0s=5;         //окончание 0-го синхро импульса
   parameter st_s=2;          //окончание не 0-х синхро импульсов
	parameter st_sp=5;         //окончание синхро импульсов для pic
	parameter st_ld=2290;      //для ЛД импульс будет за 700мкс до импульса 120Гц
   reg [7:0] n_sync;          //номер текущего синхроимпульса
   reg [7:0] sync_cou_err;    //счетчик ошибок внешней синхронизации (не в воротах)
	//-----------------------------
	//коррекция 
	reg sync_corr =0;
	reg [7:0] n_sync_corr =0;
	reg [11:0] sync_cou_corr =0;
	reg [6:0] bcounter_corr =0;
	wire [6:0] bend_corr;
	reg flag_decr =0;
	reg flag_incr =0;
	reg [6:0] delta_p=0;
	reg [6:0] delta_m=0;
	wire sync_pulse;
   reg sync_=0;
	
	//-----------------------------

   reg p_sync_cou0;

   reg [3:0] cou100us;    //счетчик деления на div_100us для получения 10кГц
   reg [3:0] p_cou100us;  //задержанный счетчик cou100us
   reg c100us;            //импульсы с частотой 10кГц
   reg c1s,c1m;	        //переносы на секунды и минуты
	//wire c1s,c1m;	        //переносы на секунды и минуты
   reg out_1s,out_1m;     //выходы для внешней синхронизации
   reg [15:0] cou_c1s,cou_c1m; //счетчик длительности импульсов 
                               // на выходах внешней синхронизации
   parameter max_cou_c1s=32766; //длительность импульсов на выходе 1 сек
   parameter max_cou_c1m=32766; //длительность импульсов на выходе 1 мин

   reg [30:4] t_time;   //сэйв для нового времени
   reg [31:0] stime;     //внутренний счетчик времени
   reg new_time;	       //запрос на установку нового времени
   reg rd_new_time;      //сброс запроса на установку нового времени

   wire minutka;     //сигнал установки часов по минутке
	reg breset_ =0;
	reg breset_z =0;
	reg [10:0] cou_sync_pulse =0;
//--------------------------------------------------------------------------------
// Подгоню длительность синхроимпульсов под стандарт 5мкс не нулевой, 10мкс нулевой
always @(posedge clk)
begin
if (sync_corr) cou_sync_pulse <= cou_sync_pulse + 1;
else cou_sync_pulse <=0;
end
assign sync_out1 = ((n_sync_corr==119)&& sync_corr &&(cou_sync_pulse < 144))? 1:   //10мкс
                   ((n_sync_corr!=119)&& sync_corr &&(cou_sync_pulse < 72))?  1:0; //5мкс

//--------------------------------------------------------------------------------
//assign sync_out1 = sync_corr;
assign sync_out2 = sync;


// Запись извне во внутренние регистры
always @(posedge host_clk)
   begin
      if(wr_en_time) t_time[30:4] <= host_wr_data[30:4];
   end

// Отыщем передние и задние фронты внешних сбросов
always @(posedge clk)
   begin
//  PPS
      pps <= i_pps;
      p_pps <= pps;
	   if(~p_pps && pps) rise_pps <= 1;
	   else rise_pps <= 0;
	   if(p_pps && ~pps) fall_pps <= 1;
	   else fall_pps <= 0;
// внешняя синхронизация (секунда)
      ext_1s <= i_ext_1s;
	   pext_1s <= ext_1s;
	   if(~pext_1s && ext_1s) rise_ext1s <= 1;
	   else rise_ext1s <= 0;
	   if(pext_1s && ~ext_1s) fall_ext1s <= 1;
	   else fall_ext1s <= 0;
// внешняя синхронизация (минутка)
      ext_1m <= i_ext_1m;
	   pext_1m <= ext_1m;
	   if(~pext_1m && ext_1m) rise_ext1m <= 1;
	   else rise_ext1m <= 0;
	   if(pext_1m && ~ext_1m) fall_ext1m <= 1;
	   else fall_ext1m <= 0;
   end

// Выберем подходящий фронт сигнала и потом подходящий сигнал
assign rst_pps = sync_iedge? fall_pps: rise_pps;
assign rst_ext = sync_iedge? fall_ext1s: rise_ext1s;
// сформируем 'breset' в зависимости от типа синхронизации и 
//  при установке нового времени (!!!)
assign breset = (type_of_sync==2'b01)? rst_pps: (type_of_sync==2'b10)? rst_ext: new_time;
// Сформируем сигнал минутки по нужному фронту
assign minutka = (~mode_set_time)? 1: sync_iedge? fall_ext1m: rise_ext1m;

// задержим breset на 2 такта чтобы он совпал с c100us
always @(posedge clk)
begin
breset_ <= breset;
breset_z <= breset_;
end

// Начальный делитель частоты
//  подстраивается под внешние сбросы
always @(posedge clk)
   if(breset || bcounter==bend-1) bcounter <= 0; 
   else bcounter <= bcounter+1;
// Вторичный делитель. Делит до частоты синхронизации. Сбрасывается
//  вместе с начальным делителем
always @(posedge clk)
   if(breset ||(bcounter==bend-1 && sync_cou==len_sync_cou-1)) sync_cou <= 0; 
   else if(bcounter==bend-1) sync_cou <= sync_cou+1;
// Номер синхро импульса изменяется при переходе счетчика в 0
always @(posedge clk)
   if(breset ||(bcounter==bend-1 && sync_cou==len_sync_cou-1 && 
          n_sync==max_n_sync-1)) n_sync <= 0; 
   else if(bcounter==bend-1 && sync_cou==len_sync_cou-1) n_sync <= n_sync+1;
	
// Проверим, попала ли внешняя синхронизация в ворота 3.3 мкс в плюс и в минус
always @(posedge clk)
  if(wr_en_time) sync_cou_err <= 0;
  else
      if(breset && (sync_cou!=len_sync_cou-1 || sync_cou!=0)) 
                 sync_cou_err <= sync_cou_err+1;

// Синхронизирующий сигнал (119-й импульс длинее)
always @(posedge clk)
   if((n_sync==119 && sync_cou < st_0s)||(n_sync!=119 && sync_cou < st_s)) sync <= 1;
   else sync <= 0;


	
//-------------------------------------------------------------------------------------------	
// подстройка 120 Гц
// создадим параллельную ветку счетчика синхроимпульсов, которую будем корректировать по 
// результатам прихода фронта внешней синхронизации
// начальный делитель частоты на 300 кГц = 48 тактам 14.4 МГц опорного генератора
// из-за нестабильности частоты генератора на момент прихода синхронизирующего фронта
// последний такт начального делителя частоты может быть короче 48 тактов clk, либо уже начнется счет
// первого такта (считаем, что выйти за "ворота" начального делителя частоты внешняя синхронизация не должна)
// если это произойдет - увеличиваем счетчик ошибок синхронизации
// при переключении режима синхронизации - получим ошибку, 
// счетчик ошибок обнуляется записью от ЦВ нового времени 
// если фронт внешней синхронизации пришел раньше чем мы его ожидали (но попал в ворота),
// то для каждого последущего такта синхронизации
// укорачиваем на один такт длительность первого bcounter_corr и соответственно уменьшаем delta
// в результате откорректированный 119 импульс синхронизации должен сдвинуться на delta от фронта pps
// если фронт внешней синхронизации пришел позже чем мы его ожидали (но попал в ворота),
// то для каждого последущего такта синхронизации
// удлинняем на один такт длительность первого bcounter_corr и соответственно уменьшаем delta
// коррекция идет каждую секунду


assign bend_corr = ((sync_cou_corr == 0) && flag_decr)? bend-1:
                   ((sync_cou_corr == 0) && flag_incr)? bend+1: bend;
// Начальный делитель частоты
//  подстраивается под внешние сбросы
always @(posedge clk)
   if(breset || bcounter_corr == bend_corr -1) bcounter_corr <= 0; 
   else bcounter_corr <= bcounter_corr+1;
// Вторичный делитель. Делит до частоты синхронизации. Сбрасывается
//  вместе с начальным делителем
always @(posedge clk)
   if(breset ||(bcounter_corr == bend_corr-1 && sync_cou_corr == len_sync_cou-1)) sync_cou_corr <= 0; 
   else if(bcounter_corr == bend_corr-1) sync_cou_corr <= sync_cou_corr +1;
// Номер синхро импульса изменяется при переходе счетчика в 0
always @(posedge clk)
   if(breset ||(bcounter_corr == bend_corr-1 && sync_cou_corr == len_sync_cou-1 && 
      n_sync_corr==max_n_sync-1))                                          n_sync_corr <= 0; 
   else if(bcounter_corr == bend_corr-1 && sync_cou_corr ==len_sync_cou-1) n_sync_corr <= n_sync_corr+1;
	

assign sync_pulse = sync && !sync_;
always @(posedge clk)
sync_<= sync;

	
always @(posedge clk)
begin
// записываем рассогласование и
// для каждого последущего интервала 120 Гц уменьшаем дельту на 1
if(breset && (n_sync==119) && (sync_cou == len_sync_cou-1 )) delta_m <= bend - bcounter;
else if (sync_pulse && (delta_m > 0))                        delta_m <= delta_m - 1;

if(breset && (n_sync==0) && (sync_cou == 0))     delta_p <= bcounter;
else if (sync_pulse && (delta_p > 0))            delta_p <= delta_p - 1;

if (delta_m > 2)      flag_decr <= 1'b1;
else begin if (delta_p > 2) flag_incr <= 1'b1;
           else             flag_incr <= 1'b0;
           flag_decr <= 1'b0;
     end
end

// Синхронизирующий сигнал (119-й импульс длинее)
always @(posedge clk)
   if((n_sync_corr==119 && sync_cou_corr<st_0s)||(n_sync_corr!=119 && sync_cou_corr<st_s)) sync_corr<= 1;
   else sync_corr <= 0;

//-------------------------------------------------------------------------------------------


	
//-------------------------------------------------------------
// синхронизирующий сигнал для ЛД
always @(posedge clk)
begin
if (sync_cou_corr >= st_ld) sync_ld <= 1;
else sync_ld <= 0;
// синхронизирующий сигнал для PIC
if (sync_cou_corr < st_sp) sync_pic <= 1;
else sync_pic <= 0;
end

//-------------------------------------------------------------
// Сигнал запроса прерывания 4 раза за время синхронизации 
// Запрос прерывания 1 интервал (3.3us) без сброса запроса!
//always @(posedge clk)   
//   if(sync_cou<200) inter <= 1; 
//   if(sync_cou==0 || sync_cou==int_gap || sync_cou==2*int_gap || 
//          sync_cou==3*int_gap) inter <= 1;
//   if(sync_cou==0 || sync_cou==312 || sync_cou==625 || sync_cou==937 ||
//      sync_cou==1250 || sync_cou==1562 || sync_cou==1875 || sync_cou==2187) inter <= 1;
//   else inter <= 0;

//always @(posedge clk)
//   begin
//      if(n_sync[1:0]==2'b00 && sync_cou==22) sync_piezo <= 1;
//      else sync_piezo <= 0;
//
//      if(n_sync[1:0]==2'b01 && sync_cou==22) sync_cam_ir <= 1;
//      else sync_cam_ir <= 0;
//   end

// Разрешение на передачу синхро пакета. Частота синхропакетов 1 Гц. 
// (1 интервал после синхронизации=3.3us)
always @(posedge clk)
   if(sync_cou==0 && n_sync==0) sync_win <= 1;
   else sync_win <= 0; 

//   УСТАНОВИМ ЧАСЫ
// Сохраним предыдущее состояние младшего разряда счетчика
//  синхронизации (он изменяется с частотой i_freq/2*bend=150кГц) и
//  поделим его частоту до 10кГц
always @(posedge clk)
   p_sync_cou0 <= breset? 0: sync_cou[0];   
always @(posedge clk)
   if(breset ||(p_sync_cou0 && !sync_cou[0] && cou100us==div_100us-1)) 
            cou100us <= 0;
   else if(p_sync_cou0 && !sync_cou[0]) cou100us <= cou100us+1;
// По изменениям делителя до 10 кГц в ноль определяем момент
//  выдачи однотактового импульса с периодом 100 мкс для часов
always @(posedge clk)
   p_cou100us <= cou100us;
always @(posedge clk)
   if(cou100us==0 && p_cou100us==div_100us-1) c100us <= sync_time_en;
   else c100us <= 0;



// Считаем сотни мкс
always @(posedge clk)
   if(breset_z || new_time ||(c100us && stime[3:0]==9)) stime[3:0] <= 0;
   else if(c100us) stime[3:0] <= stime[3:0]+1;
	
// Не понятно но при такой реализации сбивается синхронизация камер???????	
//assign c1s = (breset_z && (stime[13:4]>500))? ~new_time :
//             (c100us && stime[3:0]==9 && stime[13:4]==999)? ~new_time : 0;
	
//assign c1m = (c1s && stime[19:14]==59)? ~new_time : 0;	

// Считаем мс и выдаем импульс на инкремент секунд
//импульс переноса в секунды не формируется, если устанавливается новое время
always @(posedge clk)
      if(new_time && minutka) stime[13:4] <= t_time[13:4];
      else if(breset_z) begin
           stime[13:4] <= 0;
           c1s <= (stime[13:4]>500)? ~new_time: 0;
			  ////////////c1s <= ~new_time;
           end
           else if(c100us && stime[3:0]==9 && stime[13:4]==999) begin
                stime[13:4] <= 0;
	             c1s <= ~new_time;
                end
                else if(c100us && stime[3:0]==9) begin
                     stime[13:4] <= stime[13:4]+1;
	                  c1s <= 0;
		               end
                     else c1s <= 0;
// Считаем секунды и формируем импульс для счета минут и часов
always @(posedge clk)
   begin
//считаем секунды
//импульс переноса в минуты не формируется, если устанавливается новое время
      if(new_time && minutka) stime[19:14] <= t_time[19:14];
      else if(c1s && stime[19:14]==59) begin 
	          stime[19:14] <= 0;
		       c1m <= ~new_time;	
	     end
	   else if(c1s) begin 
	            stime[19:14] <= stime[19:14]+1;
		         c1m <= 0;
		     end
      else c1m <= 0;
   end

// Предложение установить новое время
always @(posedge rd_new_time or posedge host_clk)
   if(rd_new_time) new_time <= 0;
   else if(wr_en_time) new_time <= 1;  //установили запрос

// Установка нового времени или счет минут и часов
always @(posedge clk)
   if(new_time && minutka) begin
         stime[31:20] <= {1'b0,t_time[30:20]};
	      rd_new_time <= 1;	  //установили новое время
      end
   else begin 
	    rd_new_time <= 0;
// Считаем минуты
       if(c1m && stime[25:20]==59) stime[25:20] <= 0;
		 else if(c1m) stime[25:20] <= stime[25:20]+1;
// Считаем часы
       if(c1m && stime[25:20]==59 && stime[30:26]==23) begin
		         stime[30:26] <= 0;
				   stime[31] <= 1;  //перешли на новые сутки
				end
       else if(c1m && stime[25:20]==59) stime[30:26] <= stime[30:26]+1;
       end

// Удлиним импульс 1 сек для внешней синхронизации
always @(posedge clk)
   if(c1s) begin
         out_1s <= ~sync_oedge;
	      cou_c1s <= max_cou_c1s;
      end
   else if(cou_c1s!=0) cou_c1s <= cou_c1s-1;
        else out_1s <= sync_oedge;
// Удлиним импульс 1 мин для внешней синхронизации
always @(posedge clk)
   if(c1m) begin
         out_1m <= ~sync_oedge;
	      cou_c1m <= max_cou_c1m;
      end
   else if(cou_c1m!=0) cou_c1m <= cou_c1m-1;
        else out_1m <= sync_oedge;



endmodule
