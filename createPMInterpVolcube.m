function [pmInterpVolcube, mvolstats, pmInterpSegVolcube] = createPMInterpVolcube(pmPatients, pmInterpNormcube, ...
    npatients, maxdays, nmeasures, featureduration, nsegments, normwindow)

% createPMInterpVolcube - creates volatility measures cube

navgsize = floor(featureduration/nsegments);
mvolstats = zeros(nmeasures, 6);
pmInterpVolcube    = nan(npatients, maxdays, nmeasures);
pmInterpSegVolcube = nan(npatients, maxdays, nmeasures, nsegments);

for p = 1:npatients
    pduration = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
    for m = 1:nmeasures
        for d = normwindow + 2:pduration
            pmInterpVolcube(p, d, m) = abs(pmInterpNormcube(p, d, m) - pmInterpNormcube(p, (d-1), m));
            %pmInterpVolcube(p, d, m) = sum(abs(diff(pmInterpNormcube(p, (d - featureduration + 1):d, m)))) / (featureduration - 1);
            if d >= featureduration
                for i = 1:nsegments
                    pmInterpSegVolcube(p, d, m, i) = sum(abs(diff(pmInterpNormcube(p, (d - (i * navgsize) + 1):(d - ((i - 1) * navgsize)), m)))) / (navgsize - 1);
                end
            end
        end
    end
end

mvolstats(:,1) = min(reshape(pmInterpVolcube(:, :, :), [npatients * maxdays, nmeasures]));
mvolstats(:,2) = max(reshape(pmInterpVolcube(:, :, :), [npatients * maxdays, nmeasures]));
mvolstats(:,3) = mean(reshape(pmInterpVolcube(:, :, :), [npatients * maxdays, nmeasures]), 'omitnan');
mvolstats(:,4) = std(reshape(pmInterpVolcube(:, :, :), [npatients * maxdays, nmeasures]), 'omitnan');

test = reshape(pmInterpVolcube(:, :, :), [npatients * maxdays, nmeasures]);
for m = 1:nmeasures
    test2 = sort(test(~isnan(test(:,m)), m), 'ascend');
    pct99 = round(size(test2,1) * 0.99);
    pct999 = round(size(test2,1) * 0.999);
    mvolstats(m,5) = test2(pct99);
    mvolstats(m,6) = test2(pct999);
end

end

