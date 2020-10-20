function [featureduration, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures] = ...
            setBaseNumMeasAndFeaturesNew(basefeatparamsrow, nmeasures)

% setBaseNumMeasAndFeaturesNew - sets the number of base features for a
% given parameter combination (for all measures)

featureduration    = basefeatparamsrow.featureduration;

nrawfeatures       = nmeasures * featureduration;
nmsfeatures        = nmeasures * featureduration;
nvolfeatures       = nmeasures * (featureduration - 1);
npmeanfeatures     = nmeasures;

end

