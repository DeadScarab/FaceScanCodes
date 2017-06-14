function [closestIdx, error] = ssim_info(imagesDB, testImg)
% Convert images to grayscale and find SSIM index between testImg and each
% image in the imagesDB.
% https://se.mathworks.com/help/images/ref/ssim.html
    n = length(imagesDB);

    [rows, cols, ~] = size(imagesDB{1}); % extract img size
    
    testImg = imresize(testImg, [rows, cols]);
    if length(size(testImg)) == 3
        testImg = rgb2gray(testImg);
    end
    
    error = zeros(1, n, 'double');
    parfor i = 1:n
        % make it grayscale
        grayface = imagesDB{i};
        if length(size(grayface)) == 3
            grayface = rgb2gray(grayface);
        end
        
        error(i) = 1 - ssim(testImg, grayface);
    end
    
    [~, closestIdx] = min(error);
end