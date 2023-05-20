function [ Bm ] = Bm_Gen( M, S, SKm )

j = 1;
locx = zeros(M*S,1);
locy = zeros(M*S,1);
value = zeros(M*S,1);
for i=1:M
    for k=1:S
        locx(j) = i;
        locy(j) = SKm((i-1)*S+k);
        value(j) = 1;
        j =j+1;
    end
end
Bm = sparse(locx, locy, value);

end