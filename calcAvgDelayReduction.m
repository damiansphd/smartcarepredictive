function [avgdelayreduction] = calcAvgDelayReduction(pmAMPred, featureindex, labels, pred)

% calcAvgDelayReduction - calculates the avgdelayreduction over the
% threshold levels covering all the predictions from the model.

[predsort, ~] = sort(pred, 'descend');

nexamples = size(predsort, 1);
avgdelayreduction = zeros(nexamples, 1);

for a = 1:nexamples
    avgdelayreduction(a) = calcAvgDelayReductionForThresh(pmAMPred, featureindex, labels, pred, predsort(a));
end

end

