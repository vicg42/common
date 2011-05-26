%------------------------------------------------------------------------
% Сравнение изображений.(Направление градиента яркости)
% SrcImage ----- исходное изображение
% FpgaResImage - результат обработки FPGA
% TDelta_calc -- тип нахождения dX,dY (если 1, то dXm,dYm; dXs,dYs делим на 2;
%                                      если 0, то dXm,dYm; dXs,dYs НЕ делим на 2)
% TGradO_calc -- варианты вычисления направления градиента яркости
%------------------------------------------------------------------------
function Check_SobelGradO(SrcImage, FpgaResImage, TDelta_calc, TGradO_calc, IP2, IP1) %
    % Читаем изображения
    ImSrc = imread(SrcImage);
    ImSizeXY = size(ImSrc);
    ImSizeX = ImSizeXY(1,2);
    ImSizeY = ImSizeXY(1,1);

    ImResult = imread(FpgaResImage);

    % Вычисляем направление градиента яркости
    GradO = Sobel_GradO2(ImSrc, TDelta_calc, TGradO_calc, IP1, IP2); %

    % вычисляем разность
    ImDif = double(ImResult) - double(GradO);

    % Вывод на экран
    figure('Name','FPGA_result'); imshow(ImResult);
    figure('Name','MatLab_result'); imshow(GradO);
    figure('Name','Differents'); mesh(ImDif(2:(ImSizeY-1), 2:(ImSizeX-1)));

end