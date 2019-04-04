function [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrLabels, ...
    pmValFeatureIndex, pmValFeatures, pmValNormFeatures, pmValLabels] = ...
    splitTrainVsVal(pmFeatureIndex, pmFeatures, pmNormFeatures, pmLabels, trainpct)

% splitTrainVsVal - split the features and labels into a training set and a
% validation set with the percentage split defined by trainpct

rng(2);
shuffle = randperm(size(unique(pmFeatureIndex.PatientNbr),1));

splitidx = round(size(shuffle,2) * trainpct);

pmTrFeatureIndex  = pmFeatureIndex(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);
pmTrFeatures      = pmFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);
pmTrNormFeatures  = pmNormFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);
pmTrLabels        = pmLabels(ismember(pmFeatureIndex.PatientNbr, shuffle(1:splitidx)),:);

pmValFeatureIndex = pmFeatureIndex(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);
pmValFeatures     = pmFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);
pmValNormFeatures = pmNormFeatures(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);
pmValLabels       = pmLabels(ismember(pmFeatureIndex.PatientNbr, shuffle((splitidx + 1):end)),:);

end

