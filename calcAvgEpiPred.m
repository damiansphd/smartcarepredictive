function [mdlres] = calcAvgEpiPred(mdlres, featidx, labels, epilen, fpropthresh, ampred)

% calcAvgEpiPred - calculates the average episode predictions for each of 
% the episodic true labels and false labels, along with the early warning
% and trigger delay

[~, epilabl, epipred, epilablsort, epipredsort] = convertResultsToEpisodesNew(featidx, labels, mdlres.Pred, epilen);

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

%[~, ~, ~, epifpr, ~, ~] = calcQualScores(epilablsort, epipredsort);
%mdlres.IdxOp     = find(epifpr < fpropthresh, 1, 'last');

% choose the best operating point - first find the max point that meets the
% fpr threshold, then find the first point that has the same tpr as this
% point.
[~, ~, epitpr, epifpr, ~, ~] = calcQualScores(epilablsort, epipredsort);
maxidxpt     = find(epifpr < fpropthresh, 1, 'last');
mdlres.IdxOp = find(epitpr == epitpr(maxidxpt), 1, 'first');

% add logic to traverse back to first one where epifpr is the same as at
% the threshold
mdlres.EpiFPROp  = 100 * epifpr(mdlres.IdxOp);
mdlres.EpiPredOp = epipredsort(mdlres.IdxOp);

[mdlres.EarlyWarn, mdlres.TrigIntrTPR, mdlres.TrigDelay, ~, mdlres.IntrCount, mdlres.IntrTrig] = ...
    calcAvgDelayReductionForThresh(ampred(~ismember(ampred.ElectiveTreatment, 'Y'), :), featidx, labels, ...
        mdlres.Pred, mdlres.EpiPredOp);

fprintf('AvgEPV = %.1f%%, AvgEpiTPred = %.1f%% AvgEpiFPred = %.1f%%, EarlyWarn = %.1fd, TrigDelay = %.1fd, TrigIntrTPR = %.1f%%, EpiFPROp = %.3f%%, EpiPredOp = %.3f, IdxOp = %d', ...
    mdlres.AvgEPV, mdlres.AvgEpiTPred, mdlres.AvgEpiFPred, mdlres.EarlyWarn, mdlres.TrigDelay, mdlres.TrigIntrTPR, mdlres.EpiFPROp, mdlres.EpiPredOp, mdlres.IdxOp);

end

