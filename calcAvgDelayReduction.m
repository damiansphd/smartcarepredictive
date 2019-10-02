function [epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(pmAMPred, featureindex, labels, pred, thresharray)

% calcAvgDelayReduction - calculates the avgdelayreduction over the
% threshold levels covering all the predictions from the model.

[thresharraysort, ~] = sort(thresharray, 'descend');

nepisodes = size(thresharraysort, 1);
epiavgdelayreduction = zeros(nepisodes, 1);
trigintrtpr          = zeros(nepisodes, 1);
avgtrigdelay            = zeros(nepisodes, 1);

for a = 1:nepisodes
    [epiavgdelayreduction(a), trigintrtpr(a), avgtrigdelay(a), ~] = calcAvgDelayReductionForThresh(pmAMPred, ...
        featureindex, labels, pred, thresharraysort(a));
    fprintf('For threshold %.4f, Reduction in Delay is %.3f, and Intr TPR is %.3f, and Time Delay is %.3f\n', ...
        thresharraysort(a), epiavgdelayreduction(a), trigintrtpr(a), avgtrigdelay(a));
end

end

