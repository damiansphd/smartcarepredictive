clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
[fv1name, validresponse] = selectFeatVer();
if ~validresponse
    return
end

[featureparamfile, ~, ~, validresponse] = selectFeatureParametersNew(fv1name);
if ~validresponse
    return
end

featureparamfile = strcat(featureparamfile, '.xlsx');

pmFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

maxfeatureduration = max(pmFeatureParams.featureduration);
maxnormwindow      = max(pmFeatureParams.normwindow);

fprintf('Creating Feature and Label files for %2d permutations of parameters\n', size(pmFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmFeatureParams,1)
    pmFeatureParamsRow = pmFeatureParams(rp,:);
    outputfilename = generateFileNameFromFullFeatureParamsNew(pmFeatureParamsRow);
    fprintf('%2d. Generating features and labels for %s\n', rp, outputfilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    basefeatfile = generateFileNameFromBaseFeatureParamsNew(pmFeatureParamsRow);
    fprintf('Loading base feature and label data: %s\n', basefeatfile);
    load(fullfile(basedir, subfolder, strcat(basefeatfile, '.mat')));
    toc
    fprintf('\n');
    
    tic
    [pmNormFeatures, pmNormFeatNames, measures] = createFullFeaturesAndLabelsFcnNew(pmRawMeasFeats, ...
                pmMSFeats, pmVolFeats, pmPMeanFeats, pmFeatureParamsRow, measures, nmeasures);
    toc
    fprintf('\n');
    
    % save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%s.mat',outputfilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures', ...
        'pmRawDatacube', 'pmFeatureParamsRow', ...
        'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
        'pmFeatureIndex', 'pmMuIndex', 'pmSigmaIndex', ...
        'pmRawMeasFeats', 'pmMSFeats', 'pmVolFeats', 'pmPMeanFeats', ...
        'pmNormFeatures', 'pmNormFeatNames', 'pmExABxElLabels');
    toc
    fprintf('\n');
end

beep on;
beep;

