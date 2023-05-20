function [locatex, locatey, bits, res] = Prediction(x0,x1,x2,x3,x4,x5,x6, x, y, type, beta, labels, locatex, locatey, bits)
    x0_d = double(x0);
    x1_d = double(x1);
    x2_d = double(x2);
    x3_d = double(x3);
    x4_d = double(x4);
    x5_d = double(x5);
    x6_d = double(x6);
    if type == 0 % x-1 -> x
        error = x0_d - x1_d;
    elseif type == 1 % x+1 -> x
        error = x0_d - x2_d;
    elseif type == 2 % y-1 -> y
        error = x0_d - x3_d;
    elseif type == 3 % y+1 -> y
        error = x0_d - x4_d;
    elseif type == 4
        min = x1;
        max = x3;
        if min > x3
            min = x3;
            max = x1;
        end
        if x5 < min
            pred = max;
        elseif x5 > max
            pred = min;
        else
            pred = x1_d + x3_d - x5_d;
        end
        error = x0_d - double(pred);  
    elseif type == 5
        min = x2;
        max = x4;
        if min > x4
            min = x4;
            max = x2;
        end
        if x6 < min
            pred = max;
        elseif x6 > max
            pred = min;
        else
            pred = x2_d + x4_d - x6_d;
        end
        error = x0_d - double(pred);
    end
    [range,alpha] = size(labels);
    if ceil(-range/2) <= error && error <= floor((range-1)/2)
        index = error - ceil(-range/2) + 1;
        label = labels(index,:);
        tmp = '00000000';
        tmp(1:alpha) = label(:);
        res = bin2dec(tmp);
        [~,no] = size(locatex);
        locatex(no+1) = x;
        locatey(no+1) = y;
    else
        [~,l] = size(bits);
        tmp = Dec2bin(x0,8);
        bits(l+1:l+beta) = tmp(1:beta);
        tmp(1:beta) = '0';
        res = bin2dec(tmp);
    end  
end

