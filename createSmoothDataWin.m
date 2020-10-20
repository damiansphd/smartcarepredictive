function datawinarray = createSmoothDataWin(datawinarray, measures, nmeasures, nexamples, smfunction, ...
                            smwindow, smlength)

% createSmoothDataWin - applies smoothing to data window array (only to be used after
% interpolation)

mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

if smfunction > 0
    fprintf('Smoothing data cube - Function %d, Window %d, Length %d\n', smfunction, smwindow, smlength);
    
    for i = 1:nexamples
        for m = 1:nmeasures
            mfeatsrow = datawinarray(i, :, m);
            mfeatsrow = applySmoothMethodToInterpRow(mfeatsrow, smfunction, smwindow, smlength, m, mfev1idx);
            datawinarray(i, :, m) = mfeatsrow;
        end
    end
end

end

