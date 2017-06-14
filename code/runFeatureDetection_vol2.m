function featFilePath = runFeatureDetection_vol2(inputFolder, outputFolder)
% batch images

%% assumed parameters
fx = 0; % for front camera
fy = fx;

% lets try to make abs paths out of relative
curFolder = pwd;
[foldPath, filename, ext] = fileparts(inputFolder);
inputFolder = fullfile(curFolder, foldPath, filename);
[foldPath, filename, ~] = fileparts(outputFolder);
outputFolder = fullfile(curFolder, foldPath, filename);

feature_extr_exe = fullfile(pwd,'..\assets\openface', 'FeatureExtraction.exe');

%% run OF
% make output folder
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

[~, f_name, ~] = fileparts(inputFolder);
% extract features directly from input video
featFilePath = fullfile(outputFolder, [f_name, '_OF.txt']);
if ~exist(featFilePath, 'file')
    disp('Start OpenFace');
    if fx > 0
        cmd = ['"', feature_extr_exe, '" -fx ', num2str(fx), ' -fy ', num2str(fy), ' -q -fir "', inputFolder, '" -of "', featFilePath, '"'];
    else
        cmd = ['"', feature_extr_exe, '" -q -fdir "', inputFolder, '" -of "', featFilePath, '"'];
    end
    [status, cmdout] = system(cmd);
    % disp(cmdout);
    disp('End OpenFace');
else
    disp('skip OpenFace');
end


end