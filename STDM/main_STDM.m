clc;clear;
blocksize = 8;
MSB = 1;
key = 1;
Proportion_tz = 0.4;
Proportion_yc = 0.45;
sigma_E = 10^5;
dbw_noise = 20; %the variance of the noise
BCH_length=63; L=24; T=3000; S=4;
len_skm = 70;
Delta = 64;
md = 126;
aa = Delta/4;

% 
T1 = floor(T/2);
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
Proportion_wy = 1 - Proportion_tz - Proportion_yc;
point2 = floor((Proportion_tz+Proportion_wy)*blocksize*blocksize);
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
[SD_w, SD_c, A, index] = SD_gen(flag, md, len_skm);
[SKm, SKm_w] = SKm_Gen(G, md*2, len_skm, S, T1, T, index, BCH_length);
delta = round(Delta * rand(len_skm,1)) - Delta/2;
%delta = zeros(len_skm,1);

%generate the fingerprint b_k
b = randi([0,1],L,1);
[kk, t, a, b_encode] = BCH_encode(b, BCH_length);
b_encode = b_encode * 2 - 1;

pre_image = RoomReserving(origin, blocksize, MSB, NUM1, NUM2);
%figure;imshow(pre_image);

img_vec = double(pre_image(:));
img_vec_ori = double(origin(:));

%image encryption
cimg_vec = img_vec;
pad_e = zeros(md*2,1);
for i = 1:md
    for j = 1:S
        pad_e(i) = pad_e(i) + ELUT(SKm((i-1)*S+j));
    end
    cimg_vec = cimg_vec + pad_e(i) * SD_w(:,i); 
end
vec = water_embed_c(img_vec_ori, A, Delta, delta);
cimg_vec = cimg_vec + vec;
for i = 1:md
    for j = 1:S
        pad_e(i+md) = pad_e(i+md) + ELUT(SKm((i+md-1)*S+j));
    end
    cimg_vec = cimg_vec + pad_e(i+md) * SD_c(:,i); 
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
cimg_vec = mod(round(cimg_vec),256);


%show
cimg_matrix = reshape(cimg_vec,M,N);
cimg_matrix = uint8(cimg_matrix);
peak_snr_c = psnr(cimg_matrix, origin); 
%imwrite(c_ing,'C:\Users\肖祥立\Desktop\figure\04_en.bmp');
%figure; imshow(cimg_matrix);

AjImage = Adjustment(cimg_matrix, origin, blocksize, MSB, NUM1);
AjImage = Permutation(AjImage, blocksize, key, 1);
rng('shuffle');
%figure; imshow(AjImage);

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

%decrypt the image
AjImage = Permutation(AjImage, blocksize, key, -1);
rng('shuffle');
ajimg_vec = double(AjImage(:));
wing_vec = ajimg_vec;
pad_d = zeros(md*2,1);
for i = 1:md
    for j = 1:S
        pad_d(i) = pad_d(i) + DLUT(SKm((i-1)*S+j));
    end
    wing_vec = wing_vec + pad_d(i) * SD_w(:,i); 
end
for i = 1:md
    for j = 1:S
        pad_d(i+md) = pad_d(i+md) + DLUT(SKm((i+md-1)*S+j));
    end
    wing_vec = wing_vec + pad_d(i+md) * SD_c(:,i); 
end
wing_vec = mod(round(wing_vec),256);
wimg_matrix = reshape(wing_vec,M,N);
wimg_matrix = uint8(wimg_matrix);
% figure; imshow(wimg_matrix);

rec_image = Recovery( wimg_matrix, blocksize, MSB, NUM1, NUM2);
peak_snr_w = psnr(rec_image, origin); 
%figure;imshow(rec_image);

recimg_vec = double(rec_image(:));
recimg_noise = awgn(double(rec_image), -dbw_noise); %generate Gaussian noise
recimg_noise = uint8(recimg_noise);
figure;imshow(recimg_noise);
peak_snr_wn = psnr(recimg_noise, origin);
recimgvec_noise = double(recimg_noise(:));

%arbitration
Bm =  Bm_Gen(len_skm*2, T, S, SKm_w );
b_encode = b_encode';
G = G(T1+1:T,:);
arbitration = detection_my(Bm, G, A, recimg_vec, b, b_encode, Delta, delta, kk, t, a, L);
% b_arbb = b_arbb';
if arbitration == 1
    disp("无噪声情况下水印提取成功");
else
    disp("无噪声情况下水印提取失败");
end


arbitration_n = detection_my(Bm, G, A, recimgvec_noise, b, b_encode, Delta, delta, kk, t, a, L);
%b_arbb2 = b_arbb2';
if arbitration_n == 1
    disp("有噪声情况下水印提取成功");
else
    disp("有噪声情况下水印提取失败");
end

sum = 0;
for i = 1:M
    for j= 1:N
        if rec_image(i,j)~=origin(i,j) && Flag(i,j) == 0
            sum=sum+1;
        end
    end
end
















