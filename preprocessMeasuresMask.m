function [measures, nmeasures, pmOverallStats, pmPatientMeasStats, ...
    pmRawDatacube, pmInterpDatacube] = preprocessMeasuresMask(measures, nmeasures, ...
    pmOverallStats, pmPatientMeasStats, pmRawDatacube, pmInterpDatacube, featureparamsrow)

% preprocessMeasuresMask - remove data for measurements that are not in the
% selected measuresmeask for the run.

% measuresmask          Action
%       1               all measures included
%       2               Cough only
%       3               Cough and Wellness
%       4               All except Temperature

measuresmask = featureparamsrow.measuresmask;
bucketmask   = featureparamsrow.bucketfeat;
rangemask    = featureparamsrow.minmaxfeat;
volmask      = featureparamsrow.volfeat;

fprintf('Pre-processing for measures mask\n');
if measuresmask == 1
    fprintf('Keeping all measures\n');
    return;
elseif measuresmask == 2
    mkeepidx = find(ismember(measures.DisplayName, 'Cough'));
elseif measuresmask == 3
    mkeepidx = find(ismember(measures.DisplayName,{'Cough','Wellness'}));
elseif measuresmask -- 4
    mkeepidx = find(~ismember(measures.DisplayName,{'Temperature'}));
end

mdelidx = 1:nmeasures;
mdelidx(mkeepidx) = [];

fprintf('Deleting measures :-\n');
for m = 1:size(mdelidx, 2)
    fprintf('%d %s\n', mdelidx(m), measures.DisplayName{mdelidx(m)});
end
measures(mdelidx, :) = [];
nmeasures = size(measures, 1);
pmOverallStats(mdelidx, :) = [];
pmPatientMeasStats(ismember(pmPatientMeasStats.MeasureIndex, mdelidx),:) = [];
pmRawDatacube(:,:,mdelidx) = [];
pmInterpDatacube(:,:,mdelidx) = [];

fprintf('Setting bucket mask\n');
if bucketmask == 1
    fprintf('Set to use raw data for all measures\n');
    measures.Bucket(:) = 0;
elseif bucketmask == 2
    fprintf('Set to use bucketed features for all measures\n');
    measures.Bucket(:) = 1;
elseif bucketmask == 3
    fprintf('Set to use bucketed features for LungFunction, O2Saturation, and PulseRate\n');
    bkeepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    measures.Bucket(:) = 0;
    measures.Bucket(bkeepidx) = 1;
end

fprintf('Setting range mask\n');
if rangemask == 1
    fprintf('Not adding any range features\n');
    measures.Range(:) = 0;
elseif bucketmask == 2
    fprintf('Adding range features for all measures\n');
    measures.Range(:) = 1;
elseif bucketmask == 3
    fprintf('Adding range features for LungFunction, O2Saturation, and PulseRate\n');
    rkeepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    measures.Range(:) = 0;
    measures.Range(rkeepidx) = 1;
end

fprintf('Setting volatility mask\n');
if volmask == 1
    fprintf('Not adding any volatility features\n');
    measures.Volatility(:) = 0;
elseif volmask == 2
    fprintf('Adding volatility features for all measures\n');
    measures.Volatility(:) = 1;
elseif volmask == 3
    fprintf('Adding volatility features for LungFunction, O2Saturation, and PulseRate\n');
    vkeepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    measures.Volatility(:) = 0;
    measures.Volatility(vkeepidx) = 1;
end

end

