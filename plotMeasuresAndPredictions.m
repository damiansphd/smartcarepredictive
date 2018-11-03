clear; close all; clc;

[modelinputfile] = selectFeatureAndLabelInputs('Single');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%s.mat',modelinputfile);
modelresultsmatfile = sprintf('%s ModelResults.mat',modelinputfile);
fprintf('Loading predictive model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));
load(fullfile(basedir, subfolder, modelresultsmatfile), 'pmRunParameters', 'nmodels', 'pmModelRes');
toc

modelresults = pmModelRes(rp);
clear pmModelRes;
labelidx = 5;

plotsubfolder = sprintf('Plots/%s_PredictionPlots', modelinputfile);
mkdir(fullfile(basedir, plotsubfolder));

for p = 1:npatients   
    fprintf('Plotting results for patient %d\n', p);
    plotMeasuresAndPredictionsForPatient(pmPatients(p,:), pmAntibiotics(pmAntibiotics.PatientNbr==p,:), ...
        pmRawDatacube(p, :, :), pmInterpNormcube(p, :, :), pmFeatureIndex, pmIVLabels, ...
        modelresults, measures, nmeasures, labelidx, pmRunParameters(rp,:), plotsubfolder);
end 


