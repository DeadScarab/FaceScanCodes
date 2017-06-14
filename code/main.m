
addpath('functions/obj_IO')
addpath('functions/features')

%% input stuff
inputFile = '..\input\shb.mp4';
outputFolder = '..\output\shb';
% dbFolder = '..\assets\regions_db';
dbFolder = '..\assets\regions_db_all';
rotateAngle = 90;  % 90 or -90 or 0
n = 216;  % database size

%% run OF on input video, save views from -20, 0, +20 degress
open_face_feats_normalised(inputFile, 0, outputFolder, rotateAngle)

%% find closest models - using only frontal pic
[pathdir, fName, ~] = fileparts(inputFile);
imgName = fullfile(outputFolder, [fName '_1.png']);  % frontal
[wEyes, wNose, wMouth, wFace] = getClosestFaces(imgName, dbFolder, n);

%% DEFINE DATA DIRECTORIES
    basemodel_dir = 'model_data\';                                              % Main data directory
    output_dir = outputFolder;                                                  % Output directory
    input_directory = outputFolder;                                             % Feature point and texture file input directory
    input_file = [fName '_1'];                                                  % Input filename without extension
    
    
%% DEFINE DATA FOR EXPORT
    output_filename = input_file;
    modelfile =  strcat(output_filename,'.obj');                                % Output file
    texturefile = strcat(output_filename,'.mtl');                               % Output files .mtl file
    basemodel = strcat(basemodel_dir,'basemodels/base_model.obj');              % Basemodel
    originaltexturefile = strcat(basemodel_dir,'basemodels/base_model.mtl');    % Basemodels .mtl file
    
%% REGION BASED MODEL SELECTION
    closest_models_eyes  = 1:n;
    closest_models_nose  = 1:n;
    closest_models_mouth = 1:n;
    closest_models_face  = 1:n;

    closest_weights_eyes  = wEyes;
    closest_weights_nose  = wNose;
    closest_weights_mouth = wMouth;
    closest_weights_face  = wFace;


    models = struct('closest_models_eyes', closest_models_eyes, 'closest_models_nose', closest_models_nose, 'closest_models_mouth', closest_models_mouth, 'closest_models_face', closest_models_face); 
    weights = struct('closest_weights_eyes', closest_weights_eyes, 'closest_weights_nose', closest_weights_nose, 'closest_weights_mouth', closest_weights_mouth, 'closest_weights_face', closest_weights_face); 

    
    

%% GENERATE MODEL
    Model = belndshape_morph( basemodel, basemodel_dir, input_directory, input_file, models, weights);


    
    
%% SAVE OUTPUT MODEL %%
    
    disp('exporting')
    %%SAVE OBJ
    writeobjfast( basemodel,fullfile(output_dir, modelfile),  Model ,texturefile );
    
    %%SAVE MTL
    attachtexture( originaltexturefile, strcat(input_file, '.png'), fullfile(output_dir, texturefile) );

disp(find(wFace > 0)-1);
disp('done')