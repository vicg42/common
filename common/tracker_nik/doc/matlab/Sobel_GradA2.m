%------------------------------------------------------------------------
%Расчет градиента яркости:
% ImSrc -------- входное изображение
% TDelta_calc -- тип нахождения dX,dY (если 1, то dXm,dYm делим на 2;
%                                      если 0, то dXm,dYm НЕ делим на 2)
% TGradA_calc -- тип апрксимации (dx^2 + dy^2)^0.5 (0/1 - грубая/точная)
%------------------------------------------------------------------------
function Result = Sobel_GradA2(ImSrc, TDelta_calc, IP1, IP2) %, TGradA_calc
    %Зануляем массив результата
    Result.A   = zeros(size(ImSrc), 'uint8');%Амплитуда градиента яркости: все точки
    Result.Aip = zeros(size(ImSrc), 'uint8');%Амплитуда градиента яркости: Только точки попавшие в дапозон порогового итервала(IP)

    Result.dXm = zeros(size(ImSrc), 'uint16');%Нормированиые значения модулей. Для расчета табличных значений угла град. ярк.
    Result.dYm = zeros(size(ImSrc), 'uint16');

    Result.dXs = zeros(size(ImSrc), 'int16');%Не нормированиые значения. Для расчета направления град. яркости.
    Result.dYs = zeros(size(ImSrc), 'int16');

%     dXm_dbg = zeros(size(ImSrc), 'uint16');
%     dYm_dbg = zeros(size(ImSrc), 'uint16');

    %Вычисления
    for i=2:size(ImSrc, 1) - 1
        for j=2:size(ImSrc, 2) - 1

            dX1 = int16(ImSrc(i - 1, j - 1)) + 2 * int16(ImSrc(i - 1, j)) + int16(ImSrc(i - 1, j + 1));
            dX2 = int16(ImSrc(i + 1, j - 1)) + 2 * int16(ImSrc(i + 1, j)) + int16(ImSrc(i + 1, j + 1));

            dY1 = int16(ImSrc(i - 1, j - 1)) + 2 * int16(ImSrc(i, j - 1)) + int16(ImSrc(i + 1, j - 1));
            dY2 = int16(ImSrc(i - 1, j + 1)) + 2 * int16(ImSrc(i, j + 1)) + int16(ImSrc(i + 1, j + 1));

            %--------------------------------------
            %Конвертация в соответствии с требование Никифорова от 03.06.2011
            %--------------------------------------
            dX1_tmp = dX1;
            dX2_tmp = dX2;
            dY1_tmp = dY1;
            dY2_tmp = dY2;
            dY2=dX1_tmp;
            dY1=dX2_tmp;
            dX2=dY1_tmp;
            dX1=dY2_tmp;
            %--------------------------------------


            %Вычисляем модуль
            dXm = 0;
            dYm = 0;
            if dX1 > dX2
            dXm = int16(dX1) - int16(dX2);
            else
            dXm = int16(dX2) - int16(dX1);
            end;

            if dY1 > dY2
            dYm = int16(dY1) - int16(dY2);
            else
            dYm = int16(dY2) - int16(dY1);
            end;


            %dXs,dYs - знаковые значения
            dXs = dX1 - dX2;
            dYs = dY2 - dY1;%dYs = dY1 - dY2;


            if TDelta_calc==1
              dXdiv = double(dXm)/2;
              dYdiv = double(dYm)/2;

              dXsdiv = double(dXs)/2;
              dYsdiv = double(dYs)/2;

              dXs = fix(dXsdiv);%Отбрасываем дробную часть
              dYs = fix(dYsdiv);%Отбрасываем дробную часть

              dXm = fix(dXdiv);%Отбрасываем дробную часть
              dYm = fix(dYdiv);%Отбрасываем дробную часть
            end;

%             dXm_dbg(i,j) = uint16(dXm);
%             dYm_dbg(i,j) = uint16(dYm);

%            if TGradA_calc==0
%              GradA = uint16(dXm) + uint16(dYm);
%            else
              GradA = uint16( bitshift(uint16(123 * uint16(max(dXm, dYm))), -7)) + uint16(bitshift(uint16(13 * uint16(min(dXm, dYm))), -5));
              %где
              %(-7) это сдвиг на 7 бит вправо(деление на 128)
              %(-5) это сдвиг на 5 бит вправо(деление на 32)
%            end;

            %Нормирование амплитуды Градиента яркости:
            if GradA >= 255
                GradA = 255;
            else
                GradA = uint8(GradA);
            end;


            if (IP2>=GradA) && (GradA >= IP1)
              Result.Aip(i,j) = uint8(GradA);
            end;

            Result.A(i,j)   = uint8(GradA);


            %Нормирование значений модуля
            if dXm > 255
                dXm = 255;
            end;

            if dYm > 255
                dYm = 255;
            end;
            Result.dXm(i,j) = dXm;
            Result.dYm(i,j) = dYm;
            Result.dXs(i,j) = dXs;
            Result.dYs(i,j) = dYs;


        end;%for(j)
    end;%for(i)

%     dXm_vdbg = dXm_dbg
%     dYm_vdbg = dYm_dbg
end

