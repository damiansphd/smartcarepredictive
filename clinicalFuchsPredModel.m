function [pred] = clinicalFuchsPredModel(muindex, sigmaindex, normfeatures, pred, measures, featureduration, coughthresh, lfuncthresh)

% clinicalFuchsPredModel - function to predict based on modified fuchs
% criteria (at least the two criteria we have home measurements for


if (sum(measures.BucketMeas) + sum(measures.Range) + sum(measures.Volatility) + ...
        sum(measures.AvgSeg) + sum(measures.VolSeg) + sum(measures.CChange) + ...
        sum(measures.PMean) + sum(measures.PStd) + sum(measures.BuckPMean) + ...
        sum(measures.BuckPStd) ~= 0) || ...
        (sum(measures.RawMeas(ismember(measures.DisplayName, {'Cough', 'LungFunction'}))) ~= 2)
    fprintf('**** Invalid features for the modified fuchs model ****\n');
    return
end

nexamples = size(normfeatures,1);
nrawmeas = sum(measures.RawMeas);
ntiles = 4;
navgsize = floor(featureduration/ntiles);
coughavg = zeros(ntiles, 1);
lfuncavg = zeros(ntiles, 1);

munorm       = duplicateMeasuresByFeatures(muindex(:, logical(measures.RawMeas')), featureduration, nrawmeas);
sigmanorm    = duplicateMeasuresByFeatures(sigmaindex(:, logical(measures.RawMeas')), featureduration, nrawmeas);
rawfeatures  = (normfeatures .* sigmanorm) + munorm;

for n = 1:nexamples
    featurerow = rawfeatures(n,:);
    m = 1; % cough
    for i = 1:ntiles
        idx = (m * featureduration) - ((i - 1) * navgsize);
        coughavg(i) = mean(featurerow((idx - navgsize + 1):idx));
    end
    m = 2; % lung function
    for i = 1:ntiles
        idx = (m * featureduration) - ((i - 1) * navgsize);
        lfuncavg(i) = mean(featurerow((idx - navgsize + 1):idx));
    end
    
    if ( (coughavg(1) < (1 - coughthresh) * coughavg(2))   || ...
         (coughavg(1) < (1 - coughthresh) * coughavg(3))   || ...
         (coughavg(1) < (1 - coughthresh) * coughavg(4)) ) && ...
       ( (lfuncavg(1) < (1 - lfuncthresh) * lfuncavg(2))   || ...
         (lfuncavg(1) < (1 - lfuncthresh) * lfuncavg(3))   || ...
         (lfuncavg(1) < (1 - lfuncthresh) * lfuncavg(4)) )
        pred(n) = 1;
    else
        pred(n) = 0;
    end
    
end

end

