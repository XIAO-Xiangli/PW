clc;clear;
blocksize = 16;
MSB = 1;
key = 1;
Proportion_tz = 0.6;
Proportion_yc = 0.3;
sigma_E = 10^8;
dbw_noise = 36; %the variance of the noise
BCH_length=63; L=24; T=3000; S=2;
aa = 16;
times = 100;
% cutting_row = 300;
Q_p = 0;

% T1 = floor(T * Proportion_yc);
% T2 = T - T1;

%read image information
origin3 = imread('1024.jpg'); 
[M,N,Channel] = size(origin3);
%figure; imshow(origin);

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

Proportion = 1 - (sum(flag)/length(flag));
T1 = floor(T * Proportion);
T2 = T - T1;

tic;
pre_image3 = RoomReserving(origin3, blocksize, MSB, NUM1, NUM2);
%figure;imshow(pre_image3);
toc;

arbitration_sum = 0;
%peak_snr_wn_sum = 0;
for time = 1 : times

%generate ELUT, SKm
% tic;
ELUT = ELUT_Gen( sigma_E, T ); 
SKm = SKm_Gen(M*N*Channel, T1, T2, S, flag);

img_vec3 = double(pre_image3(:));

%image encryption
cimg_vec = zeros(M*N*Channel, 1);
pad_e = zeros(M*N*Channel,1);
for i = 1:M*N*Channel
    for j = 1:S
        pad_e(i) = ELUT(SKm((i-1)*S+j));
    end
    cimg_vec(i) = mod((img_vec3(i)+pad_e(i)),256); 
end
%show
cimg_matrix3 = reshape(cimg_vec,M,N,Channel);
cimg_matrix3 = uint8(cimg_matrix3);
peak_snr_c = psnr(cimg_matrix3, origin3); 
% imwrite(cimg_matrix3,'C:\Users\Administrator\Desktop\05_en.png');
% figure; imshow(cimg_matrix3);
% toc;

AjImage3_a = Adjustment(cimg_matrix3, origin3, blocksize, MSB, NUM1);
% imwrite(AjImage3_a,'C:\Users\Administrator\Desktop\05_aj_np.png');
% figure; imshow(AjImage3_a);
AjImage3 = Permutation(AjImage3_a, blocksize, key, 1);
rng('shuffle');
% imwrite(AjImage3,'C:\Users\Administrator\Desktop\05_aj.png');
% figure; imshow(AjImage3);

%generate the fingerprint b_k
b = randi([0,1],L,1);
[kk, t, a, b_encode] = BCH_encode(b, BCH_length);
b_encode = b_encode * 2 - 1;
G=zeros(T,BCH_length);
for i=T1+1:T
    j=randi([1,BCH_length]);
    G(i,j)=1;
end

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
%DLUT = -ELUT;

%decrypt the image
AjImage3 = Permutation(AjImage3, blocksize, key, -1);
rng('shuffle');
ajimg_vec3 = double(AjImage3(:));
wing_vec3 = zeros(M*N*Channel, 1);
pad_d = zeros(M*N*Channel,1);
for i = 1:M*N*Channel
    for j = 1:S
        pad_d(i) = DLUT(SKm((i-1)*S+j));
    end
    wing_vec3(i) = mod((ajimg_vec3(i) + pad_d(i)),256); 
end
wimg_matrix3 = reshape(wing_vec3,M,N,Channel);
wimg_matrix3 = uint8(wimg_matrix3);
%figure; imshow(wimg_matrix3);

rec_image3 = Recovery( wimg_matrix3, blocksize, MSB, NUM1, NUM2);
peak_snr_w = psnr(rec_image3, origin3); 
% imwrite(rec_image3,'C:\Users\Administrator\Desktop\05_re.png');
%figure;imshow(rec_image3);

imwrite(rec_image3,'1024_JEPG.jpg','quality',Q_p);
recimg_noise3 = imread('1024_JEPG.jpg');
%imwrite(recimg_noise3,'C:\Users\Administrator\Desktop\05_clip.png');

% recimg_noise3 = rec_image3;
% for c = 1 : Channel
% for i = 1 : M
%     for j = 1 : N
%         if i <= M - cutting_row && j > N - cutting_row
%             recimg_noise3(i,j,c) = recimg_noise3(i,j-1,c);   
%         end
%         if i > M - cutting_row && j <= N - cutting_row
%             recimg_noise3(i,j,c) = recimg_noise3(i-1,j,c);  
%         end
%         if i > M - cutting_row && j > N - cutting_row
%             recimg_noise3(i,j,c) = recimg_noise3(i-1,j-1,c);  
%         end
%     end
% end
% end
% imwrite(recimg_noise3,'C:\Users\Administrator\Desktop\05_clip.png');

%recimg_vec3 = double(rec_image3(:));
% recimg_noise = awgn(double(rec_image), -dbw_noise); %generate Gaussian noise
% recimg_noise = uint8(recimg_noise);
%peak_snr_wn = psnr(recimg_noise, origin);
recimgvec_noise3 = double(recimg_noise3(:));

%arbitration
Bm = Bm_Gen(M*N*Channel, S, SKm);
b_encode = b_encode';
% arbitration = detection_my(Bm, G, recimg_vec3, img_vec3, b, b_encode, flag, kk, t, a, L);
% % b_arbb = b_arbb';
% if arbitration == 1
%     disp("无噪声情况下水印提取成功");
% else
%     disp("无噪声情况下水印提取失败");
% end


arbitration_n = detection_my(Bm, G, recimgvec_noise3, img_vec3, b, b_encode, flag, kk, t, a, L);
%b_arbb2 = b_arbb2';
% if arbitration_n == 1
%     disp("有噪声情况下水印提取成功");
% else
%     disp("有噪声情况下水印提取失败");
% end

arbitration_sum = arbitration_sum + arbitration_n;
end

success_rate = arbitration_sum/times
%peak_snr_wn_av = peak_snr_wn_sum/times

sum = 0;
for c = 1:Channel
    for i = 1:M
        for j= 1:N
            if rec_image3(i,j,c)~=origin3(i,j,c) && Flag(i,j,c) == 0
                sum=sum+1;
            end
        end
    end
end
















