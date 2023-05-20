function [P]= myTDESinv(key,C)

[M,N] = size(C);
C1 = transpose(C);
C2 = transpose(C1(:));
x = zeros(M*N/8,8);
for i = 1:M*N/8
    x(i,:) = C2(8*(i-1)+1:8*(i-1)+8);
end
P1 = zeros(M*N/8,8);
for i = 1:M*N/8
    if i == 1
        P1(i, :) = myDESinv(key,x(i,:));
    else
        P1(i, :) = bitxor( myDESinv(key,x(i, :)),x(i-1,:));
    end
end
P2 = zeros(1,M*N);
for i = 1:M*N/8
    P2(8*(i-1)+1:8*(i-1)+8) = P1(i, :);
end
P = reshape(P2,N,M);
P = transpose(P);
end

