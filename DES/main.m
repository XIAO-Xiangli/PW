clear; clc;

P = imread( '30723072.jpg') ;
[M,N,Channel] = size(P);


%加密
tic;
C = P;
key = zeros(Channel,8);
for i = 1:Channel
    key(i,:) = mod( floor(rand(1,8)*10000),256);
    P_i = double(P(:,:,i));
    C(:,:,i) = myTDES(key(i,:), P_i);
end
C = uint8(C);
toc;
figure(1);imshow(C);

%解密
tic;
Pd = C;
for i = 1:Channel
    Pd(:,:,i) = myTDESinv(key(i,:), C(:,:,i));
end
toc;
Pd = uint8(Pd);
figure(2);imshow(Pd);

for i = 1:M
    for j = 1:N
        for c = 1:Channel
        if Pd(i,j,c) ~= P(i,j,c)
            i , j, c
        end
        end
    end
end
