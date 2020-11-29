function [idx] = extractIdxForRange(data, lowerb, upperb)

% extractIdxForRange - return an index for the subset of the data between
% the lower and upper bound values

idx = data > lowerb & data <= upperb;

end

