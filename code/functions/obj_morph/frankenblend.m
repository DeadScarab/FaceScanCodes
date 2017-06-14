function [ franken_points ] = frankenblend( eyes, eyes_idx, nose, nose_idx, mouth, mouth_idx, rest, rest_idx, XYadjust )
%FRANKENBLEND This function blends together different point clouds based on
%their corresponding regions

%   This function takes in point clouds of the selected eyes,nose,mouth and
%   face and their regions of interest '_idx'. The regions are then
%   adjusted to fit together and then the overlap areas are given a smooth
%   overlap
%   'XYadjust' defines an adjustment location where the regions should be
%   located on the final model, helps with areas with curved overlap like
%   the nose

    franken_points = rest;
    
    nose_sect = mean(franken_points(intersect(nose_idx,rest_idx),:), 1) - mean(nose(intersect(nose_idx,rest_idx),:), 1);
    nose(:,1) = nose(:,1) + nose_sect(1);
    nose(:,2) = nose(:,2) + nose_sect(2);
    nose(:,3) = nose(:,3) + nose_sect(3);
    nose_sect = XYadjust(1,:) - mean(nose(intersect(nose_idx,rest_idx),:), 1);
    nose(:,1) = nose(:,1) + nose_sect(1)/4;
    nose(:,2) = nose(:,2) + nose_sect(2)/4;
    
    franken_points = smoothpointblend(franken_points, nose,nose_idx, 1.1/2 );
    
    mouth_sect = mean(franken_points(intersect(mouth_idx,rest_idx),:), 1) - mean(mouth(intersect(mouth_idx,rest_idx),:), 1);
    mouth(:,1) = mouth(:,1) + mouth_sect(1);
    mouth(:,2) = mouth(:,2) + mouth_sect(2);
    mouth(:,3) = mouth(:,3) + mouth_sect(3);
    mouth_sect = XYadjust(3,:) - mean(mouth(intersect(mouth_idx,rest_idx),:), 1);
    mouth(:,1) = mouth(:,1) + mouth_sect(1)/4;
    mouth(:,2) = mouth(:,2) + mouth_sect(2)/4;
    
    franken_points = smoothpointblend(franken_points, mouth,mouth_idx, 2/2 ); 
    
    eye_sect = mean(franken_points(intersect(eyes_idx,rest_idx),:), 1) -  mean(eyes(intersect(eyes_idx,rest_idx),:), 1);
    eyes(:,1) = eyes(:,1) + eye_sect(1);
    eyes(:,2) = eyes(:,2) + eye_sect(2);
    eyes(:,3) = eyes(:,3) + eye_sect(3);

    eyes_idx_L = [];
    eyes_idx_R = [];
    for loc = eyes_idx'
        if eyes(loc,1)>0
            eyes_idx_L = [eyes_idx_L, loc];
        else
            eyes_idx_R = [eyes_idx_R, loc];
        end
    end
    
    
    franken_points = smoothpointblend(franken_points, eyes,eyes_idx_L, 1.1/2 );
    franken_points = smoothpointblend(franken_points, eyes,eyes_idx_R, 1.1/2 );

end

