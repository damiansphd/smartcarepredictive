function [pmInterpRangecube] = createPMInterpRangecube(pmPatients, pmInterpNormcube, ...
    npatients, maxdays, nmeasures, featureduration)

% createPMInterpRangecube - creates measures range cube

pmInterpRangecube = nan(npatients, maxdays, nmeasures);

for p = 1:npatients
    pduration = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
    for m = 1:nmeasures
        for d = featureduration:pduration
            pmInterpRangecube(p, d, m) =   max(pmInterpNormcube(p, (d - featureduration + 1): d, m)) ...
                                         - min(pmInterpNormcube(p, (d - featureduration + 1): d, m));
        end
    end
end

end

