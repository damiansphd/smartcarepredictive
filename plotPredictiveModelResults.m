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
load(fullfile(basedir, subfolder, modelresultsmatfile), 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
if pmModelParamsRow.labelmethod == 1
    pmIVModelRes = pmModelRes;
    pmIVFeatureParamsRow = pmFeatureParamsRow;
    pmIVModelParamsRow = pmModelParamsRow;
    modelresultsfile2 = strrep(modelresultsfile,'_lm1','_lm2');
    modelresultsmatfile2 = sprintf('%s.mat', modelresultsfile2);
    fprintf('Loading predictive model results data for %s\n', modelresultsfile2);
    load(fullfile(basedir, subfolder, modelresultsmatfile2), 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
    pmExModelRes = pmModelRes;
    pmExFeatureParamsRow = pmFeatureParamsRow;
    pmExModelParamsRow = pmModelParamsRow;
elseif pmModelParamsRow.labelmethod == 2
    pmExModelRes = pmModelRes;
    pmExFeatureParamsRow = pmFeatureParamsRow;
    pmExModelParamsRow = pmModelParamsRow;
    modelresultsfile2 = strrep(modelresultsfile,'_lm2','_lm1');
    modelresultsmatfile2 = sprintf('%s.mat', modelresultsfile2);
    fprintf('Loading predictive model results data for %s\n', modelresultsfile2);
    load(fullfile(basedir, subfolder, modelresultsmatfile2), 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
    pmIVModelRes = pmModelRes;
    pmIVFeatureParamsRow = pmFeatureParamsRow;
    pmIVModelParamsRow = pmModelParamsRow;
else
    fprintf('Unknown label method\n');
    return;
end
featureparamsfile = generateFileNameFromFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile));
clear('pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));
labelidx = 5;

[plottype, validresponse] = selectPlotType;
if ~validresponse
    return;
end

if plottype == 1
    % plot weights
    fprintf('Plotting Model Weights\n');
    plotModelWeights(pmIVModelRes, pmExModelRes, measures, nmeasures, ...
        pmIVFeatureParamsRow, plotsubfolder, basemodelresultsfile);
elseif plottype == 2
    % plot PR and ROC Curves
    fprintf('Plotting PR and ROC Curves\n');
    plotPRAndROCCurves(pmIVModelRes, pmExModelRes, pmIVLabels, pmExLabels, ...
        pmIVFeatureParamsRow, plotsubfolder, basemodelresultsfile);
elseif plottype == 3
    % plot measures and predictions for all patients
    for p = 1:npatients
        fprintf('Plotting results for patient %d\n', p);
        plotMeasuresAndPredictionsForPatient(pmPatients(p,:), ...
            pmAntibiotics(pmAntibiotics.PatientNbr == p & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(p),:), ...
            pmAMPred(pmAMPred.PatientNbr == p,:), ...
            pmRawDatacube(p, :, :), pmInterpDatacube(p, :, :), pmFeatureIndex, pmIVLabels, pmExLabels, ...
            pmIVModelRes, pmExModelRes, pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p,:), ...
            measures, nmeasures, labelidx, pmIVFeatureParamsRow, plotsubfolder, basemodelresultsfile);
    end
elseif plottype == 4
    % plot measures and predictions for a single patient
    [p, validresponse] = selectPatientNbr(npatients);
    if ~validresponse
        return;
    end
    fprintf('Plotting results for patient %d\n', p);
        plotMeasuresAndPredictionsForPatient(pmPatients(p,:), ...
            pmAntibiotics(pmAntibiotics.PatientNbr == p & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(p),:), ...
            pmAMPred(pmAMPred.PatientNbr == p,:), ...
            pmRawDatacube(p, :, :), pmInterpDatacube(p, :, :), pmFeatureIndex, pmIVLabels, pmExLabels, ...
            pmIVModelRes, pmExModelRes, pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p,:), ...
            measures, nmeasures, labelidx, pmIVFeatureParamsRow, plotsubfolder, basemodelresultsfile);  
end


