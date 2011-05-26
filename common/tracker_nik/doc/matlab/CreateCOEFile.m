function Result = CreateCOEFile(FileName)
    DeltaY = zeros(256 * 256, 1);
    DeltaX = zeros(256 * 256, 1);
    M = zeros(256, 256);
    for i = 0:255
        for j = 0:255
        DeltaY(256 * i + j + 1) = i;
        DeltaX(256 * i + j + 1) = j;
        M(i + 1, j + 1) = CalcAlpha(j, i);
        end;
    end;
    Alpha = CalcAlpha(DeltaX, DeltaY);
    fid = fopen(FileName,'w');
    fwrite(fid, 'Memory_Initialization_Radix=10;');
    fwrite(fid, [013 010]);
    fwrite(fid, 'Memory_Initialization_Vector=');
    fwrite(fid, [013 010]);
    for i = 1:max(size(Alpha))-1
        fwrite(fid, int2str(Alpha(i)));
        fwrite(fid, ','); 
        fwrite(fid, [013 010]);        
    end
    fwrite(fid, int2str(Alpha(max(size(Alpha)))));
    fwrite(fid, ';'); 
    fwrite(fid, [013 010]);       
    fclose(fid);

    Result = M;
end

function Result = CalcAlpha(DeltaX, DeltaY)
    Size = 1;
    if size(DeltaX) ~= size(DeltaY)
        Return = 0;
        return;
    else
        Size = max(size(DeltaX));
    end;
    for i = 1:Size
        R = 0;
        if DeltaX(i) == 0 && DeltaY(i) == 0
            R = 0;
        elseif DeltaX(i) == 0 && DeltaY(i) >= 0
            R = 0;
        else
            R = double(128.0 * atan(double(DeltaY(i)) / double(DeltaX(i))) / pi);
        end;
        Result(i) = uint8(floor(R));
    end;
end