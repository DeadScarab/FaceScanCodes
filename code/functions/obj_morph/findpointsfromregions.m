function [ points ] = findpointsfromregions( map )
%FINDPOINTSFROMREGIONS Finds point indexes that correspond to the given
%mesh faces

    points = zeros(size(map,3)*4,1);
    
    for i = 1:size(map,3)
        for j = 1:4
            points(i+(j-1)*size(map,3),1) = map(j,1,i);
        end
    end

end

