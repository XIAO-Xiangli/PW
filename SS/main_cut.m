  clc;clear;
blocksize = 8;
MSB = 1;
key = 1;
Proportion_tz = 0.6;
Proportion_yc = 0.3;
sigma_E = 255;
cutting_row = 100;
cutting_column = 100;
BCH_length=63; L=24; T=3000; S=2;
aa = 16;

T1 = floor(T * Proportion_yc);
T2 = T - T1;

%read image information
origin = imread('03.png'); 
[M,N,C] = size(origin);

point1 = floor(Proportion_tz*blocksize*blocksize);
% if mod(floor((Proportion_tz+Proportion_yc)*blocksize*blocksize)-floor(Proportion_tz*blocksize*blocksize),2) == 0
%     point2 = floor((Proportion_tz+Proportion_yc)*blocksize*blocksize);
% else
%     point2 = floor((Proportion_tz+Proportion_yc)*blocksize*blocksize)-1;
% end
point2 = floor((Proportion_tz+Proportion_yc)*blocksize*blocksize);
NUM1 = point1;
NUM2 = point2;

Flag = ones(M, N);
for i = 1 : M
    for j = 1 : N
        if blocksize*mod(i-1,blocksize)+mod(j-1, blocksize)+1 <= point1
            if origin(i,j) < aa || origin(i,j) > 255-aa || (origin(i,j) > 127-aa && origin(i,j) < 129+aa)
                Flag(i,j) = 0;
            end
        elseif blocksize*mod(i-1,blocksize)+mod(j-1, blocksize)+1 > point2
            Flag(i,j) = 0;
        elseif origin(i,j) > 255-aa || origin(i,j) < aa
            Flag(i,j) = 0;
        end
    end
end
flag = Flag(:);

%generate ELUT, SKm, and G
ELUT = ELUT_Gen( sigma_E, T ); 
SKm = SKm_Gen(M*N, T1, T2, S, flag);
G = zeros(T,BCH_length);
for i=T1+1:T
    j=randi([1,BCH_length]);
    G(i,j)=1;
end

pre_image = RoomReserving(origin, blocksize, MSB, NUM1, NUM2);
%figure;imshow(pre_image);

img_vec = double(pre_image(:));
img_vec_ori = double(origin(:));

%image encryption
cimg_vec = zeros(M*N, 1);
pad_e = zeros(M*N,1);
for i = 1:M*N
    for j = 1:S
        pad_e(i) = ELUT(SKm((i-1)*S+j));
    end
    cimg_vec(i) = mod((img_vec(i)+pad_e(i)),256); 
end

%show
cimg_matrix = reshape(cimg_vec,M,N);
cimg_matrix = uint8(cimg_matrix);
peak_snr_c = psnr(cimg_matrix, origin); 
%imwrite(c_ing,'C:\Users\肖祥立\Desktop\figure\04_en.bmp');
% figure; imshow(cimg_matrix);

AjImage = Adjustment(cimg_matrix, origin, blocksize, MSB, NUM1);
AjImage = Permutation(AjImage, blocksize, key, 1);
rng('shuffle');
%figure; imshow(AjImage);

%generate the fingerprint b_k
b = randi([0,1],L,1);
[kk, t, a, b_encode] = BCH_encode(b, BCH_length);
b_encode = b_encode * 2 - 1;

%compute D-LUT
WLUT = floor(aa/S) * G * (b_encode');
% for i =1:T
%     if WLUT(i) == 1
%         temp = rand();
%         %WLUT(i) = WLUT(i)*5;
%         WLUT(i) = WLUT(i)*ceil((temp^3)*16);
%     end       
% end
DLUT = -ELUT + WLUT;
% DLUT = -ELUT;

%decrypt the image
AjImage = Permutation(AjImage, blocksize, key, -1);
rng('shuffle');
ajimg_vec = double(AjImage(:));
wing_vec = zeros(M*N, 1);
pad_d = zeros(M*N,1);
for i = 1:M*N
    for j = 1:S
        pad_d(i) = DLUT(SKm((i-1)*S+j));
    end
    wing_vec(i) = mod((ajimg_vec(i) + pad_d(i)),256); 
end
wimg_matrix = reshape(wing_vec,M,N);
wimg_matrix = uint8(wimg_matrix);
% figure; imshow(wimg_matrix);

rec_image = Recovery( wimg_matrix, blocksize, MSB, NUM1, NUM2);
peak_snr_w = psnr(rec_image, origin); 
%figure;imshow(rec_image);

recimg_noise = rec_image;
for i = 1 : M
    for j = 1 : N
        if i > M - cutting_row || j > N - cutting_row
            recimg_noise(i,j) = origin(i,j);   %检测时候可以根据原始图像恢复原始像素
        end
    end
end

recimg_vec = double(rec_image(:));
% recimg_noise = awgn(double(rec_image), -dbw_noise); %generate Gaussian noise
% recimg_noise = uint8(recimg_noise);
peak_snr_wn = psnr(recimg_noise, origin);
recimgvec_noise = double(recimg_noise(:));

%arbitration
Bm =  Bm_Gen(M*N, S, SKm);
b_encode = b_encode';
arbitration = detection_my(Bm, G, recimg_vec, img_vec, b, b_encode, flag, kk, t, a, L);
% b_arbb = b_arbb';
if arbitration == 1
    disp("无剪切情况下水印提取成功");
else
    disp("无剪切情况下水印提取失败");
end


arbitration_n = detection_my(Bm, G, recimgvec_noise, img_vec, b, b_encode, flag, kk, t, a, L);
%b_arbb2 = b_arbb2';
if arbitration_n == 1
    disp("有剪切情况下水印提取成功");
else
    disp("有剪切情况下水印提取失败");
end

sum = 0;
for i = 1:M
    for j= 1:N
        if rec_image(i,j)~=origin(i,j) && Flag(i,j) == 0
            sum=sum+1;
        end
    end
end
















