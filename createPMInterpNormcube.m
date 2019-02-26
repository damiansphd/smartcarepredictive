function [pmInterpNormcube, pmSmoothInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, pmPatients, pmOverallStats, ...
    pmPatientMeasStats, npatients, maxdays, measures, nmeasures, normmethod, smfunction, smwindow, smlength)

% createPMInterpNormcube - creates the normalised data cube

pmInterpNormcube = nan(npatients, maxdays, nmeasures);
pmSmoothInterpNormcube = nan(npatients, maxdays, nmeasures);

for m = 1:nmeasures
    if normmethod == 1
        % use overall study level mean/std (by measure)
        pmInterpNormcube(:,:,m) = (pmInterpDatacube(:,:,m) - pmOverallStats.Mean(m)) / (pmOverallStats.StdDev(m));
    elseif normmethod == 2
        % use patient level mean/std (by measure)
        for p = 1:npatients
            pmeas = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m, :);
            if size(pmeas,1) == 0 || pmeas.StdDev == 0
                fprintf('Using Overall study mean and std for patient %d, measure %d\n', p, m);
                pmean = pmOverallStats.Mean(m);
                pstd = pmOverallStats.StdDev(m);
            else
                pmean = pmeas.Mean;
                pstd  = pmeas.StdDev;
            end
            pmInterpNormcube(p,:,m) = (pmInterpDatacube(p,:,m) - pmean) / pstd;
        end
    else
        fprintf('Unknown normalisation method\n');
    end
end

mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

if smfunction > 0
    fprintf('Smoothing normalised cube - Function %d, Window %d, Length %d\n', smfunction, smwindow, smlength);
    
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            %pmSmoothInterpNormcube(p,1:pmaxdays,m) = smooth(pmInterpNormcube(p,1:pmaxdays,m),5);
            pmSmoothInterpNormcube(p,1:pmaxdays,m) = applySmoothMethodToInterpRow(pmInterpNormcube(p,1:pmaxdays,m), smfunction, smwindow, smlength, m, mfev1idx);
        end
    end
end


end

