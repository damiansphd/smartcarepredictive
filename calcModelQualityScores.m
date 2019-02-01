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
    
    mdlres.Precision(a) = TP / (TP + FP);
    mdlres.Recall(a)    = TP / (TP + FN); 
    mdlres.TPR(a)       = mdlres.Recall(a);
    mdlres.FPR(a)       = FP / (FP + TN);
end
    
mdlres.PRAUC    = 100 * trapz(mdlres.Recall, mdlres.Precision);
mdlres.ROCAUC   = 100 * trapz(mdlres.FPR   , mdlres.TPR);
mdlres.Accuracy = 100 * (1 - sum(abs(mdlres.PredSort - mdlres.LabelSort)) / nexamples);
mdlres.PosAcc   = 100 * (sum(mdlres.PredSort(mdlres.LabelSort)) ...
                            / size(mdlres.LabelSort(mdlres.LabelSort), 1));
mdlres.NegAcc   = 100* (sum(1 - mdlres.PredSort(~mdlres.LabelSort)) ...
                            / size(mdlres.LabelSort(~mdlres.LabelSort), 1));
            
fprintf('PR AUC = %.3f%%, ROC AUC = %.3f%%, Accuracy = %.3f%%, PosAcc = %.3f%%, NegAcc = %.3f%%\n', ...
         mdlres.PRAUC, mdlres.ROCAUC, mdlres.Accuracy, mdlres.PosAcc, mdlres.NegAcc);

end

