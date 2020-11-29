function [mdlres] = calcQCModelQualityScores(mdlres, labels, fplabels, nexamples)

% calcQCModelQualityScores - calculates the various quality metrics for a
% given model run.

TPCost  = 0;
TNCost  = 0;
FP1Cost = 0;
FP2Cost = 10;
FNCost  = 1;

[mdlres.PredSort, sortidx] = sort(mdlres.Pred, 'descend');
mdlres.LabelSort   = labels(sortidx);
mdlres.FPLabelSort = fplabels(sortidx);

for a = 1:nexamples
    TP  = sum(mdlres.LabelSort(1:a) == 1);
    FP  = sum(mdlres.LabelSort(1:a) == 0);
    FP2 = sum(mdlres.FPLabelSort(1:a) == 0);
    FP1 = FP - FP2;
    TN  = sum(mdlres.LabelSort(a+1:nexamples) == 0);
    FN  = sum(mdlres.LabelSort(a+1:nexamples) == 1);
    
    mdlres.TP(a)  = TP;
    mdlres.FP(a)  = FP;
    mdlres.FP1(a) = FP1;
    mdlres.FP2(a) = FP2;
    mdlres.TN(a)  = TN;
    mdlres.FN(a)  = FN;
    
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
    
    mdlres.QCCostArray(a) = ((TPCost * TP) + (TNCost * TN) + (FP1Cost * FP1) + (FP2Cost * FP2) + (FNCost * FN)) / nexamples; 
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

mdlres.QCCostOp    = min(mdlres.QCCostArray);
mdlres.IdxOp       = find(mdlres.QCCostArray == mdlres.QCCostOp, 1, 'first');
mdlres.PredOp      = mdlres.PredSort(mdlres.IdxOp);
mdlres.TPROp       = 100 * mdlres.TPR(mdlres.IdxOp);
mdlres.FPROp       = 100 * mdlres.FPR(mdlres.IdxOp);
mdlres.PrecisionOp = 100 * mdlres.Precision(mdlres.IdxOp);
mdlres.RecallOp    = 100 * mdlres.Recall(mdlres.IdxOp);

end

