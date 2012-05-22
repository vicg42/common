module blextsyn(clk,fr,inv,tv,th,midsyn,in,ah,av,iexp,extsyn,uph,downh,beginsyn,e1sec,esyn,isyn,tv60);
    input clk;//65.625MHz
	 input [1:0] fr;//Частота кадров
    input inv;//Инверсия фронта синхронизации
    input tv;//Конец кадра 
	 input th;//Конец строки	
    input midsyn;//Синхронизация по середине экспозиции
    input in;//120герц
    input [10:0] ah;//Адрес столбца
    input [10:0] av;//Адрес строки
    input [10:0] iexp;//Текущая экспозиция
	 input extsyn;//Сигнал внешней синхронизации
    output reg uph;//Увеличение длительности строки
    output reg downh;//Уменьшение длительности строки
    output reg beginsyn;//Общая привязка к внешней синхронизации
	 output reg e1sec;//1 секунда, один период clk, внешняя
    output reg esyn;//60 герц, один период clk, внешняя
    output reg isyn;//60 герц, один период clk, внутренняя
	 output reg tv60;//tv-60Hz
//Переменные
    reg [7:0] cbsub;//Счетчик ошибки
    reg [7:0] cberr;//Счетчик коррекции ошибки
    reg [8:0] cbwidth;//Счетчик определения 1секунды
    reg frame;//60 герц меадр
    reg oin;//Для выработки импульса по фронту
    reg sub;//Ворота между внешней и внутренней синхронизациями    
    reg err;//Регистр ошибки:разрешает сброс по первому esyn     
    reg iin,fdin,fdup,fddown;
    reg [1:0] beginsyn2;
	 reg [2:0] cbframe;//счетчик кадров камеры
	 reg en1sec;
	 reg [2:0] cbtv;//Выделение 60Гц по tv сигналу
	 
//Параметры
//    parameter midh = 391;//Середина строки
    parameter maxsub = 100;//Максимальная разность между синхронизациями

always @(posedge clk)
  begin iin <=fdin; fdin <=in;//Привязка синхронизации к внутреннему генератору
        oin <=((inv&&~fdin&&iin)||(~inv&&fdin&&~iin))? 1: 0;//Выделение импульса из фронта 
        cbwidth <= ((inv && ~iin)||(~inv && iin))? cbwidth + 1: 0;//считаем длину синхронизации
		  frame <=  (cbwidth==500)? 0: (oin)? ~frame: frame;//Привязка к 1сек и получение меандра 60Гц
		  en1sec <= (cbwidth==500)? 1: (oin)? 0: en1sec;//Выделение ворот
		  e1sec <= (~extsyn)? tv60: (en1sec)? oin: 0;//Выделение импульса привязанного к внешней 1сек или внутренней синхронизации 60Гц
		  esyn <=(~frame && oin)? 1: 0;//Выделение внешней синхронизации 60Гц
		  cbtv <= ((fr==0||fr==1&&cbtv==1||fr==2&&cbtv==3||fr==3&&cbtv==7)&&tv)? 0: cbtv+1;
		  tv60 <= (fr==0||fr==1&&cbtv==1||fr==2&&cbtv==3||fr==3&&cbtv==7)? tv: 0;//Выделение внутренней синхронизации 60Гц
		  cbframe <= (beginsyn)? 0: (tv)? cbframe+1: cbframe;//счетчик кадров камеры
		  isyn <= ((midsyn==0&&fr==0&&tv)||(midsyn==0&&fr==1&&cbframe==1&&tv)||
				     (midsyn==0&&fr==2&&cbframe==3&&tv)||(midsyn==0&&fr==3&&cbframe==7&&tv)||
				     (midsyn==1&&fr==0&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==0&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==532)||
					  (midsyn==1&&fr==1&&cbframe==1&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==1&&cbframe==1&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==266)||
					  (midsyn==1&&fr==2&&cbframe==3&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==2&&cbframe==3&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==133)||
					  (midsyn==1&&fr==3&&cbframe==7&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==3&&cbframe==7&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==67))? 1: 0;//Выделение внутренней синхронизации							  
		  beginsyn <= (err&&esyn)? 1'b1: 1'b0;//Общий сброс
		  sub <= (beginsyn)? 0: (esyn^isyn)? ~sub : sub;//определение ворот разности между синхронизациями
		  cbsub <= (sub==1)? cbsub+1: 0;//Вычисление разности между синхронизациями в пикселах
		  err <= (cbsub==maxsub)? 1:(beginsyn)? 0: err;//Установка флага ошибки при превышении максимума
		  uph <= (cberr==0||beginsyn)? 0: (sub==1&&esyn==1)? 1: uph;//Строку надо увеличить
		  downh <= (cberr==0||beginsyn)? 0: (sub==1&&isyn==1)? 1: downh;//Строку надо уменьшить
		  cberr <= (err)? 0: (esyn^isyn && sub)? cbsub: (th&&cberr!=0)? cberr-1: cberr;
  end
endmodule
