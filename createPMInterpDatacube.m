function [pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures)

% createPMInterpDatacube - fill in missing data points as follows :-
%   1) use linear interpolation for missing points within measurements
%   2) use nearest neighbour extrapolation for missing points at the
%   beginning and end

pmInterpDatacube = nan(npatients, maxdays, nmeasures);

for p = 1:npatients
    for m = 1:nmeasures
        if sum(~isnan(pmRawDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m))) >= 2
            actx = find(~isnan(pmRawDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m)));
            acty = pmRawDatacube(p, ~isnan(pmRawDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m)), m);
            fullx = (1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1));
            fully = interp1(actx, acty, fullx, 'linear');
            pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m) = fully;
            actx = find(~isnan(pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m)));
            acty = pmInterpDatacube(p, ~isnan(pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m)), m);
            fullx = (1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1));
            fully = interp1(actx, acty, fullx, 'nearest', 'extrap');
            pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m) = fully;
        end
    end
end

end

