clc;clear;
blocksize = 16;
MSB = 1;
key = 1;
Proportion_tz = 0.6;
Proportion_yc = 0.3;
sigma_E = 10^5;
dbw_noise = 20; %the variance of the noise
BCH_length=63; L=24; T=3000; S=4;
len_skm = 63;
Delta = 400;
md = 63;
aa = Delta/50;


T1 = floor(T/2);
T2 = T - T1;

%read image information
origin3 = imread('1024.jpg'); 
[M,N,Channel] = size(origin3);
%%figure; imshow(origin);

tic;
point1 = floor(Proportion_tz*blocksize*blocksize);
% if mod(floor((Proportion_tz+Proportion_yc)*blocksize*blocksize)-floor(Proportion_tz*blocksize*blocksize),2) == 0
%     point2 = floor((Proportion_tz+Proportion_yc)*blocksize*blocksize);
% else
%     point2 = floor((Proportion_tz+Proportion_yc)*blocksize*blocksize)-1;
% end
Proportion_wy = 1 - Proportion_tz - Proportion_yc;
point2 = floor((Proportion_tz+Proportion_wy)*blocksize*blocksize);
NUM1 = point1;
NUM2 = point2;

Flag = ones(M, N, Channel);
for c = 1 : Channel
for i = 1 : M
    for j = 1 : N
        if blocksize*mod(i-1,blocksize)+mod(j-1, blocksize)+1 <= point1
            if origin3(i,j,c) < aa || origin3(i,j,c) > 255-aa || (origin3(i,j,c) > 127-aa && origin3(i,j,c) < 129+aa)
                Flag(i,j,c) = 0;
            end
        elseif blocksize*mod(i-1,blocksize)+mod(j-1, blocksize)+1 > point2
            Flag(i,j,c) = 0;
        elseif origin3(i,j,c) > 255-aa || origin3(i,j,c) < aa
            Flag(i,j,c) = 0;
        end
    end
end
end
flag = Flag(:);

pre_image3 = RoomReserving(origin3, blocksize, MSB, NUM1, NUM2);
%%figure;imshow(pre_image3);
toc;

tic;
%generate ELUT, SKm, G, SD, A, and delta
ELUT = ELUT_Gen( sigma_E, T ); 
%len_skm = BCH_length+M*N-sum(flag);
G_zero = 1;
while isempty(G_zero) == 0
    G = zeros(T,BCH_length);
    for i=T1+1:T
        j=randi([1,BCH_length]);
        G(i,j)=1;
    end
    sum_G =sum(G);
    G_zero = find(sum_G<S);
end
[SD_w,  A, index] = SD_gen_rgb(flag, md, len_skm);
[SKm, SKm_w] = SKm_Gen(G, md*2, len_skm, S, T1, T, index, BCH_length);
delta = round(Delta * rand(len_skm,1)) - Delta/2;
%delta = zeros(len_skm,1);

img_vec3 = double(pre_image3(:));
img_vec_ori3 = double(origin3(:));

%image encryption
cimg_vec3 = img_vec3;
pad_e = zeros(md*2,1);
for i = 1:md
    for j = 1:S
        pad_e(i) = pad_e(i) + ELUT(SKm((i-1)*S+j));
    end
    cimg_vec3 = cimg_vec3 + pad_e(i) * (SD_w(:,i).*flag); 
end
cimg_vec3 = cimg_vec3 + water_embed_c(img_vec_ori3, A, Delta, delta);
for i = 1:md
    for j = 1:S
        pad_e(i+md) = pad_e(i+md) + ELUT(SKm((i+md-1)*S+j));
    end
    cimg_vec3 = cimg_vec3 + pad_e(i+md) * (-SD_w(:,i).*(flag-1)); 
end
% index = 1;
% for i = BCH_length+1 : len_skm
%     for j = 1:S
%         pad_e(i) = ELUT(SKm((i-1)*S+j));
%     end
%     while flag(index) == 1
%         index = index + 1;
%     end
%     cimg_vec(index) = mod(cimg_vec(index)+pad_e(i),256);
%     index = index + 1;
% end
cimg_vec3 = mod(round(cimg_vec3),256);

