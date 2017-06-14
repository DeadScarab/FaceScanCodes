%Function for creating a bledshape from scratch

%%DEFINE DATA DIRECTORIES
% basemodel_dir = 'model_data\model_objects\';
basemodel_dir = '..\assets\wrapped_models';
refrence_model = 'model_data\basemodels\base_model.obj';
output_dir = 'model_data';  % where to save matlab bin, probably shouldnt change
directory = dir(basemodel_dir);

% add subdirs to path
addpath('functions/obj_IO')
addpath('functions/obj_morph')
addpath('functions/feature_func')

%%REFRENCE MODEL
[ points , ~ ] = readobj( refrence_model );


model_points = zeros(size(points,1), 3, 1);
basemodel_counter = 0;

%%READ MODELS AND SAVE TO 'blendshape_points.mat'
% Order is important
for file_index=1:length(directory)
    file_name = directory(file_index).name;
    obj_file = regexp(file_name, ['^.*', regexptranslate('escape', '.obj')], 'match', 'once');
    if ~isempty(obj_file)
        basemodel_counter = basemodel_counter + 1;
        disp(fullfile(basemodel_dir,file_name))
        [ points , ~ ] = readobj( fullfile(basemodel_dir,file_name) );
        model_points(:,:,basemodel_counter) = points;
    end
end
save(fullfile(output_dir, 'blendshape_points.mat'), 'model_points' );



