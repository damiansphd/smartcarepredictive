function [measures, nmeasures, pmOverallStats, pmPatientMeasStats, ...
    pmRawDatacube, pmInterpDatacube] = preprocessMeasuresMask(measures, nmeasures, ...
    pmOverallStats, pmPatientMeasStats, pmRawDatacube, pmInterpDatacube, featureparamsrow)

% preprocessMeasuresMask - remove data for measurements that are not in the
% selected measuresmeask for the run.

rawmeasmask  = featureparamsrow.rawmeasfeat;
bucketmask   = featureparamsrow.bucketfeat;
rangemask    = featureparamsrow.rangefeat;
volmask      = featureparamsrow.volfeat;

fprintf('Setting raw measures mask\n');
if rawmeasmask == 1
    fprintf('Set to use raw features for no measures\n');
    measures.RawMeas(:) = 0;
elseif rawmeasmask == 2
    fprintf('Set to use raw features for all measures\n');
    measures.RawMeas(:) = 1;
elseif rawmeasmask == 3
    fprintf('Set to use raw features for LungFunction, O2Saturation, and PulseRate\n');
    mkeepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    measures.RawMeas(:) = 0;
    measures.RawMeas(mkeepidx) = 1;
elseif rawmeasmask == 4
    fprintf('Set to use raw features for Cough and Wellness\n');
    mkeepidx = ismember(measures.DisplayName,{'Cough','Wellness'});
    measures.RawMeas(:) = 0;
    measures.RawMeas(mkeepidx) = 1;
end

fprintf('Setting bucketed measures mask\n');
if bucketmask == 1
    fprintf('Set to use bucketed features for no measures\n');
    measures.BucketMeas(:) = 0;
elseif bucketmask == 2
    fprintf('Set to use bucketed features for all measures\n');
    measures.BucketMeas(:) = 1;
elseif bucketmask == 3
    fprintf('Set to use bucketed features for LungFunction, O2Saturation, and PulseRate\n');
    bkeepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    measures.BucketMeas(:) = 0;
    measures.BucketMeas(bkeepidx) = 1;
elseif bucketmask == 4
    fprintf('Set to use bucketed features for Cough and Wellness\n');
    bkeepidx = ismember(measures.DisplayName,{'Cough','Wellness'});
    measures.BucketMeas(:) = 0;
    measures.BucketMeas(bkeepidx) = 1;
end

fprintf('Setting range mask\n');
if rangemask == 1
    fprintf('Not adding any range features\n');
    measures.Range(:) = 0;
elseif rangemask == 2
    fprintf('Adding range features for all measures\n');
    measures.Range(:) = 1;
elseif rangemask == 3
    fprintf('Adding range features for LungFunction, O2Saturation, and PulseRate\n');
    rkeepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    measures.Range(:) = 0;
    measures.Range(rkeepidx) = 1;
elseif rangemask == 4
    fprintf('Adding volatility features for Cough and Wellness\n');
    rkeepidx = ismember(measures.DisplayName,{'Cough','Wellness'});
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
elseif volmask == 4
    fprintf('Adding volatility features for Cough and Wellness\n');
    vkeepidx = ismember(measures.DisplayName,{'Cough','Wellness'});
    measures.Volatility(:) = 0;
    measures.Volatility(vkeepidx) = 1;
end

% 1) need to add check to pick only one of raw or bucketed if both are on for
% a measure


% 2) need to comment out the deleting of measures that aren't used - going
% to keep all measures going forward - but check where nmeasures is used
% first
%fprintf('Pre-processing for measures mask\n');
%if rawmeasmask == 1
%    fprintf('Keeping all measures\n');
%    mkeepidx = (1:nmeasures)';
%elseif rawmeasmask == 2
%    fprintf('Keeping Cough\n');
%    mkeepidx = find(ismember(measures.DisplayName, 'Cough'));
%elseif rawmeasmask == 3
%    fprintf('Keeping Cough and Wellness\n');
%    mkeepidx = find(ismember(measures.DisplayName,{'Cough','Wellness'}));
%elseif rawmeasmask -- 4
%    fprintf('Keeping all except Temperature\n');
%    mkeepidx = find(~ismember(measures.DisplayName,{'Temperature'}));
%end
%
%mdelidx = 1:nmeasures;
%mdelidx(mkeepidx) = [];
%
%fprintf('Deleting measures :-\n');
%for m = 1:size(mdelidx, 2)
%    fprintf('%d %s\n', mdelidx(m), measures.DisplayName{mdelidx(m)});
%end
%measures(mdelidx, :) = [];
%nmeasures = size(measures, 1);
%pmOverallStats(mdelidx, :) = [];
%pmPatientMeasStats(ismember(pmPatientMeasStats.MeasureIndex, mdelidx),:) = [];
%pmRawDatacube(:,:,mdelidx) = [];
%pmInterpDatacube(:,:,mdelidx) = [];


end

