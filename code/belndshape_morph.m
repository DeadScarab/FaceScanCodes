function [ points ] = belndshape_morph( basemodel, basemodel_dir, input_directory, input_file,  models, weights )
%BELNDSHAPE_MORPH Main blending function that creates a morphed model

%   This function creates a morphed model using input weights with
%   corresponding regions and models, stitches them together and then
%   morphs the output the feature points created by OpenFace

addpath('functions/obj_IO')
addpath('functions/obj_morph')
addpath('functions/feature_func')


 closest_models_eyes = models.closest_models_eyes;
 closest_models_nose = models.closest_models_nose;
 closest_models_mouth = models.closest_models_mouth;
 closest_models_face = models.closest_models_face;
 closest_weights_eyes = weights.closest_weights_eyes;
 closest_weights_nose = weights.closest_weights_nose;
 closest_weights_mouth = weights.closest_weights_mouth;
 closest_weights_face = weights.closest_weights_face;



%% MORPH INPUTS %%

    regionmodel = strcat(basemodel_dir,'basemodels/region_maps.obj');       % Basemodel mapped region data
    input_files = fullfile(input_directory, input_file);                        % Directory for texture and feature data
    featurepoints = strcat(input_files, '_2d.txt');                             % 2D feature points from OpenFace
    load(strcat(basemodel_dir,'feat_points.mat'))                               % Feature point index data for mapping to obj model
    feature_adjust_scale = 1.2;                                                 % Feature point face scale muliplier
    load(strcat(basemodel_dir,'blendshape_points.mat'));                        % Load blendshape

    move = readfeats( featurepoints, feature_map, [0, 4], 20);                  % Read 2D feature point data

%% ADJUST FEATURE POINTS %%
    disp('rescaling main shape')
        move(1:18,2) = move(1:18,2)*feature_adjust_scale;
    disp('equalizing main features')
        move(:,2:4) = equalizefeats( move(:,2:4) );

    [~, mapping] = readobj( basemodel );                                        % Read basemodel for point refrence


%% GENERATE FACE REGIONS %%
    disp('importing model regions')
    %%EYES
    eye_region = findregion( regionmodel, 'EyeRegion' );                                   
    eye_point_inx = findpointsfromregions( mapping(:,:, eye_region) );
    eye_point_inx = eye_point_inx(eye_point_inx~=0);
    
    %%NOSE
    nose_region = findregion( regionmodel, 'NoseRegion' );
    nose_point_inx = findpointsfromregions( mapping(:,:, nose_region) );
    nose_point_inx = nose_point_inx(nose_point_inx~=0);
    
    %%MOUTH
    mouth_region = findregion( regionmodel, 'MouthRegion' );
    mouth_point_inx = findpointsfromregions( mapping(:,:, mouth_region) );
    mouth_point_inx = mouth_point_inx(mouth_point_inx~=0);
    
    %%REST
    rest_region = findregion( regionmodel, 'FaceRegion' );
    rest_point_inx = findpointsfromregions( mapping(:,:, rest_region) );
    rest_point_inx = rest_point_inx(rest_point_inx~=0);


 
%% BLEND BEST FIT REGIONS %%
    disp('blending base model')
    %%EYES
    closest_models = model_points(:,:,closest_models_eyes);
    eyes_points = blendshape(closest_models, closest_weights_eyes); 
    
    %%NOSE
    closest_models = model_points(:,:,closest_models_nose);
    nose_points = blendshape(closest_models, closest_weights_nose); 
    
    %%MOUTH
    closest_models = model_points(:,:,closest_models_mouth);
    mouth_points = blendshape(closest_models, closest_weights_mouth); 
    
    %%REST
    closest_models = model_points(:,:,closest_models_face);
    rest_points = blendshape(closest_models, closest_weights_face); 
    
    %%REGION LOCATIONS IN FEATURES
    XYadjust = zeros(4,3);
    XYadjust(1,:) = mean(move([28:31,34], 2:4));
    XYadjust(2,:) = mean(move([37:42,43:48], 2:4));
    XYadjust(3,:) = mean(move([49:68], 2:4));
    
    %%STITCH BEST FIT REGIONS 
    points = frankenblend(eyes_points,eye_point_inx,nose_points,nose_point_inx,mouth_points,mouth_point_inx,rest_points,rest_point_inx, XYadjust);
    
    
    

%% GAUSSIAN MORPH MODEL TO FIT FEATURES %%

    disp('gauss morph large')
    points = gaussallmove3D( points, points(move(:,1),:), move(:,2:4), move(:,5) , 20, 0.4, 2);     % morph the general shape
    disp('gauss morph medium')
    points = gaussallmove3D( points, points(move(:,1),:), move(:,2:4), move(:,5) , 12, 0.4, 1);     % morph large face features like nose and eyebrows
    disp('gauss morph small')
    points = gaussallmove3D( points, points(move(:,1),:), move(:,2:4), move(:,5) , 7, 0.1, 0);        % morph details like eyes, nostrils and mouth


disp('model created')
end

