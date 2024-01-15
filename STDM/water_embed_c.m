function pho_img = water_embed_c(orginal, A, Delta, delta)

pho = A' * orginal;
pho_q = Delta * round((pho + delta) / Delta) - delta;
% pho_img = A * (pho_q - pho);

% pho = zeros(L,0);
% pho_q = pho;
% for i = 1 : L
%     pho(i) = dot(orginal, A(:,i));
%     pho_q(i) = (Delta * round((pho(i) - delta(i)) / Delta) + delta(i));
% end
% 
% 
[~,L] = size(A);
[M,N] = size(orginal);
pho_img = zeros(M,N);
for i = 1 : L
    pho_img = pho_img - pho(i)*A(:,i) + pho_q(i)*A(:,i);
end

%water_img = mod(water_img, 256);

end

