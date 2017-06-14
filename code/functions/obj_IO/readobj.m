function [ points , mapping ] = readobj( filename )
%READOBJ Read OBJ file and return ordered vertecies and oredered faces

%   Reads OBJ 'filename' and writes vertecies into a (:,3) 'points'
%   variable, faces are written into a (4,2,:) 'mapping'
%   the input OBJ file should only contain quads or lower vertex count
%   polygons and the file should not contain vertex normal information

file = textread(filename, '%s', 'delimiter', '\n');
verts =file( strmatch('v ', file));
map =file( strmatch('f ', file));

points = [];
mapping = [];
for line = verts
    [a,b,c,d] = strread(strjoin(line),'%s %f %f %f','delimiter',' ');
    points = [points; [b,c,d]];
end

nof = [];
iterator = 0;
for line = map
    all = strread(strjoin(map),'%s','delimiter','/');
    all = strread(strjoin(all),'%s','delimiter',' ');
    for i = 1:size(all)
        if(strjoin(all(i))~='f')
            sub_iterator = sub_iterator + 1;
            nof(:,sub_iterator,iterator)=str2double(all(i));
        else
            iterator = iterator + 1;
            sub_iterator = 0;
        end
    end

    for i = 1:(size(nof,3))
        sub_mapping = [];
        for j = 1:(size(nof,2)/2)
            sub_mapping = [sub_mapping; [nof(1,j*2-1,i),nof(1,j*2,i)]];
        end
        
        mapping(:,:,size(mapping,3)+1) = sub_mapping;
    end
    mapping = mapping(:,:,2:end);
    
end


end

