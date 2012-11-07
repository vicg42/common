//-------------------------------------------------------------
//  Модуль обмена с пультом (несколько МУПов)
//-------------------------------------------------------------
// Автор Латушко А.В.
//
// V1.0   6.7.5
// V2.0   31.8.5
// V3.0   22.9.6
//-------------------------------------------------------------
module pult_io(rst,clk_io,trans_ack,
               data_i,data_o,dir_485,
               host_clk_wr,wr_en,data_from_host,
               host_clk_rd,rd_en,data_to_host,
               busy,ready
               );

   input rst,clk_io;            //сброс и тактовая для обмена с пультом
   input trans_ack;             //контроллер PCI совершил обмен с кем-то

   input data_i;                //последовательные данные от пульта
   output data_o;               //последовательные данные на пульт
   output dir_485;              //управление 485 приемо-передатчиком

   input host_clk_wr;           //тактовая от хоста для записи
   input wr_en;                 //разрешение записи в память светодиодов
   input [31:0] data_from_host; //данные из хоста для записи

   input host_clk_rd;           //тактовая от хоста для чтения
   input rd_en;                 //разрешение записи в память светодиодов
   output [31:0] data_to_host;  //данные в хост

   output busy,ready;           //состояние обмена с пультом

// Внутренние переменные
   wire wr_en,rd_en;
   reg start_mup;             //запрос обмена с одним МУПом
   reg [2:0] n_mup;           //номер МУПа (МУПов -> 8 шт.)

   reg [2:0] state;           //состояния FSM
   parameter S_W=0;
   parameter S_1=1;
   parameter S_2=2;
   parameter S_3=3;
   parameter S_4=4;

   reg rd_en_m,wr_en_m;     //чтение данных для пульта, запись данных от пульта
   wire [31:0] dout;        //данные из фифо на МУП
   wire busy_mup;           //занятость модуля обмена с МУП
   wire [15:0] but;         //шина кнопок
   wire [23:0] an_data;     //шина аналоговых данных
   wire error,answer;       //состояние текущего обмена с МУП
   reg [31:0] din;          //регистр для перезаписи в фифо
   reg rst_ififo;           //сбросим премное фифо от лишних данных
   wire empty_i;            //пустота фифо данных для пульта
   wire empty_o;            //пустота фифо данных от пульта

   wire [31:0] data_from_host;
   wire [31:0] data_to_host;

   reg busy;                  //мы заняты обменом
   wire ready;                //готовность данных от пульта

// Данные от PCI для светодиодов
fifo511x32th To_pult_fifo (
    .din(data_from_host),
    .rd_clk(clk_io),
    .rd_en(rd_en_m),
    .rst(rst | rst_ififo),
    .wr_clk(host_clk_wr),
    .wr_en(wr_en),
    .dout(dout),
    .empty(empty_i),
    .full());

// Данные для PCI (кнопки, АЦП и признаки об обменах с МУПами)
fifo511x32th From_pult_fifo (
    .din(din),
    .rd_clk(host_clk_rd),
    .rd_en(rd_en),
    .rst(rst),
    .wr_clk(clk_io),
    .wr_en(wr_en_m),
    .dout(data_to_host),
    .empty(empty_o),
    .full());

assign ready = ~empty_o & ~busy;

// Поочередное общение со всеми МУПами пульта
// Первое данное из фифо не читаем (fall-through) !!
always @(posedge rst or posedge clk_io)
   if(rst) begin
         state <= S_W;
         start_mup <= 0;
         n_mup <= 0;
         rd_en_m <= 0;
         wr_en_m <= 0;
         rst_ififo <= 0;
         busy <= 0;
      end
   else case(state)
      S_W: if(trans_ack && ~empty_i) begin
            state <= S_1;
            start_mup <= 1;
            n_mup <= 0;
            busy <= 1;
         end
      S_1: if(busy_mup) begin
            state <= S_2;
            start_mup <= 0;
         end
      S_2: if(~busy_mup) begin      //обмен закончился
            state <= S_3;
            din <= {error,answer,14'h0000,but};
            wr_en_m <= 1;
            if(n_mup==1 || n_mup==3 || n_mup==5) rd_en_m <= 1;
         end
      S_3: begin
            state <= S_4;
            din <= {8'h00,an_data[23:0]};
            rd_en_m <= 0;
            if(n_mup==7) rst_ififo <= 1;   //остальные данные нам не нужны
         end
      S_4: if(n_mup==7) begin
            state <= S_W;
            wr_en_m <= 0;
            rst_ififo <= 0;
            busy <= 0;
         end
        else begin
            state <= S_1;
            start_mup <= 1;
            n_mup <= n_mup+1;
            wr_en_m <= 0;
         end
      endcase

// Установим устройство обмена с МУПами по 485 интерфейсу
mup_io My_mup_io (
    .rst(rst),
    .clk(clk_io),
    .data_i(data_i),
    .data_o(data_o),
    .dir_485(dir_485),
    .start(start_mup),
    .busy(busy_mup),
    .error(error),
    .answer(answer),
    .n_mup(n_mup),
    .led(n_mup[0]? dout[31:16]: dout[15:0]),
    .but(but),
    .an_data(an_data)
    );

endmodule
