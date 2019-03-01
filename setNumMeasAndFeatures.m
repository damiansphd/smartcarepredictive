function [featureduration, predictionduration, monthfeat, demofeat, ...
          nbuckets, navgseg, nvolseg, nrawmeasures, nbucketmeasures, nrangemeasures, ...
          nvolmeasures, navgsegmeasures, nvolsegmeasures, ncchangemeasures, npmeasmeasures, ...
          nrawfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
          nvolsegfeatures, ncchangefeatures, npmeasfeatures, ndatefeatures, ndemofeatures, ...
          nfeatures, nnormfeatures] = setNumMeasAndFeatures(featureparamsrow, measures, nmeasures)

% setNumMeasAndFeatures - sets the number of measures and features for a
% given parameter combination

featureduration    = featureparamsrow.featureduration;
predictionduration = featureparamsrow.predictionduration;
monthfeat          = featureparamsrow.monthfeat;
demofeat           = featureparamsrow.demofeat;

nbuckets           = featureparamsrow.nbuckets;
navgseg            = featureparamsrow.navgseg;
nvolseg            = featureparamsrow.nvolseg;

nrawmeasures       = sum(measures.RawMeas);
nbucketmeasures    = sum(measures.BucketMeas);
nrangemeasures     = sum(measures.Range);
nvolmeasures       = sum(measures.Volatility);
navgsegmeasures    = sum(measures.AvgSeg);
nvolsegmeasures    = sum(measures.VolSeg);
ncchangemeasures   = sum(measures.CChange);
npmeasmeasures     = sum(measures.PatMeas);

nrawfeatures       = nrawmeasures * featureduration;
nbucketfeatures    = nbucketmeasures * nbuckets * featureduration;
nrangefeatures     = nrangemeasures;
nvolfeatures       = nvolmeasures * (featureduration - 1);
navgsegfeatures    = navgsegmeasures * navgseg;
nvolsegfeatures    = nvolsegmeasures * nvolseg;
ncchangefeatures   = ncchangemeasures;
npmeasfeatures     = npmeasmeasures * 2;

if monthfeat == 0
    ndatefeatures = 0;
elseif monthfeat == 1
    ndatefeatures = 2;
else
    ndatefeatures = monthfeat - 1;
end
if demofeat == 1
    ndemofeatures = 0;
elseif demofeat == 2
    ndemofeatures = 5;
else
    ndemofeatures = 1;
end

nfeatures       = nmeasures * featureduration;
nnormfeatures   = nrawfeatures + nbucketfeatures + nrangefeatures + nvolfeatures + ...
                    navgsegfeatures + nvolsegfeatures + ncchangefeatures + ...
                    npmeasfeatures + ndatefeatures + ndemofeatures;
end

