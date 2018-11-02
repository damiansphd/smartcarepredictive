function [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrIVLabels, ...
    pmValFeatureIndex, pmValFeatures, pmValNormFeatures, pmValIVLabels] = ...
    splitTrainVsVal(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, trainpct)

% splitTrainVsVal - split the features and labels into a training set and a
% validation set with the percentage split defined by trainpct

rng(2);
shuffle = randperm(size(unique(pmFeatureIndex.PatientNbr),1));

splitidx = round(size(shuffle,2) * trainpct);

pmTrFeatureIndex  = pmFeatureIndex(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);
pmTrFeatures      = pmFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);
pmTrNormFeatures  = pmNormFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);
pmTrIVLabels      = pmIVLabels(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);

pmValFeatureIndex = pmFeatureIndex(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);
pmValFeatures     = pmFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);
pmValNormFeatures = pmNormFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);
pmValIVLabels     = pmIVLabels(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);

end

