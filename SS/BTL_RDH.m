%file: BTL_RDH.m
%function: the third data hiding method to embedding the data for recovery
%origin: the original image
%blocksieze: the blocksize for embedding (type==1)
%NUM: the number of pixels that the adjustment area contains (type==1)
%     no meaning (type==0 or type==2)
%type: illustrate the distribution of the adjustment areas.
%      2 means others
%      1 means the embedding areas are in every block
%      0 means unblocking and the whole block can be adjusted
%edge: in order to distinguish between the two distribution of areas, 0 for type 1 and others for type 0
%data: the data to be embeded

function res = BTL_RDH( origin, blocksize, MSB, NUM, data)
res = origin;
alpha = 3;
beta = 2;
if alpha <= beta
    labels = dec2bin(1:2^alpha-1);
else
    labels = dec2bin(2^(alpha-beta):2^alpha-1);
end
[M,N,C] = size(origin);
for channel = 1 : 1 : C
    locatex = [];
    locatey = [];
    bits = [];
    origin_c = origin(:,:,channel);
    % the special condition (the pixels are locating at the boundary)
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
                x0 = origin_c(i,y);x1 = 0;x2 = origin_c(i+1,y);x3 = 0;x4 = 0;x5 = 0;x6 = 0;
                [locatex,locatey,bits,res(i,y,channel)] = Prediction(x0,x1,x2,x3,x4,x5,x6,i,y,1,beta,labels,locatex,locatey,bits);
            end
            for j = y-1 : -1 : y-blocksize+1
                x0 = origin_c(x,j);x1 = 0;x2 = 0;x3 = 0;x4 = origin_c(x,j+1);x5 = 0;x6 = 0;
                [locatex,locatey,bits,res(x,j,channel)] = Prediction(x0,x1,x2,x3,x4,x5,x6,x,j,3,beta,labels,locatex,locatey,bits);
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
                    x0 = origin_c(i,j);x1 = 0;x2 = origin_c(i+1,j);x3 = 0;x4 = origin_c(i,j+1);x5 = 0;x6 = origin_c(i+1,j+1);
                    [locatex,locatey,bits,res(i,j,channel)] = Prediction(x0,x1,x2,x3,x4,x5,x6,i,j,5,beta,labels,locatex,locatey,bits);
                    count = count + 1;
                end
            end
        end
    end
    data = Encode(data,MSB);
    [~,l] = size(data);
    data = Compression(l,data,1);
    [~,l1] = size(data);
    [~,l2] = size(bits);
    data(l1+1:l1+l2) = bits(1:l2); % the whole information to be embedded
    [~,len] = size(locatex);
    capacity = len*(8-alpha); % caculate the embedding capacity
    %capacity,l1+l2
    disp(['Available capacity = ', num2str(capacity-l2)])
    disp(['Required capacity = ', num2str(l1)])
    % padding the data into length being the same as the capacity
    data (l1+l2+1) = '1';
    data(l1+l2+2:capacity) = '0';
    % embedding the information into marked pixels
    no = 1; % index of the data
    for index = 1 : 1 : len
        temp = Dec2bin(res(locatex(index),locatey(index),channel),8);
        temp(alpha+1:8) = data(no:no+7-alpha);
        res(locatex(index),locatey(index),channel) = bin2dec(temp);
        no = no + 8-alpha;
    end
end
end

