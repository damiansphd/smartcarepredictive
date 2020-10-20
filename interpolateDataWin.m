function pmInterpNormDataWinArray = interpolateDataWin(pmNormDataWinArray, ...
            pmMuIndex, pmSigmaIndex, pmOverallStats, nexamples, totalwin, nmeasures)

% interpolateDataWin - interpolate the data window array by measure using only
% the data in the data window array

nextrem  = 0;
ndefault = 0;

pmInterpNormDataWinArray = pmNormDataWinArray;

for i = 1:nexamples
    for m = 1:nmeasures
        mdatawinrow = pmInterpNormDataWinArray(i, :, m);

        % interpolate first (requires at least 2 values per measure)
        actx = find(~isnan(mdatawinrow));
        if size(actx, 2) >= 2
            acty = mdatawinrow(~isnan(mdatawinrow));
            fullx = (1:totalwin);
            fully = interp1(actx, acty, fullx, 'linear');
            pmInterpNormDataWinArray(i, :, m) = fully;
        end
        % then extrapolate missing edge values
        mdatawinrow = pmInterpNormDataWinArray(i, :, m);
        actx = find(~isnan(mdatawinrow));
        if size(actx, 2) < totalwin
            %fprintf('Missing extremity value found\n');
            nextrem = nextrem + 1;
            if size(actx, 2) >= 2
                acty = mdatawinrow(~isnan(mdatawinrow));
                fullx = (1:totalwin);
                fully = interp1(actx, acty, fullx, 'nearest', 'extrap');
                pmInterpNormDataWinArray(i, :, m) = fully;
            else
                % not enough data points to extrapolate
                % use normalised overall study mean instead.
                ndefault = ndefault + 1;
                mdatawinrow(isnan(mdatawinrow)) = (pmOverallStats.Mean(m) - pmMuIndex(i, m)) / pmSigmaIndex(i, m);
                pmInterpNormDataWinArray(i, :, m) = mdatawinrow;
            end
        end
    end
end

fprintf('Total number of examples/measures = %d, extrapolation cases = %d, default cases = %d\n', nexamples * nmeasures, nextrem, ndefault);

end

