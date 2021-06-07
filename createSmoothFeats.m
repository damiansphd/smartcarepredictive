function features = createSmoothFeats(features, measures, nmeasures, nexamples, nmfeats, smfunction, ...
                            smwindow, smlength)

% createSmoothFeats - applies smoothing to raw meas features (only to be used after
% interpolation)

mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

if smfunction > 0
    fprintf('Smoothing data cube - Function %d, Window %d, Length %d\n', smfunction, smwindow, smlength);
    
    for i = 1:nexamples
        for m = 1:nmeasures
            mfeatsrow = features(i, ((m-1) * nmfeats) + 1: (m * nmfeats));
            mfeatsrow = applySmoothMethodToInterpRow(mfeatsrow, smfunction, smwindow, smlength, measures.Index(m), mfev1idx);
            features(i, ((m-1) * nmfeats) + 1: (m * nmfeats)) = mfeatsrow;
        end
    end
end

end

