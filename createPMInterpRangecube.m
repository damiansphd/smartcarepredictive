function [pmInterpRangecube, pmInterpSegAvgcube] = createPMInterpRangecube(pmPatients, pmInterpcube, ...
    npatients, maxdays, nmeasures, featureduration, nsegments, normwindow)

% createPMInterpRangecube - creates measures range cube and segmented range
% cube

navgsize = floor(featureduration/nsegments);

pmInterpRangecube  = nan(npatients, maxdays, nmeasures);
pmInterpSegAvgcube = nan(npatients, maxdays, nmeasures, nsegments);

for p = 1:npatients
    pduration = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
    for m = 1:nmeasures
        for d = (featureduration + normwindow):pduration
            pmInterpRangecube(p, d, m) =   max(pmInterpcube(p, (d - featureduration + 1): d, m)) ...
                                         - min(pmInterpcube(p, (d - featureduration + 1): d, m));
            for i = 1:nsegments
                pmInterpSegAvgcube(p, d, m, i) = mean(pmInterpcube(p, (d - (i * navgsize) + 1):(d - ((i - 1) * navgsize)), m));
            end
        end
    end
end

end

