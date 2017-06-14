function [closestIdx, error] = lbpf_info(imagesDB, testImg)
% Convert images to grayscale and find SSIM index between testImg and each
% image in the imagesDB.
% https://se.mathworks.com/help/images/ref/ssim.html
%     n = length(imagesDB);
% 
%     [rows, cols, ~] = size(imagesDB{1}); % extract img size
%     
%     testImg = imresize(testImg, [rows, cols]);
%     if length(size(testImg)) == 3
%         testImg = rgb2gray(testImg);
%     end
%     
%     lbpTestImg = extractLBPFeatures(testImg);
%     
%     error = zeros(1, n, 'double');
%     parfor i = 1:n
%         % make it grayscale
%         grayface = imagesDB{i};
%         if length(size(grayface)) == 3
%             grayface = rgb2gray(grayface);
%         end
%         lbpDBImg = extractLBPFeatures(grayface);
%         
%         error(i) = sum((lbpTestImg - lbpDBImg).^2);
%     end
%     
%     [~, closestIdx] = min(error);
    
    
     n = length(imagesDB);

    [rows, cols, ~] = size(imagesDB{1}); % extract img size

    for i = 1:n
        % make it grayscale
        grayface = imagesDB{i};
        if length(size(grayface)) == 3
            grayface = rgb2gray(grayface);
        end
        grayface = imgaussfilt(grayface, 2);
        lbpDBImg(i,:) = extractLBPFeatures(grayface);

    end
     [coeff,score,~,~,explained,mu] = pca(lbpDBImg);
    
    testImg = imresize(testImg, [rows, cols]);
    if length(size(testImg)) == 3
        testImg = rgb2gray(testImg);
    end
    testImg = imgaussfilt(testImg, 2);
    testImgVector = extractLBPFeatures(testImg);
    testImgVector = double(testImgVector);
    testImgPCAScore = (testImgVector - mu) * coeff;
  
    % remove some pca comp
    % explained(51:end) = 0;
    
    % find distances
    error = zeros(1, n, 'double');
    parfor i = 1:n
        error(i) = sum(abs(testImgPCAScore - score(i, :))) ;
    end
    
    [~, closestIdx] = min(error);
end

