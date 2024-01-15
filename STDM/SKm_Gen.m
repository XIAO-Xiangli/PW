function [ SKm, SKm_w ] = SKm_Gen(G, md, len_skm, S, T1, T, index, BCH_length)

SKm = zeros(md*S,1);
SKm_w = zeros(len_skm*S, 1);
k = 1;
h = 1;
for i = 1 : md/2
    if index(k) == i
%         h = ceil(rand()*BCH_length);
        source = find(G(:,h) == 1);
        ind = randperm(length(source));
        for j = 1:S
            SKm((i-1)*S+j) = source(ind(j));
            SKm_w((k-1)*S+j) = source(ind(j));
        end
        if k < len_skm
            k = k+1;
            if h < BCH_length
                h = h + 1;
            else
                h = ceil(rand()*BCH_length);
            end
        end
    else
        SKm((i-1)*S+1:i*S) = randperm(T-T1, S) + T1;
    end
end
for i = md/2+1 : md
    SKm((i-1)*S+1:i*S) = randperm(T1, S);
end

end