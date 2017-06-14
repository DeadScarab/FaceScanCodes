clearvars

% first have to create renders from database models
% run render_obj.py using blender python distribution, f.e.
% "c:\Program Files\Blender Foundation\Blender\blender.exe" --background --python render_obj.py
% That can sometimes fail to put texture on, run it again :)
n = 216;
% relative paths should work...
input_folder = '..\assets\renders_again';     % location of renders
outputFolder = '..\assets\regions_db_again';  % target location for DB
rotateAngle = 90;

addpath('functions/features')

% if needed, rotate pics
if rotateAngle ~= 0
    rotated_dir = fullfile(input_folder, 'rotated');
    mkdir(rotated_dir);
    parfor i=0:n
        dstFile = fullfile(rotated_dir, sprintf('male%03d.png', i));
        inputFile = fullfile(input_folder, sprintf('male%03d.jpg', i));
        img = imread(inputFile);
        img = imrotate(img, rotateAngle);
        imwrite(img, dstFile);
    end
    input_folder = rotated_dir;
end

%% run OpenFace on all frontal renders, extract normalised face, save 2d & 3d points
mkdir(outputFolder);
% run for all images in folder
ofDataFile = runFeatureDetection_vol2(input_folder, outputFolder);
[data, tab] = readOFData(ofDataFile);

%% create folders for regions
mkdir(fullfile(outputFolder, 'face'));
mkdir(fullfile(outputFolder, 'eyes'));
mkdir(fullfile(outputFolder, 'nose'));
mkdir(fullfile(outputFolder, 'mouth'));

%% extract regions from all normalised images, save to separate folders
parfor i=0:n
    inputFile = fullfile(input_folder, sprintf('male%03d.png', i));
    extractNormalisedFrame(inputFile, data, i, outputFolder, sprintf('male%03d', i), 1);
    
    img_name = fullfile(outputFolder, sprintf('male%03d.png', i));
    pts_name = fullfile(outputFolder, sprintf('male%03d_2d.txt', i));
    img_face = extractRegion(img_name, pts_name, 1);
    img_eyes = extractRegion(img_name, pts_name, 2);
    img_nose = extractRegion(img_name, pts_name, 3);
    img_mouth = extractRegion(img_name, pts_name, 4);
    
    imwrite(img_face, fullfile(outputFolder, 'face', sprintf('male%03d.png', i)));
    imwrite(img_eyes, fullfile(outputFolder, 'eyes', sprintf('male%03d.png', i)));
    imwrite(img_nose, fullfile(outputFolder, 'nose', sprintf('male%03d.png', i)));
    imwrite(img_mouth, fullfile(outputFolder, 'mouth', sprintf('male%03d.png', i)));
end
