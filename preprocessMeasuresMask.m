function [measures, nmeasures, pmOverallStats, pmPatientMeasStats, ...
    pmRawDatacube, pmInterpDatacube] = preprocessMeasuresMask(measures, nmeasures, ...
    pmOverallStats, pmPatientMeasStats, pmRawDatacube, pmInterpDatacube, measuresmask)

% preprocessMeasuresMask - remove data for measurements that are not in the
% selected measuresmeask for the run.

% measuresmask          action
%       1               all measures included
%       2               Cough only

fprintf('Pre-processing for measures mask\n');
fprintf('--------------------------------\n');
if measuresmask == 1
    fprintf('Keeping all measures\n');
    return;
elseif measuresmask == 2
    mkeepidx = find(ismember(measures.DisplayName, 'Cough'));
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

end

