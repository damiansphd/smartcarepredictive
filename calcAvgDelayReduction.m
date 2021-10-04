function [epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex, featureindex, labels, pred, thresharraysort, printlog)

% calcAvgDelayReduction - calculates the avgdelayreduction over the
% threshold levels covering all the predictions from the model.

nepisodes            = size(thresharraysort, 1);
epiavgdelayreduction = zeros(nepisodes, 1);
trigintrtpr          = zeros(nepisodes, 1);
avgtrigdelay         = zeros(nepisodes, 1);

if nepisodes < 1000
    ptinterval = 1;
else
    ptinterval = floor(nepisodes / 1000);
end
    
for a = 1:nepisodes
    % now we have 10,000+ episodes, don't need to calculate for every point
    % - for now calculate every <ptinterval> points, and propogate values in between
    if (a == 1 || a == nepisodes || (a / ptinterval) == round(a / ptinterval, 0))
        [epiavgdelayreduction(a), trigintrtpr(a), avgtrigdelay(a), ~, ~, ~] = calcAvgDelayReductionForThresh(epiindex, ...
            featureindex, labels, pred, thresharraysort(a), printlog);
        if printlog
            fprintf('Idx pt: %d - Threshold %.8f, Reduction in Delay is %.3f, and Intr TPR is %.3f%%, and Time Delay is %.3f\n', ...
                a, thresharraysort(a), epiavgdelayreduction(a), trigintrtpr(a), avgtrigdelay(a));
        end
    else
        epiavgdelayreduction(a) = epiavgdelayreduction(a - 1);
        trigintrtpr(a)          = trigintrtpr(a - 1);
        avgtrigdelay(a)         = avgtrigdelay(a - 1);
    end
    if ~printlog
        if (a / (ptinterval * 20)) == round(a / (ptinterval * 20))
            fprintf('.');
        end
    end
end

fprintf('\n');

end

