%------------------------------------------------------------------------
% Сравнение изображений.
% SrcImage ------ исходное изображение
% FpgaResImage -- результат обработки FPGA
%------------------------------------------------------------------------
function Check_Image(SrcImage, FpgaResImage)
    % Читаем изображения
    ImSrc = imread(SrcImage);
    ImResult = imread(FpgaResImage);

    % вычисляем разность
    ImDif = double(ImResult) - double(ImResult);

    % Вывод на экран
    figure('Name','FPGA_result'); imshow(ImResult);
    figure('Name','ImSrc'); imshow(ImSrc);
    figure('Name','Differents'); mesh(ImDif(2:1023, 2:1023));

end