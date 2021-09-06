function [qcfeatures, qcfeatnames, qcmeasures, qcmodfeatparamrow] = createQCFeaturesFromDataWinArray(datawinarray, featureparamsrow, nexamples, totalwin, measures, nmeasures)

% createQCFeaturesFromDataWinArray - function to create the input features
% for the quality classifier from a datawin array

dummyarray = zeros(nexamples, totalwin, nmeasures);
mswinarray = zeros(nexamples, totalwin, nmeasures);
mswinarray(isnan(datawinarray)) = 1;

qcmodfeatparamrow             = featureparamsrow;
qcmodfeatparamrow.msfeat      = qcmodfeatparamrow.rawmeasfeat;
qcmodfeatparamrow.rawmeasfeat = 1;
qcmodfeatparamrow.volfeat     = 1;
qcmodfeatparamrow.pmeanfeat   = 1;

[qcfeatures, qcfeatnames, qcmeasures] = createModelFeaturesFcn(dummyarray, ...
        mswinarray, dummyarray, dummyarray, qcmodfeatparamrow, nexamples, totalwin, measures, nmeasures);
    
end

