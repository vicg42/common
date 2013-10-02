//---------------------------------------------------------
//  Модуль обмена с Модулем Универсальным Пульта (МУП).
// На МУП передается адресный байт и 2 байта управления
//  светодиодами, от МУП приходит 2 байта состояния кнопок,
//  3 байта с АЦП. Если МУП ответил, то выставляется
//  сигнал 'answer', а если произошла ошибка четности, то
//  выставляется признак 'error'.
//---------------------------------------------------------
// Автор Латушко А.В.
//
// V1.0   6.7.5
//---------------------------------------------------------
module mup_io(rst,clk,data_i,data_o,dir_485,
              start,busy,error,answer,
              n_mup,led,but,an_data,
              clk_en
              );

   input rst;             //сброс FSM
   input clk_en;          //add vicg
   input clk;             //тактовая (4х битовой частоты обмена)
   input data_i;          //данные из 485 приемника
   output data_o;         //данные на 485 передатчик
   output dir_485;        //направление работы 485 ПП
   input start;           //начало цикла обмена
   output busy;           //готовность модуля обменяться с МУП
   output error;          //ошибка обмена с МУП
   output answer;         //МУП отвечает
   input [2:0] n_mup;     //номер МУПа для обращения
   input [15:0] led;      //слово управления светодиодами
   output [15:0] but;     //слово состояния кнопок
   output [23:0] an_data; //данные из АЦП

// Внутренние переменные
   reg data_rec,data_rec1;
   reg [3:0] state;      //состояние FSM
   reg [3:0] state_ret;  //адрес возврата из состояния ожидания нового байта от МУП
   parameter S_W=0;
   parameter S_S_NMUP=1;
   parameter S_S_1LED=2;
   parameter S_S_2LED=3;
   parameter S_W_ANS=4;
   parameter S_R_1BUT=5;
   parameter S_R_2BUT=6;
   parameter S_R_1AN=7;
   parameter S_R_2AN=8;
   parameter S_R_3AN=9;
   parameter S_TO=10;
   reg data_o;
   reg busy,error,answer;
   parameter insid=0;    //направление работы 485 приемопередатчика
   parameter outside=1;
   reg dir_485;           //управление направлением обмена по 485
   reg [5:0] count;       //счетчик тактов внутри состояний 'state'
   reg [15:0] but;
   reg [7:0] t_rec;  //временное хранилище принятого байта (до проверки на ошибку)
   reg [23:0] an_data;

// Входной триггер и задержка на такт для определения начала старт-бита
always @(posedge clk)
begin
  if (clk_en) begin
  data_rec <= data_i;
  data_rec1 <= data_rec;
  end
end //always @

// FSM для обмена с МУП
always @(posedge clk)
begin
   if(rst) begin
         state <= S_W;
         count <= 0;
         dir_485 <= insid;
         data_o <= 1;
         busy <= 0;
         error <= 0;
         answer <= 0;
      end
   else if (clk_en) case(state)
      S_W: begin
            if(start) state <= S_S_NMUP;    //ждем начала обмена
            count <= 0;
            dir_485 <= outside;
            busy <= 1;       //мы заняты
            data_o <= 1;
         end
// пересылка адресного байта
      S_S_NMUP: begin
         if(count==43) count <= 0; else count <= count+1;
         case(count)
            0,1,2,3: begin     //старт-бит -> на выход
              data_o <= 0;
              error <= 0;      //сбросили ошибку
              answer <= 0;     //сбросили признак ответа респондента
             end
// перешлем [7:3] биты адресного байта нулями
//          4,5,6,7,        // 7 бит -> на выход
//          8,9,10,11,      // 6 бит -> на выход
//          12,13,14,15,    // 5 бит -> на выход
//          16,17,18,19,    // 4 бит -> на выход
//          20,21,22,23:    // 3 бит -> на выход
            24,25,26,27: data_o <= n_mup[2];  // 2 бит номера МУПа -> на выход
            28,29,30,31: data_o <= n_mup[1];  // 1 бит номера МУПа -> на выход
            32,33,34,35: data_o <= n_mup[0];  // 0 бит номера МУПа -> на выход
            36,37,38,39: data_o <= ^n_mup;    //поехала четность адресного байта
            40,41,42:    data_o <= 1;         // стоп бит -> на выход
            43: state <= S_S_1LED; //будем передавать первый байт со светодиодами
         endcase
      end      // конец пересылки адресного байта
