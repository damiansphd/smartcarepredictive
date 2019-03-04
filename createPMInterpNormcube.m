function [pmInterpNormcube, pmSmoothInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, ...
    pmMuNormcube, pmSigmaNormcube, pmPatients, npatients, maxdays, measures, nmeasures, ...
    smfunction, smwindow, smlength)

% createPMInterpNormcube - creates the normalised data cube

pmInterpNormcube = nan(npatients, maxdays, nmeasures);
pmSmoothInterpNormcube = nan(npatients, maxdays, nmeasures);

pmInterpNormcube = (pmInterpDatacube - pmMuNormcube) ./ pmSigmaNormcube;

mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

if smfunction > 0
    fprintf('Smoothing normalised cube - Function %d, Window %d, Length %d\n', smfunction, smwindow, smlength);
    
    for p = 1:npatients
        pmaxdays = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
        for m = 1:nmeasures
            pmSmoothInterpNormcube(p,1:pmaxdays,m) = applySmoothMethodToInterpRow(pmInterpNormcube(p,1:pmaxdays,m), smfunction, smwindow, smlength, m, mfev1idx);
        end
    end
end


end

