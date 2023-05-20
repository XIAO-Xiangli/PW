function [C] = myTDES(key,P)

[M,N] = size(P);
P1 = transpose(P);
P2= transpose(P1(:));
x = zeros(M*N/8,8);
for i = 1:M*N/8
    x(i,:) = P2(8*(i-1)+1:8*(i-1)+8);
end
C1 = zeros(M*N/8,8);
for i = 1:M*N/8
    if i == 1
        C1(i,:) = myDES(key,x(i, :));
    else
        C1(i,:) = myDES(key, bitxor(C1(i-1,:),x(i,:)));
    end
end
C2 = zeros(1,M*N);
for i = 1:M*N/8
    C2(8*(i-1)+1:8*(i-1)+8) = C1(i,:);
end
C = reshape(C2, N, M);
C = transpose(C);
end