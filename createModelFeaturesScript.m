clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

subfolder = 'DataFiles';
[fv1name, validresponse] = selectFeatVer();
if ~validresponse
    return
end

[modfeatparamfile, ~, ~, validresponse] = selectModelFeatureParameters(fv1name);
if ~validresponse
    return
end

modfeatparamfile = strcat(modfeatparamfile, '.xlsx');

pmModFeatureParams = readtable(fullfile(basedir, subfolder, modfeatparamfile));

fprintf('Creating Model feature and label files for %2d permutations of parameters\n', size(pmModFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmModFeatureParams,1)
    pmModFeatParamsRow = pmModFeatureParams(rp,:);
    outputfilename = generateFileNameFromModFeatureParams(pmModFeatParamsRow);
    fprintf('%2d. Generating model features and labels for %s\n', rp, outputfilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % 1. load data window arrays
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    datawinfile = generateFileNameFromDataWinParams(pmModFeatParamsRow);
    fprintf('Loading data window array data: %s\n', datawinfile);
    load(fullfile(basedir, subfolder, strcat(datawinfile, '.mat')));
    toc
    fprintf('\n');
    
    [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ...
        pmNormDataWinArray, pmInterpNormDataWinArray, pmRawMeasWinArray, pmMSWinArray, ...
        pmVolWinArray, pmPMeanWinArray, totalvolwin, measures] = createModFeaturesFromDWArrays(pmDataWinArray, ...
            pmOverallStats, nexamples, measures, nmeasures, pmModFeatParamsRow);
    
    % 6. save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%s.mat',outputfilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures', ...
        'pmRawDatacube', 'pmModFeatParamsRow', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'pmMuIndex', 'pmSigmaIndex', ...
        'pmNormDataWinArray', 'pmInterpNormDataWinArray', ...
        'pmRawMeasWinArray', 'pmMSWinArray', 'pmVolWinArray', 'pmPMeanWinArray', 'totalvolwin', ...
        'pmNormFeatures', 'pmNormFeatNames');
    toc
    fprintf('\n');
end

beep on;
beep;

