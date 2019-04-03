function [featureduration, predictionduration, datefeat, demofeat, ...
          nbuckets, navgseg, nvolseg, nbuckpmeas, nrawmeasures, nbucketmeasures, nrangemeasures, ...
          nvolmeasures, navgsegmeasures, nvolsegmeasures, ncchangemeasures, ...
          npmeanmeasures, npstdmeasures, nbuckpmeanmeasures, nbuckpstdmeasures, ...
          nrawfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
          nvolsegfeatures, ncchangefeatures, npmeanfeatures, npstdfeatures, ...
          nbuckpmeanfeatures, nbuckpstdfeatures, ndatefeatures, ndemofeatures, ...
          nfeatures, nnormfeatures] = setNumMeasAndFeatures(featureparamsrow, measures, nmeasures)

% setNumMeasAndFeatures - sets the number of measures and features for a
% given parameter combination

featureduration    = featureparamsrow.featureduration;
predictionduration = featureparamsrow.predictionduration;
datefeat          = featureparamsrow.datefeat;
demofeat           = featureparamsrow.demofeat;

nbuckets           = featureparamsrow.nbuckets;
navgseg            = featureparamsrow.navgseg;
nvolseg            = featureparamsrow.nvolseg;
nbuckpmeas         = featureparamsrow.nbuckpmeas;

nrawmeasures       = sum(measures.RawMeas);
nbucketmeasures    = sum(measures.BucketMeas);
nrangemeasures     = sum(measures.Range);
nvolmeasures       = sum(measures.Volatility);
navgsegmeasures    = sum(measures.AvgSeg);
nvolsegmeasures    = sum(measures.VolSeg);
ncchangemeasures   = sum(measures.CChange);
npmeanmeasures     = sum(measures.PMean);
npstdmeasures      = sum(measures.PStd);
nbuckpmeanmeasures = sum(measures.BuckPMean);
nbuckpstdmeasures  = sum(measures.BuckPStd);

nrawfeatures       = nrawmeasures * featureduration;
nbucketfeatures    = nbucketmeasures * nbuckets * featureduration;
nrangefeatures     = nrangemeasures;
nvolfeatures       = nvolmeasures * (featureduration - 1);
navgsegfeatures    = navgsegmeasures * navgseg;
nvolsegfeatures    = nvolsegmeasures * nvolseg;
ncchangefeatures   = ncchangemeasures;
npmeanfeatures     = npmeanmeasures;
npstdfeatures      = npstdmeasures;
nbuckpmeanfeatures = nbuckpmeanmeasures * nbuckpmeas;
nbuckpstdfeatures  = nbuckpstdmeasures  * nbuckpmeas;


if datefeat == 0
    ndatefeatures = 0;
elseif datefeat == 1
    ndatefeatures = 2;
else
    ndatefeatures = datefeat - 1;
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
                  npmeanfeatures + npstdfeatures + nbuckpmeanfeatures + nbuckpstdfeatures + ...
                  ndatefeatures + ndemofeatures;
end

