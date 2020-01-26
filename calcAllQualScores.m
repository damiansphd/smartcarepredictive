function [pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmTrCVPatientSplit, epilen)
% calcAllQualScores - function that calls all the underlying quality score
% calculation functions

[pmDayRes, pmAMPredUpd] = calcPredQualityScore(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmTrCVPatientSplit);
pmDayRes      = calcModelQualityScores(pmDayRes, trcvlabels, ntrcvexamples);
pmDayRes      = calcAvgEpiPred(pmDayRes, pmTrCVFeatureIndex, trcvlabels, epilen);  

end

