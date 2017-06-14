function [ ] = attachtexture( filename, texturename, linkedfilename )
%ATTACHTEXTURE Creates a MTL file 'filename' with a refence to 'texturename' as the texture 

%   Using 'linkedfilename' as a refrence, a new MTL file is created with
%   a refrnce to the texture 'texturename'

copyfile(filename,linkedfilename);
fid = fopen(linkedfilename, 'a+');
fprintf(fid, 'map_Kd %s \n', texturename);
fclose(fid);
end

