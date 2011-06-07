%------------------------------------------------------------------------
% Сравнение изображений.
% SrcImage ------ исходное изображение
% FpgaResImage -- результат обработки FPGA
% TDelta_calc -- тип нахождения dX,dY (если 1, то dXm,dYm; dXs,dYs делим на 2;
%                                      если 0, то dXm,dYm; dXs,dYs НЕ делим на 2)
% TGradO_var --- варианты вычисления направления градиента яркости
% IP ----------- Интервальные пороги (задается в файле IP.mat)
% IPcount ------ Кол-во Интервальные порогов
%------------------------------------------------------------------------
function Check_Image(SrcImage, ResultDir, TDelta_calc, TGradO_var, IP, IPcount)
    % Читаем изображения
    ImSrc = imread(SrcImage);

    ImSizeXY = size(ImSrc);
    ImSizeX = ImSizeXY(1,2);
    ImSizeY = ImSizeXY(1,1);

    for i=0: IPcount-1
%       %%--------------------------------------------------------
%       ImResult = imread(strcat(ResultDir, 'img', num2str(i), '_0.png'));
%
%       % вычисляем разность
%       ImDif = double(ImResult) - double(ImResult);
%
%       % Вывод на экран
%       figure('Name',strcat('IP',num2str(i), 'Image FPGA')); imshow(ImResult);
%       figure('Name',strcat('IP',num2str(i), 'Image MatLab')); imshow(ImSrc);
%       figure('Name',strcat('IP',num2str(i), 'Image Diff')); mesh(ImDif(2:(ImSizeY-1), 2:(ImSizeX-1)));

      strcat('IP', num2str(i),'Расчет градиента яркости...')
      %%--------------------------------------------------------
      ImFgradA = imread(strcat(ResultDir, 'img', num2str(i), '_1.png'));
      % Вычисляем градиент яркости
      GradA = Sobel_GradA2(ImSrc, TDelta_calc, IP(1,i+1), IP(2,i+1)); % TGradA_calc);

      % вычисляем разность
      GradADif = double(ImFgradA) - double(GradA);

      % Вывод на экран
%      figure('Name',strcat('IP',num2str(i), 'GradA FPGA')); imshow(ImFgradA);
%      figure('Name',strcat('IP',num2str(i), 'GradA MatLab')); imshow(GradA);
      figure('Name',strcat('IP',num2str(i), 'GradA Diff')); mesh(GradADif(2:(ImSizeY-1), 2:(ImSizeX-1)));
      strcat('Выполнено!')


      strcat('IP', num2str(i),'Расчет направления градиента яркости')
      %%--------------------------------------------------------
      ImFgradO = imread(strcat(ResultDir, 'img', num2str(i), '_2.png'));
      % Вычисляем направление градиента яркости
      GradO = Sobel_GradO2(ImSrc, TDelta_calc, TGradO_var, IP(1,i+1), IP(2,i+1));

      % вычисляем разность
      GradODif = double(ImFgradO) - double(GradO);

%      ImFgradO(600:663, 130:163)
%      GradO(600:663, 130:163)
%      GradODif(600:663, 130:163)

      % Вывод на экран
%      figure('Name',strcat('IP',num2str(i), 'FPGA_result')); imshow(ImFgradO);
%      figure('Name',strcat('IP',num2str(i), 'ImSrc')); imshow(GradO);
      figure('Name',strcat('IP',num2str(i), 'GradO Diff')); mesh(GradODif(2:(ImSizeY-1), 2:(ImSizeX-1)));
      strcat('Выполнено!')
    end;%for(i)

end