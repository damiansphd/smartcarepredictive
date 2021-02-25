function [precision, recall, tpr, fpr, prauc, rocauc] = calcQualScores(labelsort, predsort)

% calcQualScores - calculates FPR from a set of labels and predictions

nexamples = size(predsort, 1);
precision = zeros(nexamples, 1);
recall    = zeros(nexamples, 1);
tpr       = zeros(nexamples, 1);
fpr       = zeros(nexamples, 1);

for a = 1:nexamples
    TP = sum(labelsort(1:a) == 1);
    FP = sum(labelsort(1:a) == 0);
    TN = sum(labelsort(a+1:nexamples) == 0);
    FN = sum(labelsort(a+1:nexamples) == 1);
    
    precision(a) = TP / (TP + FP);
    recall(a)    = TP / (TP + FN); 
    tpr(a)       = recall(a);
    fpr(a)       = FP / (FP + TN);
end

prauc    = 100 * trapz(recall, precision);
rocauc   = 100 * trapz(fpr   , tpr);

end

