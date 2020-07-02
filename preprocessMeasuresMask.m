function [measures] = preprocessMeasuresMask(measures, nmeasures, featureparamsrow)

% preprocessMeasuresMask - set the various masks for different types of
% measure feature

masks = [featureparamsrow.rawmeasfeat;
         featureparamsrow.msfeat;
         featureparamsrow.bucketfeat ;
         featureparamsrow.rangefeat  ;
         featureparamsrow.volfeat    ;
         featureparamsrow.avgsegfeat ;
         featureparamsrow.volsegfeat ;
         featureparamsrow.cchangefeat;
         featureparamsrow.pmeanfeat;
         featureparamsrow.pstdfeat;
         featureparamsrow.buckpmean;
         featureparamsrow.buckpstd];
     
colnames = {'RawMeas'; 'MSMeas'; 'BucketMeas'; 'Range'; 'Volatility'; 'AvgSeg'; 'VolSeg'; 'CChange'; 'PMean'; 'PStd'; 'BuckPMean'; 'BuckPStd'};

for a = 1:size(masks,1)
    fprintf('Setting %s mask : ', colnames{a});
    [keepidx] = convertMeasureCombToMask(masks(a), measures, nmeasures);
    mask = zeros(nmeasures,1);
    mask(keepidx) = 1;
    measures(:, colnames(a)) = array2table(mask);
end

% If both raw and bucketed features are set for a given measure, update to
% have only bucketed to avoid duplicative features

for m = 1:nmeasures
    if measures.RawMeas(m) && measures.BucketMeas(m)
        fprintf('Both raw and bucketed features selected for %s - keep only bucketed\n', measures.DisplayName{m});
        measures.RawMeas(m) = 0;
    end
    if measures.PMean(m) && measures.BuckPMean(m)
        fprintf('Both raw and bucketed patient mean selected for %s - keep only bucketed\n', measures.DisplayName{m});
        measures.PMean(m) = 0;
    end
    if measures.PStd(m) && measures.BuckPStd(m)
        fprintf('Both raw and bucketed patient std selected for %s - keep only bucketed\n', measures.DisplayName{m});
        measures.PStd(m) = 0;
    end
end

end

