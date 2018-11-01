clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
runparameterfile = selectModelRunParameters();
runparameterfile = strcat(runparameterfile, '.xlsx');

pmRunParameters = readtable(fullfile(basedir, subfolder, runparameterfile));

maxfeatureduration = max(pmRunParameters.featureduration);

for rp = 1:size(pmRunParameters,1)
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',pmRunParameters.modelinputsmatfile{rp});
    fprintf('Loading predictive model input data\n');
    load(fullfile(basedir, subfolder, modelinputsmatfile));
    toc
    fprintf('\n');
    
    % pre-process to remove unwanted measures and data
    tic
    [measures, nmeasures, pmOverallStats, pmPatientMeasStats, ...
        pmRawDatacube, pmInterpDatacube] = preprocessMeasuresMask(measures, ...
        nmeasures, pmOverallStats, pmPatientMeasStats, pmRawDatacube, ...
        pmInterpDatacube, pmRunParameters.measuresmask(rp));
    toc
    fprintf('\n');

    % create normalised data cube
    tic
    fprintf('Normalising data\n');
    [pmInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, pmOverallStats, pmPatientMeasStats, ...
        npatients, maxdays, nmeasures, pmRunParameters.normmethod(rp)); 
    toc
    fprintf('\n');

    % create feature/label examples from the data
    % need to add setting and using of the measures mask
    tic
    fprintf('Creating Features and Labels\n');
    [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels] = createFeaturesAndLabelsFcn(pmPatients, pmAntibiotics, ...
        pmRawDatacube, pmInterpDatacube, pmInterpNormcube, measures, nmeasures, npatients, maxdays, maxfeatureduration, ...
        pmRunParameters.featureduration(rp), pmRunParameters.predictionduration(rp));
    toc
    fprintf('\n');

    tic
    fprintf('Split into training and validation sets\n');
    [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrIVLabels, ...
        pmValFeatureIndex, pmValFeatures, pmValNormFeatures, pmValIVLabels] = ...
        splitTrainVsVal(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmRunParameters.trainpct(rp)); 
    toc
    fprintf('\n');
    
    % save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    basefilename = generateFileNameFromRunParameters(pmRunParameters(rp,:));
    outputfilename = sprintf('%s.mat',basefilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', ...
        'pmOverallStats', 'pmPatientMeasStats', ...
        'pmRawDatacube', 'pmInterpDatacube', 'maxdays', ...
        'measures', 'nmeasures', ...
        'pmRunParameters', 'rp', 'pmInterpNormcube', ...
        'pmFeatureIndex', 'pmFeatures', 'pmNormFeatures', 'pmIVLabels', ...
        'pmTrFeatureIndex', 'pmTrFeatures', 'pmTrNormFeatures', 'pmTrIVLabels', ...
        'pmValFeatureIndex', 'pmValFeatures', 'pmValNormFeatures', 'pmValIVLabels');
    toc
    fprintf('\n');
end
