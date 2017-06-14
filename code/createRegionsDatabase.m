clearvars

% first have to create renders from database models
% run render_obj.py using blender python distribution, f.e.
% "c:\Program Files\Blender Foundation\Blender\blender.exe" --background --python render_obj.py
% That can sometimes fail to put texture on, run it again :)
n = 216;
% relative paths should work...
input_folder = '..\assets\renders_all';     % location of renders
outputFolder = '..\assets\regions_db_all';  % target location for DB

addpath('functions/features')

%% run OpenFace on all frontal renders, extract normalised face, save 2d & 3d points
% mkdir(outputFolder);
% for i=1:n
% %     inputFile = fullfile(input_folder, sprintf('male%03d_front.png', i));
%     inputFile = fullfile(input_folder, sprintf('male%03d.jpg', i));
%     open_face_feats_normalised(inputFile, 1, outputFolder, 90)
% end

%% create folders for regions
mkdir(fullfile(outputFolder, 'face'));
mkdir(fullfile(outputFolder, 'eyes'));
mkdir(fullfile(outputFolder, 'nose'));
mkdir(fullfile(outputFolder, 'mouth'));
mkdir(fullfile(outputFolder, 'fullFace'));

%% extract regions from all normalised images, save to separate folders
parfor i=0:n
%     img_name = fullfile(outputFolder, sprintf('male%03d_front.png', i));
%     pts_name = fullfile(outputFolder, sprintf('male%03d_front_2d.txt', i));
    img_name = fullfile(outputFolder, sprintf('male%03d.png', i));
    pts_name = fullfile(outputFolder, sprintf('male%03d_2d.txt', i));
%     img_face = extractRegion(img_name, pts_name, 1);
%     img_eyes = extractRegion(img_name, pts_name, 2);
%     img_nose = extractRegion(img_name, pts_name, 3);
%     img_mouth = extractRegion(img_name, pts_name, 4);
    img_fullFace = extractRegion(img_name, pts_name, 0);
    
%     imwrite(img_face, fullfile(outputFolder, 'face', sprintf('male%03d.png', i)));
%     imwrite(img_eyes, fullfile(outputFolder, 'eyes', sprintf('male%03d.png', i)));
%     imwrite(img_nose, fullfile(outputFolder, 'nose', sprintf('male%03d.png', i)));
%     imwrite(img_mouth, fullfile(outputFolder, 'mouth', sprintf('male%03d.png', i)));
    imwrite(img_fullFace, fullfile(outputFolder, 'fullFace', sprintf('male%03d.png', i)));
end
