function [ SKm ] = SKm_Gen(M, T1, T2, S, flag)

SKm=zeros(M*S,1);
for i=1:M
    if flag(i) == 0
        SKm((i-1)*S+1:i*S)=randperm(T1, S);
    else
        SKm((i-1)*S+1:i*S)=randperm(T2, S)+T1;
    end
end

end