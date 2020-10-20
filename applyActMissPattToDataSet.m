function [normfeatures, mpidxrow, mparrayrow] = applyActMissPattToDataSet(normfeatures, muindex, sigmaindex, pmOverallStats, ...
    mpidxrow, pmMSNormFeats, msex, nrawfeatures, featureduration, outrangeconst, interpmethod, missinterp)
    
% applyActMissPattToDataSet - choose an actual missingness pattern at random and apply
% to whole interpolated dataset

mpidxrow.ScenType = 4;
mpidxrow.Scenario{1} = 'Actual';
mpidxrow.MSExample = msex;

mparrayrow = pmMSNormFeats(msex, (nrawfeatures + 1):(nrawfeatures * 2));

% apply to interpolated raw features and missingness features
nexamples = size(normfeatures, 1);
mpmask = repmat(mparrayrow, nexamples, 1);

rawfeatures = normfeatures(:, 1:nrawfeatures);

if interpmethod == 0
    rawfeatures(logical(mpmask)) = outrangeconst;
    msfeatures = rawfeatures == outrangeconst;
elseif interpmethod == 1
    rawfeatures(logical(mpmask)) = nan;
    % add logic to (approximately) reinterpolate here
    nmeasures = nrawfeatures / featureduration;
    for m = 1:nmeasures
        mrawfeats = rawfeatures(:, ((m-1) * featureduration) + 1: (m * featureduration));
        %mmparrayrow = mparrayrow(((m-1) * featureduration) + 1: (m * featureduration));
        % interpolate first (requires at least 2 values per measure)
        actx = find(~isnan(mrawfeats(1,:)))';
        if size(actx, 1) >= 2
            acty = mrawfeats(:, ~isnan(mrawfeats(1,:)))';
            fullx = (1:featureduration)';
            fully = interp1(actx, acty, fullx, 'linear');
            rawfeatures(:, ((m-1) * featureduration) + 1: (m * featureduration)) = fully';
        end
        % then extrapolate missing edge values
        mrawfeats = rawfeatures(:, ((m-1) * featureduration) + 1: (m * featureduration));
        actx = find(~isnan(mrawfeats(1, :)))';
        if size(actx, 1) < featureduration
            fprintf('Missing extremity value found\n');
            if size(actx, 1) >= 2
                acty = mrawfeats(:, ~isnan(mrawfeats(1,:)))';
                fullx = (1:featureduration)';
                fully = interp1(actx, acty, fullx, 'nearest', 'extrap');
                rawfeatures(:, ((m-1) * featureduration) + 1: (m * featureduration)) = fully';
            else
                % not enough data points to extrapolate
                fprintf('Default value used\n');
                for i = 1:nexamples
                    mrawfeats(i, isnan(mrawfeats(i, :))) = (pmOverallStats.Mean(m) - muindex(i, m)) / sigmaindex(i, m);
                    rawfeatures(i, ((m-1) * featureduration) + 1: (m * featureduration)) = mrawfeats(i, :);
                end
                %mrawfeats(:, isnan(mrawfeats(1,:))) = outrangeconst;
                %rawfeatures(:, ((m-1) * featureduration) + 1: (m * featureduration)) = mrawfeats;
            end
        end
    end
    
    if missinterp == 1
        % calculate missingness features after interpolation applied
        % i.e. all missingness features are zero because full interpolation
        msfeatures = zeros(size(rawfeatures, 1), size(rawfeatures, 2));
    elseif missinterp == 2
        % calculate missingness features before interpolation applied
        % OR with previous missingness features
        msfeatures = normfeatures(:, (nrawfeatures + 1):(nrawfeatures * 2)) | mpmask;
    end
else
    fprintf('Interp method %d not allowed - only 0.No and 1.Full interpolation methods allowed\n', interpmethod);
    return
end

normfeatures = [rawfeatures, msfeatures];

end

