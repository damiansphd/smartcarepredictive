function [pmNormDataWinArray, pmMuIndex, pmSigmaIndex, pmPMeanWinArray] = createNormDataWinArray(pmDataWinArray, ...
            pmOverallStats, nexamples, measures, nmeasures, totalwin, normwin, study)

% createNormDataWinArray - creates the normalised data window array

[~, pmNormDataWinArray, ~] = createDataWindowArrays(nexamples, nmeasures, totalwin); 
pmMuIndex  = zeros(nexamples, nmeasures);
pmSigmaIndex = repmat(pmOverallStats.StdDev', nexamples, 1);
pmPMeanWinArray = zeros(nexamples, nmeasures);
ndefaultexamples = 0;

% for project breathe, exclude certain measures from normalisation
exnormmeas   = getExNormMeasures(study);
midx = ismember(measures.DisplayName, exnormmeas);

for i = 1:nexamples
    for m = 1:nmeasures
        % don't normalise the binary features in Project Breathe
        if ismember(study, {'BR'}) && midx(m)
            pmMuIndex(i, m) = 0;
            pmNormDataWinArray(i, :, m) = pmDataWinArray(i, :, m);
        else
            if measures.Factor(m) == 1
                sortorder = 'ascend';
            else
                sortorder =  'descend';
            end
            mnormwinrow     = pmDataWinArray(i, 1:normwin, m);
            mnormwinrow     = sort(mnormwinrow(~isnan(mnormwinrow)), sortorder);
            if size(mnormwinrow, 2) >= 3
                percentile25    = round(size(mnormwinrow, 2) * .25) + 1;
                pmMuIndex(i, m) = mean(mnormwinrow(percentile25:end));
            else
                %fprintf('Using Patient study mean for patient %d, measure %d (%s), day %d\n', p, m, measures.DisplayName{m}, d);
                ndefaultexamples = ndefaultexamples + 1;
                pmMuIndex(i, m) = pmOverallStats.Mean(m);
            end
            pmNormDataWinArray(i, :, m) = (pmDataWinArray(i, :, m) - pmMuIndex(i, m)) / pmSigmaIndex(i, m);
        end
    end
end

fprintf('Used Patient study mean for %d/%d days/measures\n', ndefaultexamples, nexamples * nmeasures);

munorm     = zeros(nmeasures, 2);

for m = 1:nmeasures
    if ismember(study, {'BR'}) && midx(m)
        pmPMeanWinArray(:, m) = pmMuIndex(:, m);
    else
        munorm(m, 1) = mean(pmMuIndex(:,m));
        munorm(m, 2) = std(pmMuIndex(:,m));
        pmPMeanWinArray(:, m) = (pmMuIndex(:, m) - munorm(m, 1)) / munorm(m, 2);
    end
end

end

