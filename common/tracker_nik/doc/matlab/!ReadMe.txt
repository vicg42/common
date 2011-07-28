CreateCOEFile.m ---- Создает *.coe файл для BRAM - таблица базовых углов для расчета направления градиента яркости
Check_Nik.m -------- Проверка результатов вычислений FPGA:

Использование CreateCOEFile.m
1. Запустить MatLab
2. в command window (MatLab) набрать
   cd путь к каталогу ..\tracker_nik\doc\matlab
3. в command window (MatLab) набрать
   CreateCOEFile('Путь к создоваемому файлу');

   Пример: CreateCOEFile('D:\tracker_nik\doc\matlab\y_0...255_x_0...255.coe');


Использование Check_Nik.m:
1. Запустить MatLab
2. в command window (MatLab) набрать
   cd путь к каталогу ..\tracker_nik\doc\matlab
3. Перейти на закладку Workspace и добавить файл IP.mat (Интервальные пороги Никифорова)
  3.1 Если необходимо отредактировать маcив IP (Интервальные пороги Никифорова)
4. Получить результаты обработки FPGA
5. в command window (MatLab) набрать

   Check_Nik('Путь к эталонному изображению',
             'Путь к каталогу результатов обработки FPGA',
             0(парамерт d - в программе lvmtr2reader(0/1 - Image 1024x1024/320x256)),
             0,
             IP,
             Кол-во используемых ИП);

   Пример: Check_Nik('D:\Work\Linkos\!!ver_arch\Veresk-M-arch\tst_image\1024x1024\gray\03g.jpg', 'D:\Work\Linkos\!!ver_arch\Veresk-M-arch\tst_sobel\Results\1024x1024\03\', 0, 0, IP, 4);

   Пример: в тестовой программе lvmtr2reader - параметр m должен быть всегда 1 (m1) - это выбор типа апроксимации 1/0 точная/грубая
                                             - параметр d устанавливается в зависимости от камеры: 1024x1024 - d1; 320x256 -d0