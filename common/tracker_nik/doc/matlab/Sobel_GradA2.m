%------------------------------------------------------------------------
%Расчет градиента яркости:
% ImSrc -------- входное изображение
% TDelta_calc -- тип нахождения dX,dY (если 1, то dXm,dYm делим на 2;
%                                      если 0, то dXm,dYm НЕ делим на 2)
% TGradA_calc -- тип апрксимации (dx^2 + dy^2)^0.5 (0/1 - грубая/точная)
%------------------------------------------------------------------------
function Result = Sobel_GradA2(ImSrc, TDelta_calc, IP1, IP2) %, TGradA_calc
    %Зануляем массив результата
    Result = zeros(size(ImSrc), 'uint8');

%     dXm_dbg = zeros(size(ImSrc), 'uint16');
%     dYm_dbg = zeros(size(ImSrc), 'uint16');

    %Вычисления
    for i=2:size(ImSrc, 1) - 1
        for j=2:size(ImSrc, 2) - 1

            dX1 = int16(ImSrc(i - 1, j - 1)) + 2 * int16(ImSrc(i - 1, j)) + int16(ImSrc(i - 1, j + 1));
            dX2 = int16(ImSrc(i + 1, j - 1)) + 2 * int16(ImSrc(i + 1, j)) + int16(ImSrc(i + 1, j + 1));

            dY1 = int16(ImSrc(i - 1, j - 1)) + 2 * int16(ImSrc(i, j - 1)) + int16(ImSrc(i + 1, j - 1));
            dY2 = int16(ImSrc(i - 1, j + 1)) + 2 * int16(ImSrc(i, j + 1)) + int16(ImSrc(i + 1, j + 1));

            %Вычисляем модуль
            dXm = 0;
            if dX1 > dX2
            dXm = int16(dX1) - int16(dX2);
            else
            dXm = int16(dX2) - int16(dX1);
            end;

            dYm = 0;
            if dY1 > dY2
            dYm = int16(dY1) - int16(dY2);
            else
            dYm = int16(dY2) - int16(dY1);
            end;

            if TDelta_calc==1
              dXdiv = double(dXm)/2;
              dYdiv = double(dYm)/2;

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

            %Нормирование результата
            if GradA >= 255
                GradA = 255;
            else
                GradA = uint8(GradA);
            end;

            if (IP2>=GradA) && (GradA >= IP1)
              Result(i,j) = uint8(GradA);
            end;

        end;%for(j)
    end;%for(i)

%     dXm_vdbg = dXm_dbg
%     dYm_vdbg = dYm_dbg
end

