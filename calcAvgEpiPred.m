function [mdlres] = calcAvgEpiPred(mdlres, featidx, labels, epilen)

% calcAvgEpiPred - calculates the average episode predictions for each of 
% the episodic true labels and false labels

[~, epilabl, epipred] = convertResultsToEpisodesNew(featidx, labels, mdlres.Pred, epilen);

if sum(epilabl == 1) ~= 0
    mdlres.AvgEpiTPred = 100 * sum(epipred(epilabl == 1))/sum(epilabl == 1);
else
    mdlres.AvgEpiTPred = 100;
end
if sum(epilabl == 0) ~= 0
    mdlres.AvgEpiFPred = 100 * sum(epipred(epilabl == 0))/sum(epilabl == 0);
else
    mdlres.AvgEpiFPred = 0;
end

mdlres.AvgEPV      = mdlres.AvgEpiTPred - mdlres.AvgEpiFPred;

fprintf('AvgEPV = %.1f%%, AvgEpiTPred = %.1f%% AvgEpiFPred = %.1f%%', mdlres.AvgEPV, mdlres.AvgEpiTPred, mdlres.AvgEpiFPred);

end

