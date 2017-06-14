function [ blend_model ] = blendshape( models, weights )
%BLENDSHAPE Blend pointclouds based on weights for each pointcloud

    weights = weights / sum(weights);

    blend_model = zeros(size(models(:,:,1)));
    for i = 1:size(models,3)
        blend_model = blend_model + models(:,:,i)*weights(i);
    end
  
end

