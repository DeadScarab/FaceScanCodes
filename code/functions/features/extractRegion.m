function [extracted_img, extracted_gray_img, mask] = extractRegion(img_file, points2d_file, regNr)
% Returns specified region of face and resize to specific size. For eyes
% and mouth, the facial background is included; for nose and face black
% background.
% regNr: 
% 0 - full OF area, 
% 1 - face wo eyes&nose&mouth, 
% 2 - eyes
% 3 - nose, 
% 4 - mouth
% 5 - nose from side, not used
    fullFace = [1:17, 27:-1:25, 20:-1:18];
    eyes = [18:20, 25:27, 46,47,48,43,40,41,42,37];
    nose = [40,32:36,43,28];
    mouth = [49:60];
    noseSide = [40,43,31,36,35,34,33,32];

% img_file = 'M:\iCV\Face Scan\Temp\database\male013_front_1.png';
% points2d_file = 'M:\iCV\Face Scan\Temp\database\male013_front_1_2d.txt';
% regNr = 1;
    img = imread(img_file);
    fid = fopen(points2d_file);
    pts = fscanf(fid, '%f');
    fclose(fid);
    x = pts(1:68); y = pts(69:136);
    [rows, cols, ~] = size(img);
    c = x * cols;
    r = y * rows;
    
    c_nose = c; r_nose = r;
    c_nose(40) = c_nose(40) + 2*30;
    c_nose(43) = c_nose(43) - 2*30;
    
    c_noseSide = c; r_noseSide = r;
    c_noseSide(40) = c_noseSide(40) + 20;
    c_noseSide(31) = c_noseSide(31) + 30;
    c_noseSide(36) = c_noseSide(36) + 30;
    c_noseSide(32) = c_noseSide(32) - 30;
    
    maskFullFace = getPolyMask(img, c, r, fullFace, 0, 0);
    maskEyes = getPolyMask(img, c, r, eyes, 0, 2);
    maskNose = getPolyMask(img, c_nose, r_nose, nose, 30, 3);
    maskMouth = getPolyMask(img, c, r, mouth, 0, 4);
%     maskFullFace = or(maskFullFace, maskEyes);
    maskFace = xor(maskFullFace, maskEyes | maskNose | maskMouth);
    
    maskNoseSide = getPolyMask(img, c_noseSide, r_noseSide, noseSide, 10, 5);
    
    switch regNr
        case 0
            mask = maskFullFace;
        case 1
            mask = maskFace;
        case 2
            mask = maskEyes;
        case 3
            mask = maskNose;
        case 4
            mask = maskMouth;
        case 5
            mask = maskNoseSide;
    end
        
    extracted_img = img .* repmat(uint8(mask), [1 1 3]);
    
    stats = regionprops(mask, 'BoundingBox');
    extracted_img = imcrop(extracted_img, stats(1).BoundingBox);
    
    % resize to standard size if nose or face - others already fixed size
    if regNr == 1
        extracted_img = imresize(extracted_img, [600 650]);
    elseif regNr == 3
        extracted_img = imresize(extracted_img, [300 200]);
    elseif regNr == 5
        extracted_img = imresize(extracted_img, [250 250]);
    elseif regNr == 0
%         extracted_img = imgaussfilt(extracted_img, 10);
        extracted_img = imresize(extracted_img, [600 650]);
    end
    
    extracted_gray_img = rgb2gray(extracted_img);
    
% figure;imshow(extracted_img);

end

function mask = getPolyMask(img, c, r, idx, dilateSize, regNr)
    c_reg = c(idx);
    r_reg = r(idx);
    if regNr == 2 % eyes - rectangle
        c_avg = (c(40) + c(43)) / 2;
        r_avg = (r(40) + r(43)) / 2;
        c_min = c_avg - 270; c_max = c_avg + 270;
        r_min = r_avg - 130; r_max = r_avg + 70;
        mask = roipoly(img, [c_min, c_min, c_max, c_max], [r_min, r_max, r_max, r_min]);
    elseif regNr == 4 % mouth - rectangle
        c_avg = (c(52) + c(58)) / 2;
        r_avg = (r(52) + r(58)) / 2;
        c_min = c_avg - 160; c_max = c_avg + 160;
        r_min = r_avg - 70; r_max = r_avg + 70;
        mask = roipoly(img, [c_min, c_min, c_max, c_max], [r_min, r_max, r_max, r_min]);
    else
        % extract exact area, dilate
        mask_idx = convhull(c_reg, r_reg);
        mask = roipoly(img, c_reg(mask_idx), r_reg(mask_idx));
        mask = imdilate(mask, strel('disk', dilateSize));
    end
%     mask = repmat(mask, [1 1 3]);
end