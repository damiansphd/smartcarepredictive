function [pmMuNormcube, pmSigmaNormcube] = createPMNormWindowcube(pmPatients, pmInterpDatacube, ...
    pmOverallStats, pmPatientMeasStats, normmethod, normwindow, ...
    npatients, maxdays, measures, nmeasures)

% createPMNormWindowcube - creates the normalisation window cube (10 day
% upper quartile mean prior to feature window) - for use with normalisation
% method 3

pmMuNormcube = NaN(npatients, maxdays, nmeasures);
pmSigmaNormcube = NaN(npatients, maxdays, nmeasures);

if normmethod == 1
    for m = 1:nmeasures
        pmMuNormcube(:, :, m)    = pmOverallStats.Mean(m);
        pmSigmaNormcube(:, :, m) = pmOverallStats.StdDev(m);
    end
elseif normmethod == 2
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            pmeas = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m, :);
            if size(pmeas,1) == 0 || pmeas.StdDev == 0
                fprintf('Using Overall study mean and std for patient %d, measure %d (%s)\n', p, m, measures.DisplayName{m});
                pmean = pmOverallStats.Mean(m);
                pstd = pmOverallStats.StdDev(m);
            else
                pmean = pmeas.Mean;
                pstd  = pmeas.StdDev;
            end
            pmMuNormcube(p, 1:pmaxdays, m)    = pmean;
            pmSigmaNormcube(p, 1:pmaxdays, m) = pstd;
        end
    end
elseif normmethod == 3
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            pmeas = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m, :);
            if size(pmeas,1) == 0 || pmeas.StdDev == 0
                fprintf('Using Overall study std for patient %d, measure %d (%s)\n', p, m, measures.DisplayName{m});
                pmean = pmOverallStats.Mean(m);
                pstd = pmOverallStats.StdDev(m);
            else
                pmean = pmeas.Mean;
                pstd  = pmeas.StdDev;
            end
            pmSigmaNormcube(p, 1:pmaxdays, m) = pstd;
            for d = (normwindow + 1):pmaxdays
                pmuwind = pmInterpDatacube(p, (d - normwindow):(d - 1), m);
                if ~isequal(measures.DisplayName(m), cellstr('PulseRate'))
                    pmuwind = sort(pmuwind(~isnan(pmuwind)), 'ascend');
                else
                    pmuwind = sort(pmuwind(~isnan(pmuwind)), 'descend');
                end
                % now using interpolated cube, this check isn't really
                % necessary - but keeping it in for robustness
                if size(pmuwind,2) >= 3
                    percentile25 = round(size(pmuwind,2) * .25) + 1;
                    pmMuNormcube(p, d, m) = mean(pmuwind(percentile25:end));
                else
                    fprintf('Using Patient study mean for patient %d, measure %d (%s), day %d\n', p, m, measures.DisplayName{m}, d);
                    pmMuNormcube(p, d, m) = pmean;
                end
            end
        end
    end
else
    fprintf('Unknown normalisation method\n');
end

end

