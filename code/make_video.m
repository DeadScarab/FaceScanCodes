clearvars

folder = 'C:\Users\v\Desktop\videos-pictures\rainer\rainer_high_quality';
files = dir(folder);

dstVideo = fullfile('C:\Users\v\Desktop\videos-pictures\rainer', 'rainer_hq.avi');
v1 = VideoWriter(dstVideo, 'Motion JPEG AVI');
open(v1);

for i=3:length(files)
    [~, ~, ext] = fileparts(files(i).name);
    ext = lower(ext);
    if strcmp(ext, '.jpg')
        full_name = fullfile(folder, files(i).name);
        img = imread(full_name);
        writeVideo(v1, img);
    end
end

close(v1);