%show
cimg_matrix3 = reshape(cimg_vec3,M,N,Channel);
cimg_matrix3 = uint8(cimg_matrix3);
peak_snr_c = psnr(cimg_matrix3, origin3); 
%imwrite(cimg_matrix3,'C:\Users\Administrator\Desktop\04_en.bmp');
%figure; imshow(cimg_matrix3);

AjImage3 = Adjustment(cimg_matrix3, origin3, blocksize, MSB, NUM1);
AjImage3 = Permutation(AjImage3, blocksize, key, 1);
rng('shuffle');
%imwrite(AjImage3,'C:\Users\Administrator\Desktop\04_aj.bmp');
figure; imshow(AjImage3);
toc;

tic;
%generate the fingerprint b_k
b = randi([0,1],L,1);
[kk, t, a, b_encode] = BCH_encode(b, BCH_length);
b_encode = b_encode * 2 - 1;

%compute D-LUT
WLUT =  floor(Delta/(4*S)) * G * (b_encode');
% for i = 1:T
%     if WLUT(i) == 1
%         temp = rand();
%         %WLUT(i) = WLUT(i)*5;
%         WLUT(i) = WLUT(i)*ceil((temp^3)*4);
%     end       
% end
DLUT = -ELUT + WLUT;
%DLUT = -ELUT;
toc;

tic;
%decrypt the image
AjImage3 = Permutation(AjImage3, blocksize, key, -1);
rng('shuffle');
ajimg_vec3 = double(AjImage3(:));
wing_vec3 = ajimg_vec3;
pad_d = zeros(md*2,1);
for i = 1:md
    for j = 1:S
        pad_d(i) = pad_d(i) + DLUT(SKm((i-1)*S+j));
    end
    wing_vec3 = wing_vec3 + pad_d(i) * (SD_w(:,i).*flag); 
end
for i = 1:md
    for j = 1:S
        pad_d(i+md) = pad_d(i+md) + DLUT(SKm((i+md-1)*S+j));
    end
    wing_vec3 = wing_vec3 + pad_d(i+md) * (-SD_w(:,i).*(flag-1)); 
end
wing_vec3 = mod(round(wing_vec3),256);
wimg_matrix3 = reshape(wing_vec3,M,N,Channel);
wimg_matrix3 = uint8(wimg_matrix3);
clear SD_w
%figure; imshow(wimg_matrix3);

rec_image3 = Recovery( wimg_matrix3, blocksize, MSB, NUM1, NUM2);
peak_snr_w = psnr(rec_image3, origin3); 
%imwrite(rec_image3,'C:\Users\Administrator\Desktop\04_re.bmp');
%figure;imshow(rec_image3);
toc;

recimg_vec3 = double(rec_image3(:));
recimg_noise3 = awgn(double(rec_image3), -dbw_noise); %generate Gaussian noise
recimg_noise3 = uint8(recimg_noise3);
%figure;imshow(recimg_noise3);
peak_snr_wn = psnr(recimg_noise3, origin3);
recimgvec_noise3 = double(recimg_noise3(:));

tic;
%arbitration
Bm =  Bm_Gen(len_skm*2, T, S, SKm_w );
b_encode = b_encode';
G = G(T1+1:T,:);
% arbitration = detection_my(Bm, G, A, recimg_vec3, b, b_encode, Delta, delta, kk, t, a, L);
% % b_arbb = b_arbb';
% if arbitration == 1
%     disp("无噪声情况下水印提取成功");
% else
%     disp("无噪声情况下水印提取失败");
% end


arbitration_n = detection_my(Bm, G, A, recimgvec_noise3, b, b_encode, Delta, delta, kk, t, a, L);
%b_arbb2 = b_arbb2';
if arbitration_n == 1
    disp("有噪声情况下水印提取成功");
else
    disp("有噪声情况下水印提取失败");
end
toc;

sum = 0;
for i = 1:M
    for j= 1:N
        for k = 1 : Channel
            if rec_image3(i,j,k)~=origin3(i,j,k) && Flag(i,j,k) == 0
                sum=sum+1;
            end
        end
    end
end
















