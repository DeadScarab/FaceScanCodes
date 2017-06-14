ids = [5, 7, 12, 14, 18, 26, 43];

lbp = [];
for i = [5, 7, 12, 14, 18, 26, 43]
    img_name = fullfile('C:\Users\v\Desktop\FaceScan_ICV\assets\regions_db_all\fullFace', sprintf('male%03d.png', i));
    img = imread(img_name);
    gray_img = rgb2gray(img);
    gray_img = imgaussfilt(gray_img, 5);
    lbp = [lbp; extractLBPFeatures(gray_img,'CellSize',[600 650])];
end

figure;
bar(lbp', 'grouped');
legend('5', '7', '12', '14', '18', '26', '43');
