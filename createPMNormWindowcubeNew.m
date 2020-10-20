function [pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube] = createPMNormWindowcubeNew(pmPatients, ...
                pmDatacube, pmOverallStats, normmethod, normwindow, ...
                npatients, maxdays, measures, nmeasures, study)

% createPMNormWindowcubeNew - creates the normalisation window cube (10 day
% upper quartile mean prior to feature window) - stripped down version for
% interpolation fix - only works with normmethod 4.

pmMucube            = NaN(npatients, maxdays, nmeasures);
pmSigmacube         = NaN(npatients, maxdays, nmeasures);
pmMuNormcube        = NaN(npatients, maxdays, nmeasures);
pmSigmaNormcube     = NaN(npatients, maxdays, nmeasures);
ndefaultexamples    = 0;
nexamples           = 0;

if normmethod == 4
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            
            % for normmethod 4, for mu, use mean of norm window prior to feature
            % window, excluding lowest quartile
            % if not enough data points, use overall study mean
            for d = (normwindow +1):pmaxdays
                nexamples = nexamples + 1;
                pmuwind = pmDatacube(p, (d - normwindow):(d - 1), m);
                if measures.Factor(m) == 1
                    pmuwind = sort(pmuwind(~isnan(pmuwind)), 'ascend');
                else
                    pmuwind = sort(pmuwind(~isnan(pmuwind)), 'descend');
                end
                if size(pmuwind,2) >= 3
                    percentile25 = round(size(pmuwind,2) * .25) + 1;
                    pmMucube(p, d, m) = mean(pmuwind(percentile25:end));
                else
                    %fprintf('Using Patient study mean for patient %d, measure %d (%s), day %d\n', p, m, measures.DisplayName{m}, d);
                    ndefaultexamples = ndefaultexamples + 1;
                    pmMucube(p, d, m) = pmOverallStats.Mean(m);
                end
            end
            
            % for normmethod 4, for sigma, use overall study std deviation
            pmSigmacube(p, 1:pmaxdays, m) = pmOverallStats.StdDev(m);
            
        end 
    end
else
    fprintf('Unsupported normalisation method %d\n', normmethod);
end

fprintf('Used Patient study mean for %d/%d days/measures\n', ndefaultexamples, nexamples);

% for project breathe, exclude certain measures from normalisation
exnormmeas   = getExNormMeasures(study);
midx = ismember(measures.DisplayName, exnormmeas);
if ismember(study, {'BR'})
    if normmethod == 4
        for p = 1:npatients
            pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
            pmMucube(p, (normwindow + 1):pmaxdays, midx) = 0;
            pmSigmacube(p, 1:pmaxdays, midx)             = 1;
        end
    else
        fprintf('Unsupported normalisation method %d\n', normmethod);
    end
end

    
% create normalised Mu and Sigma cubes (for use as features)
munorm     = zeros(nmeasures, 2);
sigmanorm  = zeros(nmeasures,2);
for m = 1:nmeasures
    if normmethod == 4
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

end

