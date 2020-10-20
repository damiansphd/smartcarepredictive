function [pmVolFeats, nvolfeats] = createVolFeats(pmRawMeasFeats, nexamples, nmeasures, featureduration)

% createVolFeats - function to create the Volatility features based on the
% Raw measures features (using only the feature window values

nmvolfeats = featureduration - 1;
nvolfeats = nmvolfeats * nmeasures;
pmVolFeats = zeros(nexamples, nvolfeats);

for m = 1:nmeasures
        mrawfeats = pmRawMeasFeats(:, ((m-1) * featureduration) + 1: (m * featureduration));
        mvolfeats = abs(diff(mrawfeats, 1, 2));
        pmVolFeats(:, ((m-1) * nmvolfeats) + 1: (m * nmvolfeats)) = mvolfeats;
end

fprintf('\n');

end


