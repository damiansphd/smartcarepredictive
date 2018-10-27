function [pmInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures)

% createPMInterpNormcube - creates the normalised data cube

pmInterpNormcube = nan(npatients, maxdays, nmeasures);

for m = 1:nmeasures
    pmInterpNormcube(:,:,m) = (pmInterpDatacube(:,:,m) - pmOverallStats.Mean(m)) / (pmOverallStats.StdDev(m));
end

end

