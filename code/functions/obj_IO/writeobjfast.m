function [ ] = writeobjfast( filename, outfilename,  points, texturefile )
%READOBJ Export OBJ file

%   Write 'points' to OBJ file 'outfilename' using 'filename' as a refrence
%   'texturefile' is added as an MTL refrence

outfile = fopen(outfilename,'w');
file = fopen(filename);
tline = fgets(file);

vercount = 1;

while ischar(tline)

    if any(regexp(tline,'v '))
        fprintf(outfile,'%s\n',[ 'v ' num2str(points(vercount,1)) ' ' num2str(points(vercount,2)) ' ' num2str(points(vercount,3)) ]);
        vercount = vercount + 1;
    
     elseif any(regexp(tline,'mtllib'))
         fprintf(outfile,'%s\n',['mtllib ' texturefile]);
         
    else
        fprintf(outfile,'%s\n',tline);
        
    end
    tline = fgets(file);
end

fclose(file);
fclose(outfile);

end