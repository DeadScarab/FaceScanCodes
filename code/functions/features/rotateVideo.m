function rotateVideo(srcVideo, dstVideo, angle)

% oldFolder = cd('C:\Projects\randomPython\image_stitching');
% cmd = ['python rotate_video.py ', '"', srcVideo,'" "', dstVideo,'"'];
% system(cmd);
% cd(oldFolder);

if exist('angle', 'var') && angle ~= 0
    v = VideoReader(srcVideo);
    v1 = VideoWriter(dstVideo, 'Motion JPEG AVI');
    open(v1);

    while hasFrame(v)
        orig_img = readFrame(v);
        img = imrotate(orig_img, angle);  %if back camera, then -90
        writeVideo(v1, img);
    end
    close(v1);
end

end