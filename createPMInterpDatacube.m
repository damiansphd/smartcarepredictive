function [pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures)

% createPMInterpDatacube - interpolate the data to fill in missing data
% points

pmInterpDatacube = nan(npatients, maxdays, nmeasures);

for p = 1:npatients
    for m = 1:nmeasures
        if sum(~isnan(pmRawDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m))) >= 2
            actx = find(~isnan(pmRawDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m)));
            acty = pmRawDatacube(p, ~isnan(pmRawDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m)), m);
            fullx = (1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1));
            fully = interp1(actx, acty, fullx, 'linear', 'extrap');
            pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m) = fully;
        end
    end
end

end

