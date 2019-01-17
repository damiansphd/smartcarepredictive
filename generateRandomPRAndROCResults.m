function [pmRandomRes] = generateRandomPRAndROCResults(trcvlabels)

% generateRandomPRAndROCResults - generate random PR and ROC results for
% plotting

ntrcvexamples = size(trcvlabels,1);
ridx = randperm(ntrcvexamples);
trcvlabels = trcvlabels(ridx);

pmRandomRes = struct('Pred'     , zeros(ntrcvexamples,1), ...
                     'PredSort' , zeros(ntrcvexamples,1), 'LabelSort', zeros(ntrcvexamples,1), ...
                     'Precision', zeros(ntrcvexamples,1), 'Recall'   , zeros(ntrcvexamples,1), ...
                     'TPR'      , zeros(ntrcvexamples,1), 'FPR'      , zeros(ntrcvexamples,1), ...
                     'PRAUC'    , 0.0                   , 'ROCAUC'   , 0.0, ...
                     'Accuracy' , 0.0);
                 
pmRandomRes.Pred = rand(ntrcvexamples, 1);
[pmRandomRes.PredSort, sortidx] = sort(pmRandomRes.Pred, 'descend');
pmRandomRes.LabelSort = trcvlabels(sortidx);

for a = 1:ntrcvexamples
    TP = sum(pmRandomRes.LabelSort(1:a) == 1);
    FP = sum(pmRandomRes.LabelSort(1:a) == 0);
    TN = sum(pmRandomRes.LabelSort(a+1:ntrcvexamples) == 0);
    FN = sum(pmRandomRes.LabelSort(a+1:ntrcvexamples) == 1);
    pmRandomRes.Precision(a) = TP / (TP + FP);
    pmRandomRes.Recall(a)    = TP / (TP + FN); 
    pmRandomRes.TPR(a)       = pmRandomRes.Recall(a);
    pmRandomRes.FPR(a)       = FP / (FP + TN);
end
    
pmRandomRes.PRAUC  = 100 * trapz(pmRandomRes.Recall, pmRandomRes.Precision);
pmRandomRes.ROCAUC = 100 * trapz(pmRandomRes.FPR   , pmRandomRes.TPR);
pmRandomRes.Accuracy = sum(abs(pmRandomRes.PredSort - pmRandomRes.LabelSort))/ntrcvexamples;
fprintf('Random Baseline: PR AUC = %.2f, ROC AUC = %.2f, Accuracy = %.2f\n', pmRandomRes.PRAUC, pmRandomRes.ROCAUC, pmRandomRes.Accuracy);
fprintf('\n');
                
end

