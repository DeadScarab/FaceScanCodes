function [ face_region ] = findregion( filename, region_name )
%FINDREGION Finds vertex indexes of all faces defined by a 'region_name' in 'filename'

%   All indecies of the faces in 'filename' that are defined by a group name of
%   'region_name' are written to 'face_region'

    file = fopen(filename);
    tline = fgets(file);
    correct_section = 0;
    face_region = [];
    face_line_counter = 0;
    while ischar(tline)
        if any(regexp(tline,'f '))
            face_line_counter = face_line_counter+1;
        end
        
        if any(regexp(tline,'g '))
            if any(regexp(tline,region_name))
                correct_section = 1;
            else
                correct_section = 0;
            end
        end
        
        if correct_section == 1 && any(regexp(tline,'f '))
            face_region(end+1) = face_line_counter;
            
            
        end
        tline = fgets(file);
    end

end

