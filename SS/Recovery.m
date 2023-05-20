%file: Recovery.m
%to recover the image
%origin: the original image
%blocksize: the blocksize of embedding area for type 0, and the blocksize of adjustment area for type 1
%MSB: the number of every bit in adjustment area used for adjustment
%     (method==1: the value of Lfix)
%NUM: the number of pixels that the adjustment area contains (type==1)
%     no meaning (type==0)
%method: using different data hiding method to reserve room 0-3
%type: illustrate the distribution of the adjustment areas.
%      2 means others
%      1 means the embedding areas are in every block
%      0 means unblocking and the whole block can be adjusted
%edge: in order to distinguish between the two distribution of areas, 0 for type 1 and others for type 0
function res = Recovery( origin, blocksize, MSB, NUM1, NUM2 )
%DeImage = Encryption(origin, key);
% High Capacity Reversible Data Hiding in Encrypted Image Based on Adaptive MSB Prediction
[data,ExtImage] = BTL_RDH_r( origin, blocksize, MSB, NUM1, NUM2);
% recover the adjustment area
res = Distribution( ExtImage, blocksize, MSB, NUM1, data);
end