function [ features ] = equalizefeats( features )
%EQUALIZEFEATS Adjusts mirrored feature points(1-18) to be equal on the y axis

for i = 1:8
    avg = (features(i,2) + features(18-i,2))/2;
    features(i,2) = avg;
    features(18-i,2) = avg;
end

end

