clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

subfolder = 'DataFiles';
[fv1name, validresponse] = selectFeatVer();
basefeatureparamfile = selectBaseFeatureParametersNew(fv1name);
basefeatureparamfile = strcat(basefeatureparamfile, '.xlsx');

pmBaseFeatureParams = readtable(fullfile(basedir, subfolder, basefeatureparamfile));

maxfeatureduration = max(pmBaseFeatureParams.featureduration);
maxnormwindow      = max(pmBaseFeatureParams.normwindow);

fprintf('Creating Feature and Label files for %2d permutations of parameters\n', size(pmBaseFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmBaseFeatureParams,1)
    
    pmBaseFeatureParamsRow = pmBaseFeatureParams(rp,:);
    
    basefilename = generateFileNameFromBaseFeatureParamsNew(pmBaseFeatureParamsRow);
    fprintf('%2d. Generating features and lables for %s\n', rp, basefilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',pmBaseFeatureParamsRow.modelinputsmatfile{1});
    fprintf('Loading model input data\n');
    load(fullfile(basedir, subfolder, modelinputsmatfile));

    toc
    fprintf('\n');
    
    [pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube] = createPMNormWindowcubeNew(pmPatients, ...
        pmRawDatacube, pmOverallStats, pmBaseFeatureParamsRow.normmethod, pmBaseFeatureParamsRow.normwindow, ...
        npatients, maxdays, measures, nmeasures, studydisplayname); 
    
    % create  base feature/label examples from the data
    % need to add setting and using of the measures mask
    % restructure the function to just create the feat idx, mu idx, sigma
    % idx, and rawmeasfeats, pmeanfeats.
    % then create a new function that performs the interpolation, smoothing
    % and creates missingness features and vol feats, and call this after the
    % augmentation function
    tic
    fprintf('Creating Base Features and Labels\n');
    [pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels] ...
        = createBaseFeaturesAndLabelsFcnNew(pmPatients, pmAntibiotics, pmAMPred, ...
            pmRawDatacube, pmMuNormcube, pmMucube, pmSigmacube, pmOverallStats, ...
            measures, nmeasures, npatients, maxdays, maxfeatureduration, maxnormwindow, pmBaseFeatureParamsRow);
    toc
    fprintf('\n');
    
    % augment the dataset with missingness scenarios if necessary
    if pmBaseFeatureParams.augmethod(rp) > 1
        [pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels] ...
            = augmentFeaturesAndLabelsNew(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, ...
                pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels, pmBaseFeatureParamsRow, nmeasures);
    end
    
    % save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%s.mat',basefilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', ...
        'maxdays', 'measures', 'nmeasures', 'pmBaseFeatureParamsRow', ...
        'pmRawDatacube', 'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
        'pmFeatureIndex', 'pmMuIndex', 'pmSigmaIndex', ...
        'pmRawMeasFeats', 'pmMSFeats', 'pmVolFeats', 'pmPMeanFeats', 'pmExABxElLabels');
    toc
    fprintf('\n');
end

beep on;
beep;

