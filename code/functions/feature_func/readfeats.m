function [ featurelist ] = readfeats( filename, map, translation, resize )
%READOBJ Read OpenFace feature points and alter them

%   Read feature points from 'filename' and add corresponding indexes for
%   each point using 'map'
%   translation and rotation are used to reshape the feature point data
%   'featurelist' is a (68,5) where (:,1) is the mapped vertex index,
%   (:,2-4) are the XY(Z) coordinates and (:,5) is the feature points size
%   for later morphing.

file = textread(filename, '%f', 'delimiter', ' ');

featurelist = zeros(68,5);
for i = 1:(68)
    
        gausssize = 0.2;
        if i<33 || i == 36
            gausssize = 0.3;
        end

        if i<27
            gausssize = 0.4;
        end
        
        featurelist(i,:) = [map(i),   file(i), file(i+68),0,   gausssize];
end

for i = 1:size(featurelist,1)
   featurelist(i,2) = (featurelist(i,2) - 0.5)*resize + translation(1);
   featurelist(i,3) = (1 - featurelist(i,3))*resize + translation(2);
end

end
