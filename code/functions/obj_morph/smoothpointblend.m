function [ base_region ] = smoothpointblend( base_region, new_region, new_region_idx, amp_size )
%SMOOTHPOINTBLEND add 'new_region's 'new_region_idx' points to 'base_region'

%   Blend 'base_region' and 'new_region' pointclouds together using
%   'new_region_idx' to define the 'new_region's strong influence in the
%   blend.


    blended_region = base_region;
    
    %%DEFINE THE REGION CENTER AND SIZE
    center = mean(new_region(new_region_idx,:));
    amplitude = [max(new_region(new_region_idx,1))-min(new_region(new_region_idx,1)) ,max(new_region(new_region_idx,2))-min(new_region(new_region_idx,2)) ,max(new_region(new_region_idx,3))-min(new_region(new_region_idx,3)) ];
    amplitude = amplitude/amp_size;                                         % Region size multiplier (2 is 100%, 1 is 200%)

    for i = 1:size(base_region,1)
        if base_region(i,3) ~= 0
            distance = (((new_region(i,1) - center(1))/amplitude(1))^2  +  ((new_region(i,2) - center(2))/amplitude(2))^2  +  ((new_region(i,3) - center(3))/amplitude(3)/2)^2)^0.5;

            blend_value = 1.01218 + (-0.007170143 - 1.01218)/(1 + (distance/0.2642294)^3.243915);
            base_region(i,:) = base_region(i,:)*(blend_value) + new_region(i,:)*(1-blend_value);
        end
    end
    
    
end

