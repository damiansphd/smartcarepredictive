function analyseDWModelPrediction(patientrow, calcdatedn, ...
    pmTrCVFeatureIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, pmModelRes, ...
    measures, nmeasures, labelidx, featureparamsrow, lbdisplayname, ...
    plotsubfolder, basemodelresultsfile)
    
% analyseDWModelPrediction - show contributions from the different sets of
% features - for Data window version of the predictive classifier

% *** change to use normfeatures rather than underlying cubes ***

pnbr = patientrow.PatientNbr;
fold = pmTrCVPatientSplit.SplitNbr(pmTrCVPatientSplit.PatientNbr == pnbr);
normfeaturerow = pmTrCVNormFeatures(pmTrCVFeatureIndex.PatientNbr == pnbr & pmTrCVFeatureIndex.ScenType == 0 & pmTrCVFeatureIndex.CalcDatedn == calcdatedn, :);

[datawinduration, nrawmeasures, nmsmeasures, nvolmeasures, npmeanmeasures, ...
          nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures, ...
          nfeatures, nnormfeatures] = setDWNumMeasAndFeatures(featureparamsrow, measures, nmeasures);

featureweights = pmModelRes.pmNDayRes(labelidx).Folds(fold).Model.Coefficients.Estimate(2:end);
bias = pmModelRes.pmNDayRes(labelidx).Folds(fold).Model.Coefficients.Estimate(1);
nextfeat = 1;

fprintf('\n');
fprintf('Prediction Analysis for Patient %d, Calc Date %d (Fold %d)\n', pnbr, calcdatedn, fold);
fprintf('------------------------------------------------\n');
fprintf('\n');
fprintf('Total Features * Weights: %+.2f\n', normfeaturerow * featureweights);
fprintf('Bias                    : %+.2f\n', bias);
fprintf('Prediction              : %5.2f%%\n', 100 * sigmoid((normfeaturerow * featureweights) + bias));

tempmeas = measures(measures.RawMeas==1,:);
if nrawmeasures == 0
    nmfeat = 0;
else
    nmfeat = nrawfeatures/nrawmeasures;
end
fprintf('\n');
fprintf('Raw Measures (%2d features per measure)\n', nmfeat);
fprintf('--------------------------------------\n');
for i = 1:nrawmeasures
    printFeatVals(normfeaturerow, featureweights, calcdatedn, i, tempmeas, nmfeat, nextfeat);
    nextfeat = nextfeat + nmfeat;
end

tempmeas = measures(measures.MSMeas==1,:);
if nmsmeasures == 0
    nmsfeat = 0;
else
    nmsfeat = nmsfeatures/nmsmeasures;
end
fprintf('\n');
fprintf('Missingness Measures (%2d features per measure)\n', nmsfeat);
fprintf('----------------------------------------------\n');
for i = 1:nmsmeasures
    printFeatVals(normfeaturerow, featureweights, calcdatedn, i, tempmeas, nmsfeat, nextfeat);
    nextfeat = nextfeat + nmsfeat;
end

tempmeas = measures(measures.Volatility==1,:);
if nvolmeasures == 0
    nmfeat = 0;
else
    nmfeat = nvolfeatures/nvolmeasures;
end
fprintf('\n');
fprintf('Volatility Measures (%2d features per measure)\n', nmfeat);
fprintf('---------------------------------------------\n');
for i = 1:nvolmeasures
    printFeatVals(normfeaturerow, featureweights, calcdatedn, i, tempmeas, nmfeat, nextfeat);
    nextfeat = nextfeat + nmfeat;
end

tempmeas = measures(measures.PMean==1,:);
if npmeanmeasures == 0
    nmfeat = 0;
else
    nmfeat = npmeanfeatures/npmeanmeasures;
end
fprintf('\n');
fprintf('Patient Mean (%2d features per measure)\n', nmfeat);
fprintf('--------------------------------------\n');
for i = 1:npmeanmeasures
    printFeatVals(normfeaturerow, featureweights, calcdatedn, i, tempmeas, nmfeat, nextfeat);
    nextfeat = nextfeat + nmfeat;
end

end

