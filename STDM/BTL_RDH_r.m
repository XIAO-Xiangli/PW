%file: BTL_RDH_r.m
%function: extracting the embedded data and recover the embedding area
%origin: the original image
%blocksieze: the blocksize for embedding (type==1)
%NUM: the number of pixels that the adjustment area contains (type==1)
%     no meaning (type==0 or type==2)
%type: illustrate the distribution of the adjustment areas.
%      2 means others
%      1 means the embedding areas are in every block
%      0 means unblocking and the whole block can be adjusted
%edge: in order to distinguish between the two distribution of areas, 0 for type 1 and others for type 0

function [datas,res] = BTL_RDH_r( origin, blocksize, MSB, NUM1, NUM)
res = origin;
alpha = 3;
beta = 2;
if alpha <= beta
    labels = dec2bin(1:2^alpha-1);
else
    labels = dec2bin(2^(alpha-beta):2^alpha-1);
end
[M,N,C] = size(origin);
datas = [];
for channel = 1 : 1 : C
    bits = []; %  store the high beta bits of pixels belong to Pn for recovery
    res_c = res(:,:,channel);
    length = NUM1 * MSB * M/blocksize * N/blocksize;
    m = M/blocksize;
    n = N/blocksize;
    for p = 1 : 1 : m
        for q = 1 : 1 : n
            % the location of the right down pixel in the block
            x = p * blocksize;
            y = q * blocksize;
            if mod(NUM,blocksize) == 0
                a = x - blocksize + NUM/blocksize + 1;
            else
                a = x - blocksize + ceil(NUM/blocksize);
            end
            for i = x-1 : -1 : a
                bin = Dec2bin(origin(i,y,channel),8);
                com(1:beta) = '0';
                if strcmp(bin(1:beta),com(1:beta)) ~= 1
                    [~,l] = size(bits);
                    bits(l+1:l+8-alpha) = bin(alpha+1:8);
                end
            end
            for j = y-1 : -1 : y-blocksize+1
                bin = Dec2bin(origin(x,j,channel),8);
                com(1:beta) = '0';
                if strcmp(bin(1:beta),com(1:beta)) ~= 1
                    [~,l] = size(bits);
                    bits(l+1:l+8-alpha) = bin(alpha+1:8);
                end
            end
            % the common condition
            count = 2*blocksize-floor(NUM/blocksize);
            for i = x-1 : -1 : x-blocksize+1
                if count > blocksize*blocksize-NUM
                    break;
                end
                for j = y-1 : -1 : y-blocksize+1
                    if count > blocksize*blocksize-NUM
                        break;
                    end
                    bin = Dec2bin(origin(i,j,channel),8);
                    com(1:beta) = '0';
                    if strcmp(bin(1:beta),com(1:beta)) ~= 1
                        [~,l] = size(bits);
                        bits(l+1:l+8-alpha) = bin(alpha+1:8);
                    end
                    count = count + 1;
                end
            end
        end
    end
    [~,l] = size(bits);
    for i = l : -1 : 1
        if bits(i) == '1'
            bits = bits(1:i-1);
            break;
        end
    end
    bits = Decompression(length,bits,1);
    data = Decode(bits(1:length),MSB);
    % recovering high beta bits of pixels with beta labels
    no = length+1; % index of the bits
    m = M/blocksize;
    n = N/blocksize;
    for p = 1 : 1 : m
        for q = 1 : 1 : n
            % the location of the right down pixel in the block
            x = p * blocksize;
            y = q * blocksize;
            if mod(NUM,blocksize) == 0
                a = x - blocksize + NUM/blocksize + 1;
            else
                a = x - blocksize + ceil(NUM/blocksize);
            end
            for i = x-1 : -1 : a
                x0 = res_c(i,y);x1 = 0;x2 = res_c(i+1,y);x3 = 0;x4 = 0;x5 = 0;x6 = 0;
                [no,res_c(i,y)] = Reduction(x0,x1,x2,x3,x4,x5,x6, 1, beta, labels, bits, no);
            end
            for j = y-1 : -1 : y-blocksize+1
                x0 = res_c(x,j);x1 = 0;x2 = 0;x3 = 0;x4 = res_c(x,j+1);x5 = 0;x6 = 0;
                [no,res_c(x,j)] = Reduction(x0,x1,x2,x3,x4,x5,x6, 3, beta, labels, bits, no);
            end
            % the common condition
            count = 2*blocksize-floor(NUM/blocksize);
            for i = x-1 : -1 : x-blocksize+1
                if count > blocksize*blocksize-NUM
                    break;
                end
                for j = y-1 : -1 : y-blocksize+1
                    if count > blocksize*blocksize-NUM
                        break;
                    end
                    x0 = res_c(i,j);x1 = 0;x2 = res_c(i+1,j);x3 = 0;x4 = res_c(i,j+1);x5 = 0;x6 = res_c(i+1,j+1);
                    [no,res_c(i,j)] = Reduction(x0,x1,x2,x3,x4,x5,x6, 5, beta, labels, bits, no);
                    count = count + 1;
                end
            end
        end
    end
    res(:,:,channel) = res_c;
    [~,l] = size(datas);
    datas(l+1:l+length) = data(1:length);
end
end

