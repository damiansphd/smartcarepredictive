clear; close all; clc;

[modelresultsfile] = selectModelResultsFile();
basemodelresultsfile = strrep(modelresultsfile, ' ModelResults', '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';

modelresultsmatfile = sprintf('%s.mat', modelresultsfile);
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsmatfile), 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');

featureparamsfile = generateFileNameFromFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile));
toc

labelidx = 5;

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));

for p = 1:npatients   
    fprintf('Plotting results for patient %d\n', p);
    plotMeasuresAndPredictionsForPatient(pmPatients(p,:), pmAntibiotics(pmAntibiotics.PatientNbr==p,:), ...
        pmRawDatacube(p, :, :), pmInterpDatacube(p, :, :), pmFeatureIndex, pmIVLabels, pmExLabels, ...
        pmModelRes, pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr==p,:), ...
        measures, nmeasures, labelidx, pmFeatureParamsRow, pmModelParamsRow, plotsubfolder, basemodelresultsfile);
end 


