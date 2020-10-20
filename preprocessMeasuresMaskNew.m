function [measures] = preprocessMeasuresMaskNew(measures, nmeasures, featureparamsrow)

% preprocessMeasuresMaskNew - set the various masks for different types of
% measure feature

masks = [featureparamsrow.rawmeasfeat;
         featureparamsrow.msfeat;
         featureparamsrow.volfeat;
         featureparamsrow.pmeanfeat];
     
colnames = {'RawMeas'; 'MSMeas'; 'Volatility'; 'PMean'};

for a = 1:size(masks,1)
    fprintf('Setting %s mask : ', colnames{a});
    [keepidx] = convertMeasureCombToMask(masks(a), measures, nmeasures);
    mask = zeros(nmeasures,1);
    mask(keepidx) = 1;
    measures(:, colnames(a)) = array2table(mask);
end

measures(:, {'BucketMeas'; 'Range'; 'AvgSeg'; 'VolSeg'; 'CChange'; 'PStd'}) = [];

end

