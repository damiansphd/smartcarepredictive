function [avgdelayreduction, trigintrtpr, avgtrigdelay, intrtrigarray, count, trigcount] = ...
                calcAvgDelayReductionForThresh(epiindex, featureindex, labels, pred, thresh, printlog)

% calcAvgDelayReductionForThres - calculates the average reduction in time to
% treatment (over all interventions) for a given threshold level

%reduction       = zeros(size(pmAMPred, 1), 1);
%trigdelayarray  = zeros(size(pmAMPred, 1), 1);
%intrtrigarray   = zeros(size(pmAMPred, 1), 1);
reduction       = zeros(size(epiindex, 1), 1);
trigdelayarray  = zeros(size(epiindex, 1), 1);
intrtrigarray   = zeros(size(epiindex, 1), 1);
count           = 0;
trigcount       = 0;

%for i = 1:size(pmAMPred, 1)
%    pnbr       = pmAMPred.PatientNbr(i);
%    exstart    = pmAMPred.Pred(i);
%    treatstart = pmAMPred.IVScaledDateNum(i);

for i = 1:size(epiindex, 1)
    pnbr       = epiindex.PatientNbr(i);
    exstart    = epiindex.Fromdn(i);
    treatstart = epiindex.Todn(i) + 1;
    
    intrlabl = labels(featureindex.PatientNbr == pnbr & featureindex.ScenType == 0 & featureindex.CalcDatedn >= exstart & featureindex.CalcDatedn < treatstart);
    if ~all(intrlabl)
        fprintf('**** Not all labels are 1 for intervention %3d:%3d:%3d ****\n', pnbr, exstart, treatstart);
    end
    
    intrpred = pred(featureindex.PatientNbr == pnbr & featureindex.ScenType == 0 & featureindex.CalcDatedn >= exstart & featureindex.CalcDatedn < treatstart);
    
    intrfeatidx = featureindex(featureindex.PatientNbr == pnbr & featureindex.ScenType == 0 & featureindex.CalcDatedn >= exstart & featureindex.CalcDatedn < treatstart, :);
    
    if size(intrpred, 1) ~= 0
        triggeridx = find(intrpred > thresh, 1, 'first');
        if size(triggeridx, 1) ~= 0
            trigdn = intrfeatidx.CalcDatedn(triggeridx);
            %reduction(i) = size(intrpred, 1) + 1 - triggeridx;
            reduction(i) = treatstart - trigdn;
            trigcount = trigcount + 1;
            intrtrigarray(i) = 1;
            %trigdelayarray(i) = triggeridx - 1;
            trigdelayarray(i) = trigdn - exstart;
        else
            intrtrigarray(i) = -1;
            %trigdelayarray(i) = size(intrpred, 1) - 1;
            trigdelayarray(i) = treatstart - exstart;
        end
        count = count + 1;
    end
end

%fprintf('TotIntr=%d, Pred=%d, Trig=%d\n', size(pmAMPred, 1), count, trigcount);
if printlog
    fprintf('TotIntr=%d, Pred=%d, Trig=%d\n', size(epiindex, 1), count, trigcount);
end

avgdelayreduction = sum(reduction) / count;
trigintrtpr = 100 * trigcount / count;
avgtrigdelay = sum(trigdelayarray) / count;

end
