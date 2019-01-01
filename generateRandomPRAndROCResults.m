function [pmRandomRes] = generateRandomPRAndROCResults(labels, nday)

% generateRandomPRAndROCResults - generate random PR and ROC results for
% plotting

trcvlabels = labels(:,nday);
ntrcvexamples = size(trcvlabels,1);

pmRandomRes = struct('Pred'     , zeros(ntrcvexamples,1), ...
                     'PredSort' , zeros(ntrcvexamples,1), 'LabelSort', zeros(ntrcvexamples,1), ...
                     'Precision', zeros(ntrcvexamples,1), 'Recall'   , zeros(ntrcvexamples,1), ...
                     'TPR'      , zeros(ntrcvexamples,1), 'FPR'      , zeros(ntrcvexamples,1), ...
                     'PRAUC'    , 0.0                   , 'ROCAUC'   , 0.0, ...
                     'Accuracy' , 0.0);
                 
pmRandomRes.Pred = rand(ntrcvexamples, 1);


                 
end

