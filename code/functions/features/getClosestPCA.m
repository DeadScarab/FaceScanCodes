function [closestIdx, error] = getClosestPCA(imagesDB, testImg)
% First does PCA analysis on imageDB using https://se.mathworks.com/help/stats/pca.html
% Secondly, finds PCA coords for testImg, and using those finds norm1
% distances from all imagesDB images. Returns closest and distances.
% NB! Calculations done on centered images - i.e. average vector (mu) is
% subtracted first.
    n = length(imagesDB);

    [rows, cols, ~] = size(imagesDB{1}); % extract img size
    
    % Reading face from the databese for training set
    % make images as vectors
    imageVectors = zeros(n, rows*cols);  % variables x observations
    parfor i = 1:n
        grayface = imagesDB{i};
        if length(size(grayface)) == 3
            grayface = rgb2gray(grayface);
        end
        imageVectors(i, :) = reshape(grayface, 1, []);
    end
    
    [coeff,score,~,~,explained,mu] = pca(imageVectors);
    
    testImg = imresize(testImg, [rows, cols]);
    if length(size(testImg)) == 3
        testImg = rgb2gray(testImg);
    end
    testImgVector = reshape(testImg, 1, []);
    testImgVector = double(testImgVector);
    testImgPCAScore = (testImgVector - mu) * coeff;
  
    % remove some pca comp
    % explained(51:end) = 0;
    
    % find distances
    error = zeros(1, n, 'double');
    parfor i = 1:n
        error(i) = abs(testImgPCAScore - score(i, :)) * explained;
    end
    
    [~, closestIdx] = min(error);
end