// пересылаем первый байт со светодиодами
      S_S_1LED: begin
         if(count==43) count <= 0; else count <= count+1;
         case(count)
            0,1,2,3:     data_o <= 0;          //старт-бит -> на выход
            4,5,6,7:     data_o <= led[15];    //светодиоды -> на выход
            8,9,10,11:   data_o <= led[14];
            12,13,14,15: data_o <= led[13];
            16,17,18,19: data_o <= led[12];
            20,21,22,23: data_o <= led[11];
            24,25,26,27: data_o <= led[10];
            28,29,30,31: data_o <= led[9];
            32,33,34,35: data_o <= led[8];
            36,37,38,39: data_o <= ^led[15:8]; //поехала четность
            40,41,42:    data_o <= 1;          // стоп бит -> на выход
            43: state <= S_S_2LED; //будем передавать 2-й байт со светодиодами
         endcase
      end
// пересылаем 2-й байт со светодиодами
      S_S_2LED: begin
         if(count==43) count <= 0; else count <= count+1;
         case(count)
            0,1,2,3:     data_o <= 0;         //старт-бит -> на выход
            4,5,6,7:     data_o <= led[7];    //светодиоды -> на выход
            8,9,10,11:   data_o <= led[6];
            12,13,14,15: data_o <= led[5];
            16,17,18,19: data_o <= led[4];
            20,21,22,23: data_o <= led[3];
            24,25,26,27: data_o <= led[2];
            28,29,30,31: data_o <= led[1];
            32,33,34,35: data_o <= led[0];
            36,37,38,39: data_o <= ^led[7:0]; //поехала четность
            40,41,42:    data_o <= 1;         // стоп бит -> на выход
            43: begin
                state <= S_W_ANS;        //идем ждать ответа от МУП
                state_ret <= S_R_1BUT;
                dir_485 <= insid;
              end
         endcase
      end
// Принимаем 1-й байт кнопок (сюда мы попали в середине старт-бита)
       S_R_1BUT: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //пропускаем старт-бит
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //идем ждать следующий байт от МУП
                   state_ret <= S_R_2BUT;
                   if(data_rec==^t_rec) but[15:8] <= t_rec[7:0];  //паритет OK
                   else error <= 1;
                   answer <= 1;          //респондент ответил
                end
          endcase
       end
// Принимаем 2-й байт кнопок (сюда мы попали в середине старт-бита)
       S_R_2BUT: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //пропускаем старт-бит
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //идем ждать следующий байт от МУП
                   state_ret <= S_R_1AN;
                   if(data_rec==^t_rec) but[7:0] <= t_rec[7:0];  //паритет OK
                   else error <= 1;
                end
          endcase
       end
// Принимаем 1-й байт АЦП (сюда мы попали в середине старт-бита)
       S_R_1AN: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //пропускаем старт-бит
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //идем ждать следующий байт от МУП
                   state_ret <= S_R_2AN;
                   if(data_rec==^t_rec) an_data[23:16] <= t_rec[7:0];  //паритет OK
                   else error <= 1;
                end
          endcase
       end
// Принимаем 2-й байт АЦП (сюда мы попали в середине старт-бита)
       S_R_2AN: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //пропускаем старт-бит
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //идем ждать следующий байт от МУП
                   state_ret <= S_R_3AN;
                   if(data_rec==^t_rec) an_data[15:8] <= t_rec[7:0];  //паритет OK
                   else error <= 1;
                end
          endcase
       end
// Принимаем 3-й байт АЦП (сюда мы попали в середине старт-бита)
       S_R_3AN: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //пропускаем старт-бит
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_TO;      //пауза после обмена
                   if(data_rec==^t_rec) an_data[7:0] <= t_rec[7:0];  //паритет OK
                   else error <= 1;
                end
          endcase
       end
// Пауза для сброса всех МУП
       S_TO: begin
          count <= count+1;
          if(count==63) begin
            busy <= 0;
            state <= S_W;
          end
       end
// Ждем ответа от МУП в течение 64 тактов либо ждем
//  прихода очередного байта посылки
       S_W_ANS: begin
          if(count==63) begin
            busy <= 0;
            state <= S_W;  //мы ждали, а нам не ответили
          end
          else if(~data_rec && data_rec1) begin
                    state <= state_ret; //есть обмен
                    count <= 0;
                 end
          else count <= count+1;
       end        //end of S_W_ANS
   endcase       //end of FSM
end //always @

endmodule
