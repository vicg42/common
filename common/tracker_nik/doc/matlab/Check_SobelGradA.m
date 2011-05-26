%------------------------------------------------------------------------
% Сравнение изображений.(Градиент яркости)
% SrcImage ------ исходное изображение
% FpgaResImage -- результат обработки FPGA
% TDelta_calc -- тип нахождения dX,dY (если 1, то dXm,dYm делим на 2;
%                                      если 0, то dXm,dYm НЕ делим на 2)
% TGradA_calc -- тип апрксимации (dx^2 + dy^2)^0.5 (0/1 - грубая/точная)
%------------------------------------------------------------------------
function Check_SobelGradA(SrcImage, FpgaResImage, TDelta_calc, IP2, IP1) %TGradA_calc)
    % Читаем изображения
    ImSrc = imread(SrcImage);
    ImSizeXY = size(ImSrc);
    ImSizeX = ImSizeXY(1,2);
    ImSizeY = ImSizeXY(1,1);

    ImResult = imread(FpgaResImage);

    % Вычисляем градиент яркости
    GradA = Sobel_GradA2(ImSrc, TDelta_calc, IP1, IP2); % TGradA_calc);

    % вычисляем разность
    ImDif = double(ImResult) - double(GradA);

    % Вывод на экран
    figure('Name','FPGA_result'); imshow(ImResult);
    figure('Name','MatLab_result'); imshow(GradA);
    figure('Name','Differents'); mesh(ImDif(2:(ImSizeY-1), 2:(ImSizeX-1)));

end