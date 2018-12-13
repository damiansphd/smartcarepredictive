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
    
    % pre-process to remove unwanted measures and data and set which
    % features are to be bucketed.
    
    tic
    [measures, nmeasures, pmOverallStats, pmPatientMeasStats, ...
        pmRawDatacube, pmInterpDatacube] = preprocessMeasuresMask(measures, ...
        nmeasures, pmOverallStats, pmPatientMeasStats, pmRawDatacube, ...
        pmInterpDatacube, pmFeatureParams(rp, :));
    toc
    fprintf('\n');

    % create normalised data cube
    tic
    fprintf('Normalising data\n');
    [pmInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, pmOverallStats, pmPatientMeasStats, ...
        npatients, maxdays, nmeasures, pmFeatureParams.normmethod(rp), pmFeatureParams.smoothingmethod(rp)); 
    toc
    fprintf('\n');
    
    % create volatility measures cube
    tic
    fprintf('Creating volatility cube\n');
    [pmInterpVolcube, mvolstats] = createPMInterpVolcube(pmPatients, pmInterpNormcube, ...
        npatients, maxdays, nmeasures); 
    toc
    fprintf('\n');
    
    % create bucketed data cube if this run option is enabled
    tic
    fprintf('Creating bucketed data\n');
    [pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpNormcube, pmFeatureParams.nbuckets(rp), npatients, maxdays, nmeasures); 
    toc
    fprintf('\n');
    
    % create feature/label examples from the data
    % need to add setting and using of the measures mask
    tic
    fprintf('Creating Features and Labels\n');
    [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels] = createFeaturesAndLabelsFcn(pmPatients, ...
        pmAntibiotics, pmAMPred, pmInterpDatacube, pmInterpNormcube, pmBucketedcube, ...
        measures, nmeasures, npatients, maxdays, maxfeatureduration, pmFeatureParams(rp,:));
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
        'measures', 'nmeasures', 'ntilepoints', ...
        'pmFeatureParams', 'rp', 'pmInterpNormcube', 'pmBucketedcube', ...
        'pmInterpVolcube', 'mvolstats', ...
        'pmFeatureIndex', 'pmFeatures', 'pmNormFeatures', ...
        'pmIVLabels', 'pmABLabels', 'pmExLabels', 'pmExLBLabels');
    toc
    fprintf('\n');
end

beep on;
beep;

