      function [arbitration] = detection_my( Bm, G, A, wing_vec, b, b_encode, Delta, delta, kk, t, a, L)

%the Matched Filter decoder
G = sparse(G);
GG = full(Bm * G);
wp = A' * wing_vec;
wp_q = (Delta * round((wp + delta) / Delta) - delta);
e = wp - wp_q;
ee = GG' * e;
b_arb = sign(ee);

% e = round(e);
% steam = GG * b_encode;
% steamdd1 = pinv(GG' * GG) * GG' * steam;
% steamdd2 = GG\steam;
% steamdd3 = GG' * b_encode;

b_arb = floor((b_arb+1)/2);
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

