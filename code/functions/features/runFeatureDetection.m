function featFilePath = runFeatureDetection(inputFile, outputFolder)
% Runs OF feature detection, saves feature file and returns its loc.
% Should work both for video and 1 image.

%% assumed parameters
fx = 1150; % for front camera
fy = fx;

% lets try to make abs paths out of relative
curFolder = pwd;
[foldPath, filename, ext] = fileparts(inputFile);
inputFile = fullfile(curFolder, foldPath, [filename, ext]);
[foldPath, filename, ~] = fileparts(outputFolder);
outputFolder = fullfile(curFolder, foldPath, filename);

feature_extr_exe = fullfile(pwd,'..\assets\openface', 'FeatureExtraction.exe');

%% run OF
% make output folder
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

[~, f_name, ~] = fileparts(inputFile);
% extract features directly from input video
featFilePath = fullfile(outputFolder, [f_name, '_OF.txt']);
if ~exist(featFilePath, 'file')
    disp('Start OpenFace');
    if fx > 0
        cmd = ['"', feature_extr_exe, '" -fx ', num2str(fx), ' -fy ', num2str(fy), ' -q -f "', inputFile, '" -of "', featFilePath, '"'];
    else
        cmd = ['"', feature_extr_exe, '" -q -f "', inputFile, '" -of "', featFilePath, '"'];
    end
    [status, cmdout] = system(cmd);
    % disp(cmdout);
    disp('End OpenFace');
else
    disp('skip OpenFace');
end


end