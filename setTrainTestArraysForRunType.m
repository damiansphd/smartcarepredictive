function [trainfeatidx, trainfeatures, trainlabels, trainpatsplit, testfeatidx, testfeatures, testlabels, testpatsplit] = ...
            setTrainTestArraysForRunType(pmTrCVFeatureIndex, pmTrCVNormFeatures, trainlabels, pmTrCVPatientSplit, ...
                                         pmTestFeatureIndex, pmTestNormFeatures, testlabels, pmTestPatientSplit, ...
                                         runtype)

% setTrainTestArrays - sets the training and test arrays based on run type

if runtype == 1
    trainfeatidx  = pmTrCVFeatureIndex;
    testfeatidx   = pmTrCVFeatureIndex;
    trainfeatures = pmTrCVNormFeatures;
    testfeatures  = pmTrCVNormFeatures;
    testlabels    = trainlabels;
    trainpatsplit = pmTrCVPatientSplit;
    testpatsplit  = pmTrCVPatientSplit;
elseif runtype == 2
    trainfeatidx  = pmTrCVFeatureIndex;
    testfeatidx   = pmTestFeatureIndex;
    trainfeatures = pmTrCVNormFeatures;
    testfeatures  = pmTestNormFeatures;
    trainpatsplit = pmTrCVPatientSplit;
    testpatsplit  = pmTestPatientSplit;
end

end

