function [pmInterpDatacube] = handleMissingFeatures(pmPatients, pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures)

% handleMissingFeatures - for any measures with no data points for a given
% patient, populate with the overall population mean for that measure

overallmean = pmOverallStats.Mean;

for p = 1:npatients
    for m = 1:nmeasures
        if sum(~isnan(pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m))) == 0
            pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m) = overallmean(m);
        end
    end
end

end

