clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
featureparamfile = selectFeatureParameters();
featureparamfile = strcat(featureparamfile, '.xlsx');

pmFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

maxfeatureduration = max(pmFeatureParams.featureduration);


for rp = 1:size(pmFeatureParams,1)
    basefilename = generateFileNameFromFeatureParams(pmFeatureParams(rp,:));
    fprintf('Generating features and lables for %s\n', basefilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',pmFeatureParams.modelinputsmatfile{rp});
    fprintf('Loading model input data\n');
    load(fullfile(basedir, subfolder, modelinputsmatfile));

    toc
    fprintf('\n');
    
    % pre-process to remove unwanted measures and data
    tic
    [measures, nmeasures, pmOverallStats, pmPatientMeasStats, ...
        pmRawDatacube, pmInterpDatacube] = preprocessMeasuresMask(measures, ...
        nmeasures, pmOverallStats, pmPatientMeasStats, pmRawDatacube, ...
        pmInterpDatacube, pmFeatureParams.measuresmask(rp));
    toc
    fprintf('\n');

    % create normalised data cube
    tic
    fprintf('Normalising data\n');
    [pmInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, pmOverallStats, pmPatientMeasStats, ...
        npatients, maxdays, nmeasures, pmFeatureParams.normmethod(rp)); 
    toc
    fprintf('\n');
    
    % create bucketed data cube if this run option is enabled
    if pmFeatureParams.bucketfeat(rp) == 2
        tic
        fprintf('Creating bucketed data\n');
        [pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpNormcube, pmFeatureParams.nbuckets(rp), npatients, maxdays, nmeasures); 
        toc
        fprintf('\n');
    else
        pmBucketedcube = [];
    end
    
    % create feature/label examples from the data
    % need to add setting and using of the measures mask
    tic
    fprintf('Creating Features and Labels\n');
    [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmExLabels] = createFeaturesAndLabelsFcn(pmPatients, ...
        pmAntibiotics, pmAMPred, pmInterpDatacube, pmInterpNormcube, pmBucketedcube, ...
        nmeasures, npatients, maxdays, maxfeatureduration, pmFeatureParams(rp,:));
    toc
    fprintf('\n');
    
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
        'pmRawDatacube', 'pmInterpDatacube', 'maxdays', ...
        'measures', 'nmeasures', 'ntilepoints'...
        'pmFeatureParams', 'rp', 'pmInterpNormcube', 'pmBucketedcube', ...
        'pmFeatureIndex', 'pmFeatures', 'pmNormFeatures', ...
        'pmIVLabels', 'pmExLabels');
    toc
    fprintf('\n');
end
