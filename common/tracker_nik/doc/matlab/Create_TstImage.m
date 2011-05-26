%------------------------------------------------------------------------
%------------------------------------------------------------------------
function Result = Create_TstImage(ImSizeX, ImSizeY) %, TGradA_calc
    %Зануляем массив результата
    Result = zeros((ImSizeX), 'uint8');
    A=0;
    %Вычисления
    for i=1:size(Result, 1)
        for j=1:size(Result, 2)
            Result(i,j) = A;
            A=A+1;
            if A>=256 
                A=0
            end;
        end;%for(j)
    end;%for(i)
end

