function [no,res] = Reduction(x0,x1,x2,x3,x4,x5,x6, type, beta, labels, bits, no)
    x1_d = double(x1);
    x2_d = double(x2);
    x3_d = double(x3);
    x4_d = double(x4);
    x5_d = double(x5);
    x6_d = double(x6);
    res = x0;
    [range,alpha] = size(labels);
    bin = Dec2bin(x0,8);
    com(1:beta) = '0';
    if strcmp(bin(1:beta),com(1:beta)) == 1
        bin(1:beta) = bits(no:no+beta-1);
        res = bin2dec(bin);
        no = no + beta;
    else
        error = double(bin2dec(bin(1:alpha))) - double(bin2dec(labels(1,:))) + double(ceil(-range/2));
        if type == 0 % x-1 -> x
            res = x1_d + error;
        elseif type == 1 % x+1 -> x
            res = x2_d + error;
        elseif type == 2 % y-1 -> y
            res = x3_d + error;
        elseif type == 3 % y+1 -> y
            res = x4_d + error;
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
            res = double(pred) + error;  
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
            res = double(pred) + error;
        end
    end
end
