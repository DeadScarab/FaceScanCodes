function weights = getWeights(error, regNr)
% Finds weights based on errors and region type
% regNr: 
% 0 - full OF area
% 1 - face wo eyes&nose&mountt
% 2 - eyes
% 3 - nose
% 4 - mouth
    
    nrClosestUsed = 2;
    if regNr >= 1
        [~, idx] = sort(error);
        cutoff = error(idx(nrClosestUsed + 1));
        
        tmp = error;
        tmp(tmp > cutoff) = 0;  % remove higher values
        tmp(tmp > 0) = cutoff - tmp(tmp > 0);  % reverse
        
        % check if any values left, if not choose smallest error
        if sum(tmp) <= 0
            [~, minIdx] = min(error);
            tmp(minIdx) = 1;
        end
        
        weights = tmp / sum(tmp); % normalise
    else
        tmp = 1 ./ error;
        weights = tmp / sum(tmp);
    end
end