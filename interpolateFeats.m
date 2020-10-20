function features = interpolateFeats(features, pmMuIndex, pmSigmaIndex, pmOverallStats, nexamples, nmeasures, nmfeats)

% interpolateFeats - interpolate a set of features by measure using only
% the data in the feature window

nextrem  = 0;
ndefault = 0;

for i = 1:nexamples
    for m = 1:nmeasures
        mfeatsrow = features(i, ((m-1) * nmfeats) + 1: (m * nmfeats));

        % interpolate first (requires at least 2 values per measure)
        actx = find(~isnan(mfeatsrow));
        if size(actx, 2) >= 2
            acty = mfeatsrow(~isnan(mfeatsrow));
            fullx = (1:nmfeats);
            fully = interp1(actx, acty, fullx, 'linear');
            features(i, ((m-1) * nmfeats) + 1: (m * nmfeats)) = fully;
        end
        % then extrapolate missing edge values
        mfeatsrow = features(i, ((m-1) * nmfeats) + 1: (m * nmfeats));
        actx = find(~isnan(mfeatsrow));
        if size(actx, 2) < nmfeats
            %fprintf('Missing extremity value found\n');
            nextrem = nextrem + 1;
            if size(actx, 2) >= 2
                acty = mfeatsrow(~isnan(mfeatsrow));
                fullx = (1:nmfeats);
                fully = interp1(actx, acty, fullx, 'nearest', 'extrap');
                features(i, ((m-1) * nmfeats) + 1: (m * nmfeats)) = fully;
            else
                % not enough data points to extrapolate
                % use normalised overall study mean instead.
                ndefault = ndefault + 1;
                mfeatsrow(isnan(mfeatsrow)) = (pmOverallStats.Mean(m) - pmMuIndex(i, m)) / pmSigmaIndex(i, m);
                features(i, ((m-1) * nmfeats) + 1: (m * nmfeats)) = mfeatsrow;
            end
        end
    end
end

fprintf('Total number of examples/measures = %d, extrapolation cases = %d, default cases = %d\n', nexamples * nmeasures, nextrem, ndefault);

end

