function [normfeatures, mpidxrow, mparrayrow] = applyActMissPattToDataSet(normfeatures, ...
    mpidxrow, pmMSNormFeats, msex, nrawfeatures, outrangeconst)
    
% applyActMissPattToDataSet - choose an actual missingness pattern at random and apply
% to whole interpolated dataset

mpidxrow.ScenType = 4;
mpidxrow.Scenario{1} = 'Actual';
mpidxrow.MSExample = msex;

mparrayrow = pmMSNormFeats(msex, nrawfeatures + 1:end);

% apply to interpolated raw features and missingness features
nexamples = size(normfeatures, 1);
mpmask = repmat(mparrayrow, nexamples, 1);

rawfeatures = normfeatures(:, 1:nrawfeatures);
rawfeatures(logical(mpmask)) = outrangeconst;
msfeatures = mpmask;

normfeatures = [rawfeatures, msfeatures];

end

