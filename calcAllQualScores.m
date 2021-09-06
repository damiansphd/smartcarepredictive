function [mdlres, ampredupd] = calcAllQualScores(mdlres, labels, nexamples, ampred, featureindex, patientsplit, epilen, fpropthresh)
% calcAllQualScores - function that calls all the underlying quality score
% calculation functions

[mdlres, ampredupd] = calcPredQualityScore(mdlres, ampred, featureindex, patientsplit);

mdlres = calcModelQualityScores(mdlres, labels, nexamples);

%mdlres      = calcAvgEpiPred(mdlres, featureindex, labels, epilen, fpropthresh, ampredupd, alldayidx);  

alldayidx = true(size(labels, 1), 1);
[epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNew(featureindex, labels, mdlres.Pred, epilen, alldayidx);
[mdlres] = calcAvgEpiPred(mdlres, epiindex, epilabl, epipred, episafeidx, featureindex, labels, fpropthresh);


end

