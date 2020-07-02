function [featureduration, predictionduration, datefeat, nbuckets, navgseg, nvolseg, nbuckpmeas, ...
          nrawfeatures, nmsfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
          nvolsegfeatures, ncchangefeatures, npmeanfeatures, npstdfeatures, ...
          nbuckpmeanfeatures, nbuckpstdfeatures, ndatefeatures, ndemofeatures] = ...
            setBaseNumMeasAndFeatures(basefeatparamsrow, nmeasures)

% setBaseNumMeasAndFeatures - sets the number of base features for a
% given parameter combination (for all measures)

featureduration    = basefeatparamsrow.featureduration;
predictionduration = basefeatparamsrow.predictionduration;
datefeat           = basefeatparamsrow.datefeat;

nbuckets           = basefeatparamsrow.nbuckets;
navgseg            = basefeatparamsrow.navgseg;
nvolseg            = basefeatparamsrow.nvolseg;
nbuckpmeas         = basefeatparamsrow.nbuckpmeas;

nrawfeatures       = nmeasures * featureduration;
nmsfeatures        = nmeasures * featureduration;
nbucketfeatures    = nmeasures * nbuckets * featureduration;
nrangefeatures     = nmeasures;
nvolfeatures       = nmeasures * (featureduration - 1);
navgsegfeatures    = nmeasures * navgseg;
nvolsegfeatures    = nmeasures * nvolseg;
ncchangefeatures   = nmeasures;
npmeanfeatures     = nmeasures;
npstdfeatures      = nmeasures;
nbuckpmeanfeatures = nmeasures * nbuckpmeas;
nbuckpstdfeatures  = nmeasures * nbuckpmeas;

if datefeat == 1
    ndatefeatures = 2;
else
    ndatefeatures = datefeat - 1;
end

ndemofeatures = 5;

end

