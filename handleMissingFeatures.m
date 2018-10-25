function [pmInterpDatacube] = handleMissingFeatures(pmPatients, pmRawDatacube, pmInterpDatacube, npatients, maxdays, nmeasures)

% handleMissingFeatures - for any measures with no data points for a given
% patient, populate with the patient mean

for p = 1:npatients
    for m = 1:nmeasures
        if sum(~isnan(pmInterpDatacube(p, 1:(pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1), m))) < 2
            pmsum = sum(pmRawDatacube(:, ~isnan(pmRawDatacube(:, :, m)), m));
            
        end
    end
end

end

