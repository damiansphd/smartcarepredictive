function [pmInterpSmoothcube] = createPMInterpSmoothcube(pmInterpcube, pmPatients, npatients, ...
    maxdays, measures, nmeasures, smfunction, smwindow, smlength)

% createPMInterpSmoothcube - creates the smoothed data cube

pmInterpSmoothcube = nan(npatients, maxdays, nmeasures);

mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

if smfunction > 0
    fprintf('Smoothing data cube - Function %d, Window %d, Length %d\n', smfunction, smwindow, smlength);
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            pmInterpSmoothcube(p,1:pmaxdays,m) = applySmoothMethodToInterpRow(pmInterpcube(p,1:pmaxdays,m), smfunction, smwindow, smlength, measures.Index(m), mfev1idx);
        end
    end
end


end

