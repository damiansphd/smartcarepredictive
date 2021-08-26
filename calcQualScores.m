function [precision, recall, tpr, fpr, prauc, rocauc] = calcQualScores(labelsort, predsort)

% calcQualScores - calculates FPR from a set of labels and predictions

nexamples = size(predsort, 1);
precision = zeros(nexamples, 1);
recall    = zeros(nexamples, 1);
tpr       = zeros(nexamples, 1);
fpr       = zeros(nexamples, 1);

if nexamples < 1000
    ptinterval = 1;
else
    ptinterval = floor(nexamples / 1000);
end

for a = 1:nexamples
    % now we have 10,000+ episodes, don't need to calculate for every point
    % - for now calculate every <ptinterval> points, and propogate values in between
    if (a == 1 || a == nexamples || (a / ptinterval) == round(a / ptinterval, 0))
        TP = sum(labelsort(1:a) == 1);
        FP = sum(labelsort(1:a) == 0);
        TN = sum(labelsort(a+1:nexamples) == 0);
        FN = sum(labelsort(a+1:nexamples) == 1);

        precision(a) = TP / (TP + FP);
        recall(a)    = TP / (TP + FN); 
        tpr(a)       = recall(a);
        fpr(a)       = FP / (FP + TN);
    else
        precision(a) = precision(a - 1);
        recall(a)    = recall(a - 1);
        tpr(a)       = tpr(a - 1);
        fpr(a)       = fpr(a - 1);
    end
end

prauc    = 100 * trapz(recall, precision);
rocauc   = 100 * trapz(fpr   , tpr);

end

