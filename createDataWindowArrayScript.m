clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

subfolder = 'DataFiles';
[fv1name, validresponse] = selectFeatVer();
datawinrpfile = selectDataWindowArrayParameters(fv1name);
datawinrpfile = strcat(datawinrpfile, '.xlsx');

pmDataWinParams = readtable(fullfile(basedir, subfolder, datawinrpfile));

maxfeatureduration = max(pmDataWinParams.datawinduration);
maxnormwindow      = max(pmDataWinParams.normwinduration);

fprintf('Creating Feature and Label files for %2d permutations of parameters\n', size(pmDataWinParams,1));
fprintf('\n');

for rp = 1:size(pmDataWinParams,1)
    
    pmDataWinParamsRow = pmDataWinParams(rp,:);
    
    datawinfilename = generateFileNameFromDataWinParams(pmDataWinParamsRow);
    fprintf('%2d. Generating features and lables for %s\n', rp, datawinfilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',pmDataWinParamsRow.modelinputsmatfile{1});
    fprintf('Loading model input data\n');
    load(fullfile(basedir, subfolder, modelinputsmatfile));

    toc
    fprintf('\n');
    
    % create  data window array from the raw data cube
    
    tic
    fprintf('Creating Feature Index, Data Window, and Label arrays\n');
    [pmFeatureIndex, pmDataWinArray, pmExABxElLabels, nexamples] ...
        = createDataWindowArrayFcn(pmPatients, pmAntibiotics, pmAMPred, pmRawDatacube, ...
            nmeasures, npatients, maxdays, maxfeatureduration, maxnormwindow, pmDataWinParamsRow);
    toc
    fprintf('\n');
    
    % augment the dataset with missingness scenarios if necessary
    if pmDataWinParams.augmethod(rp) > 1
        [pmFeatureIndex, pmDataWinArray, pmExABxElLabels] ...
            = augmentDataWindowArray(pmFeatureIndex, pmDataWinArray, ...
                pmExABxElLabels, pmDataWinParamsRow, nmeasures);
    end
    
    % save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%s.mat',datawinfilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', 'pmRawDatacube', ...
        'maxdays', 'measures', 'nmeasures', 'pmDataWinParamsRow', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', 'nexamples');
    toc
    fprintf('\n');
end

beep on;
beep;

