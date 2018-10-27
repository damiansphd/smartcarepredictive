function [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrIVLabels, ...
    pmValFeatureIndex, pmValFeatures, pmValNormFeatures, pmValIVLabels] = ...
    splitTrainVsVal(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, trainpct)

% splitTrainVsVal - split the features and labels into a training set and a
% validation set with the percentage split defined by trainpct

rng(2);
shuffle = randperm(size(pmFeatureIndex,1));

splitidx = round(size(shuffle,2) * trainpct);

pmTrFeatureIndex  = pmFeatureIndex(shuffle(1:splitidx),:);
pmTrFeatures      = pmFeatures(shuffle(1:splitidx),:);
pmTrNormFeatures  = pmNormFeatures(shuffle(1:splitidx),:);
pmTrIVLabels      = pmIVLabels(shuffle(1:splitidx),:);

pmValFeatureIndex = pmFeatureIndex(shuffle((splitidx + 1):end),:);
pmValFeatures     = pmFeatures(shuffle((splitidx + 1):end),:);
pmValNormFeatures = pmNormFeatures(shuffle((splitidx + 1):end),:);
pmValIVLabels     = pmIVLabels(shuffle((splitidx + 1):end),:);

end

