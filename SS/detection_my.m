function [arbitration] = detection_my( Bm, G, wing_vec, img_vec, b, b_encode, flag, kk, t, a, L)

%the Matched Filter decoder
% w_arbbb = double(bitand(bitxor(wing_vec, img_vec),uint8(15)));
w_arbbb = wing_vec - img_vec;
%max(w_arbbb)
for i = 1:size(w_arbbb)
    if flag(i) == 0
        w_arbbb(i) = 0;
    end
end
% w_arbbbb = sign(w_arbbb-0.5);
G = sparse(G);
w_arbb = (Bm * G)'* w_arbbb;
% warbb_sort = sort(w_arbb);
% warbb_sort(length(warbb_sort)-2:length(warbb_sort)) = [];
% w_arb = sign(w_arbb);
% b_arb = w_arb;
w_arb = sign(w_arbb-mean(w_arbb));
% w_arb = sign(w_arbb);
b_arb = floor((w_arb+1)/2);
b_encode = (b_encode+1)/2;

b_arbb = BCH_decode( b_arb', b_encode, kk, t, a );


%check if the detected fingerprint is completely correct
index = 0;
for i = 1:length(b)
    if b_arbb(i) == b(i)
        index = index + 1;
    end
end

if index == L
    arbitration = 1; %a successful trace
else
    arbitration = 0; %a failed trace
end

end

