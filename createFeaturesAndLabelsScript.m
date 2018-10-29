clear; close all; clc;

RunParameterFiles = {  
            'pm_stSC_fd20_pd15_mm1_nm1_tp0.7.xlsx';
            'pm_stSC_fd20_pd15_mm1_nm2_tp0.7.xlsx';
            };


nfiles = size(RunParameterFiles,1);
fprintf('Run parameter files available\n');
fprintf('-----------------------------\n');
for i = 1:nfiles
    fprintf('%d: %s\n', i, RunParameterFiles{i});
end
fprintf('\n');

fileidx = input('Choose file to use ? ');
if fileidx > nfiles
    fprintf('Invalid choice\n');
    return;
end
if isequal(fileidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

basedir = './';
subfolder = 'DataFiles';
runparameterfile = RunParameterFiles{fileidx};

featureduration = 20;
predictionduration = 15;
trainpct = 0.7;

pmRunParameters = readtable(fullfile(basedir, subfolder, runparameterfile));

for rp = 1:size(pmRunParameters,1)
    % load model inputs
    tic
    basedir = './';
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',pmRunParameters.modelinputsmatfile{rp});
    fprintf('Loading predictive model input data\n');
    load(fullfile(basedir, subfolder, modelinputsmatfile));
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
    [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels] = createFeaturesAndLabels(pmPatients, pmAntibiotics, ...
        pmRawDatacube, pmInterpDatacube, pmInterpNormcube, measures, nmeasures, npatients, maxdays, ...
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
    basedir = './';
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('pm_st%s_fd%d_pd%d_mm%d_nm%d_sm%d_tp%0.2f.mat', ...
        pmRunParameters.StudyDisplayName{rp}, pmRunParameters.featureduration(rp), ...
        pmRunParameters.predictionduration(rp), pmRunParameters.measuresmask(rp), ...
        pmRunParameters.normmethod(rp), pmRunParameters.smoothingmethod(rp), ...
        pmRunParameters.trainpct(rp));
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'pmRunParameters', 'rp', 'pmInterpNormcube', ...
        'pmFeatureIndex', 'pmFeatures', 'pmNormFeatures', 'pmIVLabels', ...
        'pmTrFeatureIndex', 'pmTrFeatures', 'pmTrNormFeatures', 'pmTrIVLabels', ...
        'pmValFeatureIndex', 'pmValFeatures', 'pmValNormFeatures', 'pmValIVLabels');
    toc
    fprintf('\n');
end
