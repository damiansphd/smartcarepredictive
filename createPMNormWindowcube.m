function [pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
    muntilepoints, sigmantilepoints] = createPMNormWindowcube(pmPatients, pmInterpcube, ...
                    pmOverallStats, pmPatientMeasStats, normmethod, normwindow, nbuckpmeas, ...
                    npatients, maxdays, measures, nmeasures, study)

% createPMNormWindowcube - creates the normalisation window cube (10 day
% upper quartile mean prior to feature window) - for use with normalisation
% method 3

pmMucube            = NaN(npatients, maxdays, nmeasures);
pmSigmacube         = NaN(npatients, maxdays, nmeasures);
pmMuNormcube        = NaN(npatients, maxdays, nmeasures);
pmSigmaNormcube     = NaN(npatients, maxdays, nmeasures);
pmBuckMuNormcube    = zeros(npatients, maxdays, nmeasures, nbuckpmeas + 1);
pmBuckSigmaNormcube = zeros(npatients, maxdays, nmeasures, nbuckpmeas + 1);

if normmethod == 1
    for m = 1:nmeasures
        pmMucube(:, :, m)    = pmOverallStats.Mean(m);
        pmSigmacube(:, :, m) = pmOverallStats.StdDev(m);
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
            pmMucube(p, 1:pmaxdays, m)    = pmean;
            pmSigmacube(p, 1:pmaxdays, m) = pstd;
        end
    end
elseif (normmethod == 3 || normmethod == 4)
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            if normmethod == 3
                pmeas = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p & pmPatientMeasStats.MeasureIndex == m, :);
                if size(pmeas,1) == 0 || pmeas.StdDev == 0
                    fprintf('Using Overall study std for patient %d, measure %d (%s)\n', p, m, measures.DisplayName{m});
                    pmean = pmOverallStats.Mean(m);
                    pstd = pmOverallStats.StdDev(m);
                else
                    pmean = pmeas.Mean;
                    pstd  = pmeas.StdDev;
                end
            elseif normmethod == 4
                pmean = pmOverallStats.Mean(m);
                pstd = pmOverallStats.StdDev(m);
            else
                fprintf('Should not get here !\n');
            end    
            pmSigmacube(p, 1:pmaxdays, m) = pstd;
            for d = (normwindow +1):pmaxdays
                pmuwind = pmInterpcube(p, (d - normwindow):(d - 1), m);
                % could change this to check if factor = -1 instead or use
                % getInvertedMeasures
                %if ~isequal(measures.DisplayName(m), cellstr('PulseRate'))
                if measures.Factor(m) == 1
                    pmuwind = sort(pmuwind(~isnan(pmuwind)), 'ascend');
                else
                    pmuwind = sort(pmuwind(~isnan(pmuwind)), 'descend');
                end
                % now using interpolated cube, this check isn't really
                % necessary - but keeping it in for robustness
                if size(pmuwind,2) >= 3
                    percentile25 = round(size(pmuwind,2) * .25) + 1;
                    pmMucube(p, d, m) = mean(pmuwind(percentile25:end));
                else
                    fprintf('Using Patient study mean for patient %d, measure %d (%s), day %d\n', p, m, measures.DisplayName{m}, d);
                    pmMucube(p, d, m) = pmean;
                end
            end
        end
    end
else
    fprintf('Unknown normalisation method\n');
end

% for project breathe, exclude certain measures from normalisation
exnormmeas   = getExNormMeasures(study);
midx = ismember(measures.DisplayName, exnormmeas);
if ismember(study, {'BR'})
    if normmethod == 1
        pmMucube(:, :, midx)    = 0;
        pmSigmacube(:, :, midx) = 1;
    elseif normmethod == 2
        for p = 1:npatients
            pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
            pmMucube(:, 1:pmaxdays, midx)     = 0;
            pmSigmacube(:, 1:pmaxdays, midx)  = 1;
        end
    elseif (normmethod == 3 || normmethod == 4)
        for p = 1:npatients
            pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
            pmMucube(p, (normwindow + 1):pmaxdays, midx) = 0;
            pmSigmacube(p, 1:pmaxdays, midx)             = 1;
        end
    else
        fprintf('Unknown normalisation method\n');   
    end
end

    
% create normalised Mu and Sigma cubes (for use as features)
munorm     = zeros(nmeasures, 2);
sigmanorm  = zeros(nmeasures,2);
for m = 1:nmeasures
    if normmethod == 1
        pmMuNormcube(:, :, m) = 0;
        pmSigmaNormcube(:, :, m) = 0;
    else
        meandata = reshape(pmMucube(:, :, m), [1 (npatients * maxdays)]);
        meandata = meandata(~isnan(meandata));
        stddata = reshape(pmSigmacube(:, :, m), [1 (npatients * maxdays)]);
        stddata = stddata(~isnan(stddata));
        munorm(m, 1)     = mean(meandata);
        munorm(m, 2)     = std(meandata);
        sigmanorm(m, 1)  = mean(stddata);
        sigmanorm(m, 2)  = std(stddata);
        if ismember(study, {'BR'}) && midx(m)
            pmMuNormcube(:, :, m)    = pmMucube(:, :, m);
            pmSigmaNormcube(:, :, m) = pmSigmacube(:, :, m);
        else
            pmMuNormcube(:, :, m)    = (pmMucube(:, :, m)    - munorm(m, 1))    ./ munorm(m, 2);
            pmSigmaNormcube(:, :, m) = (pmSigmacube(:, :, m) - sigmanorm(m, 1)) ./ sigmanorm(m, 2);
        end
    end
end

% create bucketed Mu and Sigma cubes
muntilepoints = zeros(nmeasures, nbuckpmeas + 1);
for m = 1:nmeasures
    malldata = reshape(pmMucube(:,:,m), [1, npatients * maxdays]);
    malldata = sort(malldata(~isnan(malldata)), 'ascend');    
    muntilepoints(m,1) = malldata(1);
    for n = 1:nbuckpmeas
        muntilepoints(m,n + 1) = malldata(ceil((size(malldata,2) * n)/nbuckpmeas));
    end
end

sigmantilepoints = zeros(nmeasures, nbuckpmeas + 1);
for m = 1:nmeasures
    malldata = reshape(pmSigmacube(:,:,m), [1, npatients * maxdays]);
    malldata = sort(malldata(~isnan(malldata)), 'ascend');    
    sigmantilepoints(m,1) = malldata(1);
    for n = 1:nbuckpmeas
        sigmantilepoints(m,n + 1) = malldata(ceil((size(malldata,2) * n)/nbuckpmeas));
    end
end

for p = 1:npatients
    for m = 1:nmeasures
        for d = 1:maxdays
            if ~isnan(pmMucube(p, d, m))
                mudatapoint = pmMucube(p, d, m);
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
            if ~isnan(pmSigmacube(p, d, m))
                sigmadatapoint = pmSigmacube(p, d, m);
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

