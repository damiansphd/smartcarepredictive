clear; close all; clc;

% logic to load in results for model runs with  both Ex and IV labels 
[modelresultsfile] = selectModelResultsFile();
basemodelresultsfile = strrep(modelresultsfile, ' ModelResults', '');
basemodelresultsfile = strrep(basemodelresultsfile, '_lm1', '');
basemodelresultsfile = strrep(basemodelresultsfile, '_lm2', '');
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelresultsmatfile = sprintf('%s.mat', modelresultsfile);
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsmatfile), 'pmModelRes', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmTrCVFeatureIndex', 'pmTrCVFeatures', ...
    'pmTrCVNormFeatures', 'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVPatientSplit');
if pmModelParamsRow.labelmethod == 1
    pmIVModelRes         = pmModelRes;
    modelresultsfile2 = strrep(modelresultsfile,'_lm1','_lm2');
    modelresultsmatfile2 = sprintf('%s.mat', modelresultsfile2);
    fprintf('Loading predictive model results data for %s\n', modelresultsfile2);
    load(fullfile(basedir, subfolder, modelresultsmatfile2), 'pmModelRes', 'pmModelParamsRow');
    pmExModelRes         = pmModelRes;
elseif pmModelParamsRow.labelmethod == 2
    pmExModelRes         = pmModelRes;
    modelresultsfile2 = strrep(modelresultsfile,'_lm2','_lm1');
    modelresultsmatfile2 = sprintf('%s.mat', modelresultsfile2);
    fprintf('Loading predictive model results data for %s\n', modelresultsfile2);
    load(fullfile(basedir, subfolder, modelresultsmatfile2), 'pmModelRes', 'pmModelParamsRow');
    pmIVModelRes         = pmModelRes;
else
    fprintf('Unknown label method\n');
    return;
end
featureparamsfile = generateFileNameFromFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile));
clear('pmModelRes');
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));
labelidx = 5;

[plottype, validresponse] = selectPlotType;
if ~validresponse
    return;
end

selectdays = setFocusDays();

if plottype == 1
    % plot weights
    fprintf('Plotting Model Weights\n');
    plotModelWeights(pmIVModelRes, pmExModelRes, measures, nmeasures, ...
        pmFeatureParamsRow, pmModelParamsRow, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 2
    % plot weights for days 2, 5, 8
    fprintf('Plotting Model Weights for prediction days 2, 5, 8\n');
    plotSelectModelWeights(pmIVModelRes, pmExModelRes, measures, nmeasures, ...
        pmFeatureParamsRow, pmModelParamsRow, selectdays, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 3    
    % plot PR and ROC Curves
    fprintf('Plotting PR and ROC Curves\n');
    plotPRAndROCCurves(pmIVModelRes, pmExModelRes, ...
        pmFeatureParamsRow, plotsubfolder, basemodelresultsfile);
elseif plottype == 4    
    % plot PR and ROC Curves for days 2, 5, 8
    fprintf('Plotting PR and ROC Curves for prediction days 2, 5, 8\n');
    plotSelectPRAndROCCurves(pmIVModelRes, pmExModelRes, ...
        pmFeatureParamsRow, selectdays, plotsubfolder, basemodelresultsfile);      
elseif plottype == 5
    % plot measures and predictions for all non-test set patients
    ntrcvpatients = size(pmTrCVPatientSplit,1);
    for pnbr = 1:ntrcvpatients
        pnbr = pmTrCVPatientSplit.PatientNbr(pnbr);
        fprintf('Plotting results for patient %d\n', pnbr);
        plotMeasuresAndPredictionsForPatient(pmPatients(pnbr,:), ...
            pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
            pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
            pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmTrCVFeatureIndex, pmTrCVIVLabels, pmTrCVExLabels, ...
            pmIVModelRes, pmExModelRes, pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
            measures, nmeasures, labelidx, pmFeatureParamsRow, plotsubfolder, basemodelresultsfile);
    end
elseif plottype == 6
    % plot measures and predictions for a single patient
    [pnbr, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    fprintf('Plotting results for patient %d\n', pnbr);
        plotMeasuresAndPredictionsForPatient(pmPatients(pnbr,:), ...
            pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
            pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
            pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmTrCVFeatureIndex, pmTrCVIVLabels, pmTrCVExLabels, ...
            pmIVModelRes, pmExModelRes, pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
            measures, nmeasures, labelidx, pmFeatureParamsRow, plotsubfolder, basemodelresultsfile);  
end


