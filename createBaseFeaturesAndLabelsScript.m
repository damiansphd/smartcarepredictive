clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

subfolder = 'DataFiles';
basefeatureparamfile = selectBaseFeatureParameters();
basefeatureparamfile = strcat(basefeatureparamfile, '.xlsx');

pmBaseFeatureParams = readtable(fullfile(basedir, subfolder, basefeatureparamfile));

maxfeatureduration = max(pmBaseFeatureParams.featureduration);
maxnormwindow      = max(pmBaseFeatureParams.normwindow);

fprintf('Creating Feature and Label files for %2d permutations of parameters\n', size(pmBaseFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmBaseFeatureParams,1)
    basefilename = generateFileNameFromBaseFeatureParams(pmBaseFeatureParams(rp,:));
    fprintf('%2d. Generating features and lables for %s\n', rp, basefilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',pmBaseFeatureParams.modelinputsmatfile{rp});
    fprintf('Loading model input data\n');
    load(fullfile(basedir, subfolder, modelinputsmatfile));

    toc
    fprintf('\n');
    
    [pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
        muntilepoints, sigmantilepoints, pmDatacube, pmInterpDatacube, pmInterpVolcube, mvolstats, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ntilepoints, pmMSDatacube] ...
        = createPreBaseFeat(pmPatients, npatients, pmOverallStats, pmPatientMeasStats, ...
        pmRawDatacube, maxdays, measures, nmeasures, pmBaseFeatureParams(rp, :));
    
    % create  base feature/label examples from the data
    % need to add setting and using of the measures mask
    tic
    fprintf('Creating Base Features and Labels\n');
    [pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
        pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
        pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, ...
        pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels] ...
        = createBaseFeaturesAndLabelsFcn(pmPatients, pmAntibiotics, pmAMPred, ...
            pmDatacube, pmInterpVolcube, pmInterpSegVolcube, ...
            pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, pmMSDatacube, ...
            pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
            pmMucube, pmSigmacube, ...
            measures, nmeasures, npatients, maxdays, ...
            maxfeatureduration, maxnormwindow, pmBaseFeatureParams(rp,:));
    toc
    fprintf('\n');
    
    % augment the dataset with missingness scenarios if necessary
    if pmBaseFeatureParams.augmethod(rp) > 1
        [pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
            pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
            pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, ...
            pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels] ...
            = augmentFeaturesAndLabels(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, ...
            pmRangeFeats, pmVolFeats, pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
            pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, ...
            pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels, pmBaseFeatureParams(rp,:), ...
            nmeasures);
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
        'pmRawDatacube', 'pmInterpDatacube', 'pmDatacube', ...
        'maxdays', 'measures', 'nmeasures', 'ntilepoints', ...
        'pmBaseFeatureParams', 'rp', ...
        'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
        'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
        'pmBucketedcube', 'pmMSDatacube', 'pmInterpVolcube', 'mvolstats', 'pmInterpSegVolcube', ...
        'pmInterpRangecube', 'pmInterpSegAvgcube', ...
        'pmFeatureIndex', 'pmMuIndex', 'pmSigmaIndex', ...
        'pmRawMeasFeats', 'pmMSFeats', 'pmBuckMeasFeats', 'pmRangeFeats', 'pmVolFeats', ...
        'pmAvgSegFeats', 'pmVolSegFeats', 'pmCChangeFeats', ...
        'pmPMeanFeats', 'pmPStdFeats', 'pmBuckPMeanFeats', 'pmBuckPStdFeats', ...
        'pmDateFeats', 'pmDemoFeats', ...
        'pmIVLabels', 'pmABLabels', 'pmExLabels', 'pmExLBLabels', 'pmExABLabels', 'pmExABxElLabels');
    outputfilename = strrep(outputfilename, 'df3', 'df0');
    outputfilename = strrep(outputfilename, 'df1', 'df0');
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', ...
        'pmRawDatacube', 'pmInterpDatacube', 'pmDatacube', ...
        'maxdays', 'measures', 'nmeasures', 'ntilepoints', ...
        'pmBaseFeatureParams', 'rp', ...
        'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
        'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
        'pmBucketedcube', 'pmMSDatacube', 'pmInterpVolcube', 'mvolstats', 'pmInterpSegVolcube', ...
        'pmInterpRangecube', 'pmInterpSegAvgcube', ...
        'pmFeatureIndex', 'pmMuIndex', 'pmSigmaIndex', ...
        'pmRawMeasFeats', 'pmMSFeats', 'pmBuckMeasFeats', 'pmRangeFeats', 'pmVolFeats', ...
        'pmAvgSegFeats', 'pmVolSegFeats', 'pmCChangeFeats', ...
        'pmPMeanFeats', 'pmPStdFeats', 'pmBuckPMeanFeats', 'pmBuckPStdFeats', ...
        'pmDateFeats', 'pmDemoFeats', ...
        'pmIVLabels', 'pmABLabels', 'pmExLabels', 'pmExLBLabels', 'pmExABLabels', 'pmExABxElLabels');
    toc
    fprintf('\n');
end

beep on;
beep;

