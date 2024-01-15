function [SD_w, A, index] = SD_gen_rgb(flag, md, L)

M = length(flag);
S_Dow = rand(sum(flag), md);
S_Dow = orth(S_Dow);
SD_w = zeros(M, md);

j = 1;
for i = 1 : M
    if flag(i)  == 1
        SD_w(i,:) = S_Dow(j,:);
        j = j + 1;
    end
end

clear S_Dow

S_Doc = rand(M-sum(flag), md);
S_Doc = orth(S_Doc);


j = 1;
for i = 1 : M
    if flag(i)  == 0
        SD_w(i,:) = S_Doc(j,:);
        j = j + 1;
    end
end

index = randperm(md);
index = index(1:L);
index = sort(index);

clear S_Doc

A = zeros(M,L);
for i = 1 :L
    A(:, i) = SD_w(:, index(i));
end

A = A.*flag;


end

