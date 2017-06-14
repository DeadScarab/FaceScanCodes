function open_face_feats_normalised(inputFile, fileType, outputFolder, rotateAngle)
% fileType: 0 - video, 1 - image

    %% input
    tic
%     inputFile = 'M:\iCV\Face Scan\Videos\lembit7.mp4';
%     rotateAngle = 90;
%     outputFolder = 'M:\iCV\Face Scan\Temp\lembit7';
%     fileType = 0;
    
    [pathstr, name, ~] = fileparts(inputFile);

    %% rotate
    % If need rotating, rotate output to same folder
    if rotateAngle ~= 0
        disp(['Rotate ', name]);
        if fileType == 0
            dstFile = fullfile(pathstr, [name '_rotated.avi']);
            if ~exist(dstFile, 'file')
                rotateVideo(inputFile, dstFile, rotateAngle);
            end
            disp('Finished rotating');
        elseif fileType == 1
            dstFile = fullfile(pathstr, [name '_rotated.png']);
            img = imread(inputFile);
            img = imrotate(img, rotateAngle);
            imwrite(img, dstFile);
        else
            disp('Incorrect file type.');
            dstFile = inputFile;
        end
        inputFile = dstFile; % use the rotated input for OF
    end
    
    %% Run OpenFace and get the data file
    
    outputFile = runFeatureDetection(inputFile, outputFolder);

    [data, tab] = readOFData(outputFile);
    
    %% Save output?
    if fileType == 0
        parfor angle = -1:1:1
            frameNr = getBestFrameNr(tab.pose_Rx, tab.pose_Ry, tab.pose_Rz, angle*20);
            % save
            i = angle + 1;
            extractNormalisedFrame(inputFile, data, frameNr, outputFolder, [name '_' num2str(i)], 0);
        end
    elseif fileType == 1
        frameNr = 1;
        extractNormalisedFrame(inputFile, data, frameNr, outputFolder, name, 1);
    end
    toc

end
