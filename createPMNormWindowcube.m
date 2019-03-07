function [pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
    muntilepoints, sigmantilepoints] = createPMNormWindowcube(pmPatients, pmInterpDatacube, ...
                    pmOverallStats, pmPatientMeasStats, normmethod, normwindow, nbuckpmeas, ...
                    npatients, maxdays, measures, nmeasures)

% createPMNormWindowcube - creates the normalisation window cube (10 day
% upper quartile mean prior to feature window) - for use with normalisation
% method 3

pmMuNormcube        = NaN(npatients, maxdays, nmeasures);
pmSigmaNormcube     = NaN(npatients, maxdays, nmeasures);
pmBuckMuNormcube    = zeros(npatients, maxdays, nmeasures, nbuckpmeas + 1);
pmBuckSigmaNormcube = zeros(npatients, maxdays, nmeasures, nbuckpmeas + 1);

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

muntilepoints = zeros(nmeasures, nbuckpmeas + 1);
for m = 1:nmeasures
    malldata = reshape(pmMuNormcube(:,:,m), [1, npatients * maxdays]);
    malldata = sort(malldata(~isnan(malldata)), 'ascend');    
    muntilepoints(m,1) = malldata(1);
    for n = 1:nbuckpmeas
        muntilepoints(m,n + 1) = malldata(ceil((size(malldata,2) * n)/nbuckpmeas));
    end
end

sigmantilepoints = zeros(nmeasures, nbuckpmeas + 1);
for m = 1:nmeasures
    malldata = reshape(pmSigmaNormcube(:,:,m), [1, npatients * maxdays]);
    malldata = sort(malldata(~isnan(malldata)), 'ascend');    
    sigmantilepoints(m,1) = malldata(1);
    for n = 1:nbuckpmeas
        sigmantilepoints(m,n + 1) = malldata(ceil((size(malldata,2) * n)/nbuckpmeas));
    end
end

for p = 1:npatients
    for m = 1:nmeasures
        for d = 1:maxdays
            if ~isnan(pmMuNormcube(p, d, m))
                mudatapoint = pmMuNormcube(p, d, m);
                mulowerq = find(muntilepoints(m,:) <= mudatapoint, 1, 'last');
                muupperq = find(muntilepoints(m,:) >= mudatapoint, 1);
                if mulowerq == muupperq
                    % datapoint is exactly on one of the ntile boundaries
                    pmBuckMuNormcube(p, d, m, mulowerq) = 1;
                elseif mulowerq > muupperq
                    % multiple ntile points have the same value
                    % assign full weight to lowest edge
                    pmBuckMuNormcube(p, d, m, muupperq) = 1;
                else
                    % regular case - datapoint is between two boundaries
                    pmBuckMuNormcube(p, d, m, mulowerq) = abs(muntilepoints(m, muupperq) - mudatapoint) / abs(muntilepoints(m, muupperq) - muntilepoints(m, mulowerq));
                    pmBuckMuNormcube(p, d, m, muupperq) = abs(muntilepoints(m, mulowerq) - mudatapoint) / abs(muntilepoints(m, muupperq) - muntilepoints(m, mulowerq));
                end
            end
            if ~isnan(pmSigmaNormcube(p, d, m))
                sigmadatapoint = pmSigmaNormcube(p, d, m);
                sigmalowerq = find(sigmantilepoints(m,:) <= sigmadatapoint, 1, 'last');
                sigmaupperq = find(sigmantilepoints(m,:) >= sigmadatapoint, 1);
                if sigmalowerq == sigmaupperq
                    % datapoint is exactly on one of the ntile boundaries
                    pmBuckSigmaNormcube(p, d, m, sigmalowerq) = 1;
                elseif sigmalowerq > sigmaupperq
                    % multiple ntile points have the same value
                    % assign full weight to lowest edge
                    pmBuckSigmaNormcube(p, d, m, sigmaupperq) = 1;
                else
                    % regular case - datapoint is between two boundaries
                    pmBuckSigmaNormcube(p, d, m, sigmalowerq) = abs(sigmantilepoints(m, sigmaupperq) - sigmadatapoint) / abs(sigmantilepoints(m, sigmaupperq) - sigmantilepoints(m, sigmalowerq));
                    pmBuckSigmaNormcube(p, d, m, sigmaupperq) = abs(sigmantilepoints(m, sigmalowerq) - sigmadatapoint) / abs(sigmantilepoints(m, sigmaupperq) - sigmantilepoints(m, sigmalowerq));
                end
            end
        end
    end
end

% remove last edge to avoid rank deficiency
pmBuckMuNormcube(:, :, :, nbuckpmeas + 1) = [];
pmBuckSigmaNormcube(:, :, :, nbuckpmeas + 1) = [];


end

