function [mdlres] = calcAvgEpiPred(mdlres, featidx, labels, epilen)

% calcAvgEpiPred - calculates the average episode predictions for each of 
% the episodic true labels and false labels

[epiindex, epilabl, epipred] = convertResultsToEpisodesNew(featidx, labels, mdlres.Pred, epilen);

mdlres.AvgEpiTPred = 100 * sum(epipred(epilabl == 1))/sum(epilabl == 1);
mdlres.AvgEpiFPred = 100 * sum(epipred(epilabl == 0))/sum(epilabl == 0);
mdlres.AvgEPV      = mdlres.AvgEpiTPred - mdlres.AvgEpiFPred;

fprintf('AvgEPV = %.1f%%, AvgEpiTPred = %.1f%% AvgEpiFPred = %.1f%%', mdlres.AvgEPV, mdlres.AvgEpiTPred, mdlres.AvgEpiFPred);

end

