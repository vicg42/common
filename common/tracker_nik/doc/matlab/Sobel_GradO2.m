%------------------------------------------------------------------------
%Расчет направления(ориентации)градиента яркости:
% ImSrc -------- входное изображение
% TDelta_calc -- тип нахождения dX,dY (если 1, то dXm,dYm; dXs,dYs делим на 2;
%                                      если 0, то dXm,dYm; dXs,dYs НЕ делим на 2)
% TGradO_calc -- варианты вычисления направления градиента яркости
%------------------------------------------------------------------------
function Result = Sobel_GradO2(ImSrc, TDelta_calc, TGradO_calc, IP1, IP2)
    %Зануляем массив результата
    Result = zeros(size(ImSrc), 'uint16');

%    dXm_dbg = zeros(size(ImSrc), 'uint16');
%    dYm_dbg = zeros(size(ImSrc), 'uint16');
%    dXs_dbg = zeros(size(ImSrc), 'int16');
%    dYs_dbg = zeros(size(ImSrc), 'int16');

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
              dXmdiv = double(dXm)/2;
              dYmdiv = double(dYm)/2;

              dXm = fix(dXmdiv);%Отбрасываем дробную часть
              dYm = fix(dYmdiv);%Отбрасываем дробную часть
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

%            dXm_dbg(i,j) = uint16(dXm);
%            dYm_dbg(i,j) = uint16(dYm);

            %Нормирование значений модуля
            if dXm > 255
                dXm = 255;
            end;

            if dYm > 255
                dYm = 255;
            end;


            %dXs,dYs - знаковые значения
            dXs = dX1 - dX2;
            dYs = dY2 - dY1;%dYs = dY1 - dY2;

            if TDelta_calc==1
              dXsdiv = double(dXs)/2;
              dYsdiv = double(dYs)/2;

              dXs = fix(dXsdiv);%Отбрасываем дробную часть
              dYs = fix(dYsdiv);%Отбрасываем дробную часть
            end;

%             dXs_dbg(i,j) = int16(dXs);
%             dYs_dbg(i,j) = int16(dYs);

            %Если необходимо производи масштабирование
            if (dXs < -255) || (dXs > 255)
                dXs = double(dXs) * 0.625;
                dXs = fix(dXs);%Отбрасываем дробную часть

                if dXs > 255
                    dXs = 255;
                elseif dXs < -255
                    dXs = -255;
                end;
            end;

            if (dYs < -255) || (dYs > 255)
                dYs = double(dYs) * 0.625;
                dYs = fix(dYs);%Отбрасываем дробную часть

                if dYs > 255
                    dYs = 255;
                elseif dYs < -255
                    dYs = -255;
                end;
            end;


            %Вычисляем угол
%            A = M(dX_offset,dY_offset);
            R = 0;
            if dXm == 0 && dYm == 0
              R = 0;
            elseif dXm == 0 && dYm >= 0
              R = 0;
            else
              R = double(128.0 * atan(double(dYm) / double(dXm)) / pi);
            end;
            A = uint8(floor(R));%Округление результатаб до ближайшего целого меньшего или равного R
                                %(B = floor(A) rounds the elements of A to the nearest integers less than or equal to A.)


            if (IP2>=GradA) && (GradA >= IP1)

                %Расчет направления(ориентации)градиента яркости:
                if TGradO_calc==0
                %Никифоров Вариант от 03/06/2011
                    if      (dYs == 0)  && (dXs == 0)
                      Result(i,j) = 0;

                    elseif  (dXs == 0)  && (dYs > 0)
                      Result(i,j) = 192;
                    elseif  (dXs == 0)  && (dYs < 0)
                      Result(i,j) = 64;

                    elseif  (dXs > 0)  && (dYs == 0)
                      Result(i,j) = 128;
                    elseif  (dXs < 0)  && (dYs == 0)
                      Result(i,j) = 0;

                    elseif  (dYs > 0)  && (dXs > 0)
                      Result(i,j) = 128 + A;
                    elseif  (dYs > 0)  && (dXs < 0)
                    %Странное поведение MatLab:
                    %x=8bit
                    %x=256 - 0 почемуто = 255, а ведь должно быть 0
                    %поэтому делаю проверку переменной А
                         if A==0
                             Result(i,j) = 0;
                         else
                            Result(i,j) = 256 - A;
                         end;
                    elseif  (dYs < 0)  && (dXs < 0)
                      Result(i,j) = A;
                    elseif  (dYs < 0)  && (dXs > 0)
                      Result(i,j) = 128 - A;
                    end;


                elseif TGradO_calc==1
                %ТЗ Вариант1
                    if      (dXs < 0)  && (dYs >= 0)
                        Result(i,j) = A;

                    elseif  (dXs > 0)  && (dYs > 0)
                        Result(i,j) = 128 - A;

                    elseif  (dXs == 0) && (dYs > 0)
                        Result(i,j) = 64;

                    elseif  (dXs > 0)  && (dYs <= 0)
                        Result(i,j) = 128 + A;

                    elseif  (dXs < 0)  && (dYs < 0)
                    %Странное поведение MatLab:
                    %x=8bit
                    %x=256 - 0 почемуто = 255, а ведь должно быть 0
                    %поэтому делаю проверку переменной А
                         if A==0
                             Result(i,j) = 0;
                         else
                            Result(i,j) = 256 - A;
                         end;

                    elseif  (dXs == 0) && (dYs < 0)
                        Result(i,j) = 192;

                    else%elseif (dXs(i,j) == 0) && (dYs(i,j) == 0)
                        Result(i,j) = 0;
                    end;

                else
                %ТЗ Вариант2
                    if      (dXs < 0)  && (dYs >= 0)
                        Result(i,j) = 128 + A;

                    elseif  (dXs > 0)  && (dYs > 0)
                    %Странное поведение MatLab:
                    %x=8bit
                    %x=256 - 0 почемуто = 255, а ведь должно быть 0
                    %поэтому делаю проверку переменной А
                         if A==0
                             Result(i,j) = 0;
                         else
                            Result(i,j) = 256 - A;
                         end;

                    elseif  (dXs == 0) && (dYs > 0)
                        Result(i,j) = 192;

                    elseif  (dXs > 0)  && (dYs <= 0)
                        Result(i,j) = A;

                    elseif  (dXs < 0)  && (dYs < 0)
                        Result(i,j) = 128 - A;

                    elseif  (dXs == 0) && (dYs < 0)
                        Result(i,j) = 64;

                    else%elseif (dXs(i,j) == 0) && (dYs(i,j) == 0)
                        Result(i,j) = 0;
                    end;

                end;%if TGradO_calc

            end;%if (PI2>=GradA) && (GradA >= IP1)

        end;%for(j)
    end;%for(i)

%    dXm_vdbg = dXm_dbg
%    dYm_vdbg = dYm_dbg
%    dXs_vdbg = dXs_dbg
%    dYs_vdbg = dYs_dbg

end
