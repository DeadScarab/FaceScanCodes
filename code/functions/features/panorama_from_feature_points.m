clearvars
% only in one directions at the moment..from center

blend_f = 0.75;
cols = 1080; rows = 1080;
frameNbrs = 1:1:61;
centerImageIdx = 30;
% validPointIdx = [18:37, 43, 49:68];
validPointIdx = [18:68];
imgSrcFolder = 'M:\iCV\Face Scan\Temp\rainer5_rotated_openFace';
imgPrefix = '';
imgSuffix = '.png';
pointsSrcFolder = imgSrcFolder;
pointsPrefix = imgPrefix;
pointsSuffix = '_2d.txt';

%% read images
imgNames = {};
for frameNr = frameNbrs
    filename = [imgPrefix, num2str(frameNr), imgSuffix];
    imgNames{end+1} = fullfile(imgSrcFolder, filename);
end

srcScene = imageDatastore(imgNames);
% display
% montage(srcScene.Files);

%% read points
allPoints = {};
for frameNr = frameNbrs
    filename = [pointsPrefix, num2str(frameNr), pointsSuffix];
    filename = fullfile(pointsSrcFolder, filename);
    fid = fopen(filename);
    tmpPts = fscanf(fid, '%f');
    fclose(fid);
    x = tmpPts(1:68) * cols; y = tmpPts(69:136) * rows;
    allPoints{end+1} = [x, y];
end

%% find transformations
numImages = numel(srcScene.Files);
% tforms(numImages) = projective2d(eye(3));
tforms(numImages) = affine2d(eye(3));

points = allPoints{1}(validPointIdx, :);

% Iterate over remaining image pairs
for n = 2:numImages

    % Store points and features for I(n-1).
    pointsPrevious = points;
    % load new points
    points = allPoints{n}(validPointIdx, :);

    % Estimate the transformation between I(n) and I(n-1).
%     tforms(n) = estimateGeometricTransform(points, pointsPrevious,...
%         'affine', 'Confidence', 99.99, 'MaxNumTrials', 10000);
%         'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
    tforms(n) = fitgeotrans(points, pointsPrevious, 'affine');

    % Compute T(1) * ... * T(n-1) * T(n)
    tforms(n).T = tforms(n-1).T * tforms(n).T;
end

% Finally, apply the center image's inverse transform to all the others.
Tinv = invert(tforms(centerImageIdx));

for i = 1:numel(tforms)
    tforms(i).T = Tinv.T * tforms(i).T;
end

% Compute the output limits  for each transform
for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 cols], [1 rows]);
end

% Find the minimum and maximum output limits
xMin = min([1; xlim(:)]);
xMax = max([cols; xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([rows; ylim(:)]);

% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
I = readimage(srcScene, 1);
panorama = zeros([height width 3], 'like', I);

% blender = vision.AlphaBlender('Operation', 'Binary mask', ...
%     'MaskSource', 'Input port');
blender = vision.AlphaBlender('Operation', 'Blend');

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);

pano_mask = false([height width]);

% Create the panorama.
% first up untill center
for i = 1:centerImageIdx

    I = readimage(srcScene, i);

    % Transform I into the panorama.
    warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);
        
    % find face mask
    c = uint16(allPoints{i}(:, 1));
    r = uint16(allPoints{i}(:, 2));

    if i == 1
        mask = true(size(I,1),size(I,2));
        mask(:, uint16(size(I,2)/2):end) = false;
    else
        mask = false(size(I,1),size(I,2));
        vasakult = c(18) + uint16((size(I,2)/2 - c(18)) * i / centerImageIdx);
        mask(:, vasakult:uint16(size(I,2)/2)+5 ) = true;
%         figure; imshow(uint8(repmat(mask, [1,1,3])) .* I); 
    end
    mask = imwarp(mask, tforms(i), 'OutputView', panoramaView);

    panorama =  uint8(repmat(mask & pano_mask,  [1,1,3])) .* (blend_f * warpedImage + (1-blend_f) * panorama) + ...
                uint8(repmat(mask & ~pano_mask, [1,1,3])) .* warpedImage + ...
                uint8(repmat(~mask & pano_mask, [1,1,3])) .* panorama;
% 
%     figure
%     imshow(panorama)
    
    % update those pano pixels
    pano_mask = pano_mask | mask;
end
% figure
% imshow(panorama)

for i = numImages:-1:centerImageIdx %1:numImages

    I = readimage(srcScene, i);

    % Transform I into the panorama.
    warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);
        
    if i == numImages
        mask = true(size(I,1),size(I,2));
        mask(:, 1:uint16(size(I,2)/2)) = false;
    % after first, only overwrite the face
    else
        % find face mask
        c = uint16(allPoints{i}(:, 1));
        r = uint16(allPoints{i}(:, 2));

        mask = false(size(I,1),size(I,2));
        keskelt = uint16(size(I,2) / 2 + (c(27) - size(I,2)/2) * (i-centerImageIdx) / (numImages-centerImageIdx));
        mask(:, uint16(size(I,2)/2)-5:keskelt) = true;
    end
    
    mask = imwarp(mask, tforms(i), 'OutputView', panoramaView);
        
    panorama =  uint8(repmat(mask & pano_mask,  [1,1,3])) .* (blend_f * warpedImage + (1-blend_f) * panorama) + ...
                uint8(repmat(mask & ~pano_mask, [1,1,3])) .* warpedImage + ...
                uint8(repmat(~mask & pano_mask, [1,1,3])) .* panorama;

%     figure
%     imshow(panorama)
    
    % update those pano pixels
    pano_mask = pano_mask | mask;
end

figure
figure;imshow(panorama)
imwrite(panorama, fullfile(imgSrcFolder, 'panorama01.png'));
imwrite(panorama, fullfile(imgSrcFolder, 'panorama02.png'));
% figure;imshow(imgaussfilt(panorama, 2));