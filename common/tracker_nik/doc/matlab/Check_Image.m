%------------------------------------------------------------------------
% Сравнение изображений.
% SrcImage ------ исходное изображение
% FpgaResImage -- результат обработки FPGA
%------------------------------------------------------------------------
function Check_Image(SrcImage, FpgaResImage)
    % Читаем изображения
    ImSrc = imread(SrcImage);
    ImFPGA = imread(FpgaResImage);

    % вычисляем разность
    ImDif = double(ImSrc) - double(ImFPGA);

    % Вывод на экран
    figure('Name','FPGA_result'); imshow(ImFPGA);
    figure('Name','ImSrc'); imshow(ImSrc);
    figure('Name','Differents'); mesh(ImDif(2:1023, 2:1023));

end