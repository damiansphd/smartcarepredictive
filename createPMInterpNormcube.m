function [pmInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, pmOverallStats, ...
    pmPatientMeasStats, npatients, maxdays, nmeasures, normmethod)

% createPMInterpNormcube - creates the normalised data cube

pmInterpNormcube = nan(npatients, maxdays, nmeasures);

for m = 1:nmeasures
    if normmethod == 1
        % use overall study level mean/std (by measure)
        pmInterpNormcube(:,:,m) = (pmInterpDatacube(:,:,m) - pmOverallStats.Mean(m)) / (pmOverallStats.StdDev(m));
    elseif normmethod == 2
        % use patient level mean/std (by measure)
        for p = 1:npatients
            pmeas = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m, :);
            if size(pmeas,1) == 0
                fprintf('Using Overall study mean and std for patient %d, measure %d\n', p, m);
                pmean = pmOverallStats.Mean(m);
                pstd = pmOverallStats.StdDev(m);
            else
                pmean = pmPatientMeasStats.Mean(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m);
                pstd  = pmPatientMeasStats.StdDev(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m);
            end
            pmInterpNormcube(p,:,m) = (pmInterpDatacube(p,:,m) - pmean) / pstd;
        end
    else
        fprintf('Unknown normalisation method\n');
    end
end

end

