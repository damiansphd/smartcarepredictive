function [mdlres] = calcModelQualityScores(mdlres, labels, nexamples)

% calcModelQualityScores - calculates the various quality metrics for a
% given model run.

[mdlres.PredSort, sortidx] = sort(mdlres.Pred, 'descend');
mdlres.LabelSort = labels(sortidx);

for a = 1:nexamples
    TP = sum(mdlres.LabelSort(1:a) == 1);
    FP = sum(mdlres.LabelSort(1:a) == 0);
    TN = sum(mdlres.LabelSort(a+1:nexamples) == 0);
    FN = sum(mdlres.LabelSort(a+1:nexamples) == 1);
    
    if (TP + FP) ~= 0
        mdlres.Precision(a) = TP / (TP + FP);
    else
        mdlres.Precision(a) = 0;
    end
    if (TP + FN) ~= 0
        mdlres.Recall(a) = TP / (TP + FN); 
    else
        mdlres.Recall(a) = 0;
    end
    mdlres.TPR(a) = mdlres.Recall(a);
    if (FP + TN) ~= 0
        mdlres.FPR(a) = FP / (FP + TN);
    else
        mdlres.FPR(a) = 0;
    end
end
    
mdlres.PRAUC    = 100 * trapz(mdlres.Recall, mdlres.Precision);
mdlres.ROCAUC   = 100 * trapz(mdlres.FPR   , mdlres.TPR);
mdlres.Acc      = 100 * (1 - sum(abs(mdlres.PredSort - mdlres.LabelSort)) / nexamples);
if size(mdlres.LabelSort(mdlres.LabelSort), 1) ~= 0
    mdlres.PosAcc   = 100 * (sum(mdlres.PredSort(mdlres.LabelSort)) ...
                                / size(mdlres.LabelSort(mdlres.LabelSort), 1));
else
    mdlres.PosAcc = 100;
end
if size(mdlres.LabelSort(~mdlres.LabelSort), 1) ~= 0
    mdlres.NegAcc   = 100* (sum(1 - mdlres.PredSort(~mdlres.LabelSort)) ...
                                / size(mdlres.LabelSort(~mdlres.LabelSort), 1));
else
    mdlres.NegAcc = 100;
end
fprintf('PR = %.3f%%, ROC = %.3f%%, Acc = %.3f%%, PosAcc = %.3f%%, NegAcc = %.3f%%\n', ...
         mdlres.PRAUC, mdlres.ROCAUC, mdlres.Acc, mdlres.PosAcc, mdlres.NegAcc);

end

