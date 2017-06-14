function [ Point_Vectors ] = gaussallmove3D( points, fromarr, toarr, gsizearr, multiplier, overextend, allmove)
%GAUSSALLMOVE Move all 'points' using vectors 'fromarr'->'toarr' based on
%their distance to 'fromarr points'

%   For all 'points', calculate the distance from each 'fromarr' and then
%   apply 'fromarr'->'toarr' vector to those points based on f(distance) 
%   'gsizearr' defines each vectors effect range
%   'multiplier' multiplies with each vectors 'gsizearr' to adjust the
%   gaussian strength and range
%   'overextend' multiplies with each vector to overexaggerate the move
%   vector
%   'allmove' disables vectors with larger 'gsizearr' values for better
%   accuracy


feature_count = size(fromarr);
Point_Vectors = zeros(size(points));
counter = 0;
for point = points'
    counter = counter + 1;
    Vector = [0, 0, 0, 0];
    for i = 1:feature_count
        from = fromarr(i,:)';
        to = toarr(i,:)';
        main_vector = (to - from)';
        
        main_vector(3) = 0;
        
        
        if allmove > -0.5 && gsizearr(i) < 0.25 || allmove > 0.5 && gsizearr(i) < 0.35 || allmove > 1.5
            dist_from_epicenter = ((from(1)-point(1))^2+(from(2)-point(2))^2+((from(3)-point(3)) / 4 )^2)^0.5;
            move_amount = 1-1/(1+exp((-dist_from_epicenter/(10*gsizearr(i)^2*multiplier)+0.2)*7));
        else
            move_amount = 0;
        end
        
        Vector = [Vector(1)+move_amount, Vector(2:4) + (move_amount * main_vector)];
        
        if move_amount==1
        end
    end
    
    if Vector(1)<1
        Vector(1) = 1;
    end
    Vector(2:4) = Vector(2:4)/Vector(1) * overextend;
    
    Point_Vectors(counter,:) = point'+Vector(2:4);

end


end