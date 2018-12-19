function [pmInterpVolcube, mvolstats] = createPMInterpVolcube(pmPatients, pmInterpNormcube, ...
    npatients, maxdays, nmeasures)

% createPMInterpVolcube - creates volatility measures cube

pmInterpVolcube = nan(npatients, maxdays, nmeasures);
mvolstats = zeros(nmeasures, 6);

for p = 1:npatients
    pduration = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
    for m = 1:nmeasures
        for d = 2:pduration
            pmInterpVolcube(p, d, m) = abs(pmInterpNormcube(p, d, m) - pmInterpNormcube(p, (d-1), m));
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

