function [epiavgdelayreduction] = calcAvgDelayReduction(pmAMPred, featureindex, labels, pred, thresharray)

% calcAvgDelayReduction - calculates the avgdelayreduction over the
% threshold levels covering all the predictions from the model.

[thresharraysort, ~] = sort(thresharray, 'descend');

nepisodes = size(thresharraysort, 1);
epiavgdelayreduction = zeros(nepisodes, 1);

for a = 1:nepisodes
    epiavgdelayreduction(a) = calcAvgDelayReductionForThresh(pmAMPred, featureindex, labels, pred, thresharraysort(a));
    fprintf('For threshold %.4f, Reduction in Delay is %.3f\n', thresharraysort(a), epiavgdelayreduction(a));
end

end

