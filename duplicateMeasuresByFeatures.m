function [expandedarray] = duplicateMeasuresByFeatures(inputarray, expandby, nmeasures)

% duplicateMeasuresByFeatures - takes matrix with a single column per
% measure, and duplicates to give each measure expandby times in columns

expandedarray    = [];

for m = 1:nmeasures
    expandedarray = [expandedarray,    inputarray(:,m) * ones(1, expandby)];
end

end

