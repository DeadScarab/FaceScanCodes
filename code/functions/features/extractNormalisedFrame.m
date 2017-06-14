function [img_roi_out_file, img_roi_out] = extractNormalisedFrame(inputFile, data, frame_nr, output_folder, f_name, fileType)
% Given video/image and OF datafile, extracts required frame, rotates and
% scales it to "normal" and resizes the output picture. Saves also only 2d
% & 3d coordinates into separate files.
% For scaling, the p_scale field from OF is used. For rotating, 3D pts rot
% is used.

%% some assumed inputs
    k = 120;  % how large area around face we want, relative - don't change
    outSize = [1080, 1080];
    
    %% rest
    % create numbers as text
    feat_nrs_str = {};
    for i = 0:67
        feat_nrs_str{i+1} = num2str(i);
    end

    % extract required frameimage
    if fileType == 0
        v = VideoReader(inputFile);
        for i = 1:frame_nr
            img = readFrame(v);
        end
    elseif fileType == 1
        img = imread(inputFile);
    end

    xs = data(frame_nr).x_img;
    ys = data(frame_nr).y_img;

    p_scale = data(frame_nr).p_scale;
    p_tx = data(frame_nr).p_tx;
    p_ty = data(frame_nr).p_ty;
    p_rz = data(frame_nr).p_rz;

    px = data(frame_nr).x_3d;
    py = data(frame_nr).y_3d;
    pz = data(frame_nr).z_3d;

    pose_Tx = data(frame_nr).Tx;
    pose_Ty = data(frame_nr).Ty;
    pose_Tz = data(frame_nr).Tz;
    pose_Rx = data(frame_nr).Rx;
    pose_Ry = data(frame_nr).Ry;
    pose_Rz = data(frame_nr).Rz;

    % extract face and rotate it, save
    [img_row_nr, img_col_nr, ~] = size(img);
    half_rows = floor(p_scale*k);
    img_roi = uint8(zeros([2*half_rows+1, 2*half_rows+1, 3]));
    row_min = int16(max(p_ty - half_rows, 1));
    row_max = int16(min(p_ty + half_rows, img_row_nr));
    col_min = int16(max(p_tx - half_rows, 1));
    col_max = int16(min(p_tx + half_rows, img_col_nr));
    %     k = min(k, min(min(p_ty, img_row_nr - p_ty), min(p_tx, img_col_nr - p_tx)) / p_scale);
    %     img_roi = img(int16(p_ty - p_scale*k):int16(p_ty + p_scale*k), int16(p_tx - p_scale*k):int16(p_tx + p_scale*k), :);
    img_roi(half_rows - p_ty + row_min+1:half_rows + row_max-p_ty+1, half_rows - p_tx + col_min+1:half_rows + col_max-p_tx+1, :) = img(row_min:row_max, col_min:col_max, :);
    img_roi_new = imrotate(img_roi, rad2deg(p_rz), 'crop');
    
    img_roi_out = imresize(img_roi_new, outSize);
    img_roi_out_file = fullfile(output_folder, sprintf('%s.png', f_name));
    imwrite(img_roi_out, img_roi_out_file);
    [img_rows_nr, img_cols_nr, ~] = size(img_roi);

    % translate and rotate points
    xy = [xs - p_tx; ys - p_ty];
    R = [cos(p_rz), sin(p_rz); -sin(p_rz), cos(p_rz)]; % rot mat
    xy = R * xy; % rotate
    % translate onto img_roi
    [h, w, ~] = size(img_roi_new);
    xs_new = xy(1, :) + w /2;
    ys_new = xy(2, :) + h / 2;
    xs_norm = xs_new / img_cols_nr;
    ys_norm = ys_new / img_rows_nr;

    % save new coords to file
%     fileID = fopen(fullfile(output_folder, sprintf('%s_%d_2d.txt', f_name, frame_nr)), 'w');
    fileID = fopen(fullfile(output_folder, sprintf('%s_2d.txt', f_name)), 'w');
    fprintf(fileID,'%f ', xs_norm);
    fprintf(fileID,'%f ', ys_norm);
    fclose(fileID);

    % translate and rotate 3d points
    xyz = [px - pose_Tx; py - pose_Ty; pz - pose_Tz];

    %     pose_Rx = -pose_Rx;
    pose_Rx = 0;
    pose_Ry = -pose_Ry;

    Rx_mat = [1, 0, 0; 0, cos(pose_Rx), -sin(pose_Rx); 0, sin(pose_Rx), cos(pose_Rx)]; 
    Ry_mat = [cos(pose_Ry), 0, sin(pose_Ry); 0, 1, 0; -sin(pose_Ry), 0, cos(pose_Ry)]; 
    Rz_mat = [cos(pose_Rz), sin(pose_Rz), 0; -sin(pose_Rz), cos(pose_Rz), 0; 0, 0, 1]; 
    % xyz = Rx_mat*Ry_mat*Rz_mat * xyz; % rotate
    xyz = Rz_mat*Ry_mat*Rx_mat * xyz; % rotate
    % rotate it 180 around z...

    % normalise 3d points to 0,1 - similar to texture
    % using points 37, 46 and 49,54 -> normalise distance
    d1 = norm([xs_norm(1, 37) - xs_norm(1, 46), ys_norm(1, 37) - ys_norm(1, 46)], 2);
    d2 = norm([xs_norm(1, 49) - xs_norm(1, 55), ys_norm(1, 49) - ys_norm(1, 55)], 2);
    D1 = norm([xyz(1, 37) - xyz(1, 46), xyz(2, 37) - xyz(2, 46)], 2);  % 3d dist, xy plane only
    D2 = norm([xyz(1, 49) - xyz(1, 55), xyz(2, 49) - xyz(2, 55)], 2);  % 3d dist, xy plane only
    h1 = d1 / D1;
    h2 = d2 / D2;
    h = (h1 + h2) / 2;
    % convert xy to cart
    [theta, rho] = cart2pol(xyz(1, :), xyz(2, :));
    rho = h * rho;  % normalise distance
    [tmp_x, tmp_y] = pol2cart(theta, rho);
    tmp_z = xyz(3, :) * h;
    xyz_norm = [tmp_x; tmp_y; tmp_z] + transpose(repmat([0.5, 0.5, 0], 68, 1));

    % save new 3D coords to file
    fileID = fopen(fullfile(output_folder, sprintf('%s_3d.txt', f_name)), 'w');
    fprintf(fileID,'%f ', xyz_norm(1, :));
    fprintf(fileID,'%f ', xyz_norm(2, :));
    fprintf(fileID,'%f ', xyz_norm(3, :));
    fclose(fileID);
    
    % save img with feature points marked
    img_marked = insertMarker(img_roi_new, [xs_new; ys_new]', 'x');
    img_marked = insertText(img_marked, [xs_new; ys_new]', feat_nrs_str, 'BoxOpacity', 0);
    imwrite(imresize(img_marked, outSize), fullfile(output_folder, sprintf('%s_marked.png', f_name)));
    

end