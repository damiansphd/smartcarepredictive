function [mdlres, ampredupd] = calcAllQualScores(mdlres, trcvlabels, ntrcvexamples, ampred, featureindex, patientsplit, epilen)
% calcAllQualScores - function that calls all the underlying quality score
% calculation functions

[mdlres, ampredupd] = calcPredQualityScore(mdlres, trcvlabels, ntrcvexamples, ampred, featureindex, patientsplit);
mdlres      = calcModelQualityScores(mdlres, trcvlabels, ntrcvexamples);
mdlres      = calcAvgEpiPred(mdlres, featureindex, trcvlabels, epilen);  

end

