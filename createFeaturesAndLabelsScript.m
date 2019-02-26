clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
featureparamfile = selectFeatureParameters();
featureparamfile = strcat(featureparamfile, '.xlsx');

pmFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

maxfeatureduration = max(pmFeatureParams.featureduration);

fprintf('Creating Feature and Label files for %2d permutations of parameters\n', size(pmFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmFeatureParams,1)
    basefilename = generateFileNameFromFeatureParams(pmFeatureParams(rp,:));
    fprintf('%2d. Generating features and lables for %s\n', rp, basefilename);
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
    [measures] = preprocessMeasuresMask(measures, nmeasures, pmFeatureParams(rp, :));
    toc
    fprintf('\n');

    % create normalised data cube
    tic
    fprintf('Normalising data\n');
    [pmInterpNormcube, pmSmoothInterpNormcube] = createPMInterpNormcube(pmInterpDatacube, ...
        pmPatients, pmOverallStats, pmPatientMeasStats, npatients, maxdays, measures, nmeasures, ...
        pmFeatureParams.normmethod(rp), pmFeatureParams.smfunction(rp), pmFeatureParams.smwindow(rp), pmFeatureParams.smlength(rp)); 
    toc
    fprintf('\n');
    
    % create measures volatility cube
    tic
    fprintf('Creating volatility and segment volatility cubes\n');
    [pmInterpVolcube, mvolstats, pmInterpSegVolcube] = createPMInterpVolcube(pmPatients, pmInterpNormcube, ...
        npatients, maxdays, nmeasures, pmFeatureParams.featureduration(rp), pmFeatureParams.nvolseg(rp)); 
    toc
    fprintf('\n');
    
    % create measures range cube
    tic
    fprintf('Creating range and segment average measure cubes\n');
    [pmInterpRangecube, pmInterpSegAvgcube] = createPMInterpRangecube(pmPatients, pmInterpNormcube, ...
        npatients, maxdays, nmeasures, pmFeatureParams.featureduration(rp), pmFeatureParams.navgseg(rp)); 
    toc
    fprintf('\n');
    
    if pmFeatureParams.smfunction(rp) > 0
        pmInterpNormcube = pmSmoothInterpNormcube;
    end
    
    % create bucketed data cube
    tic
    fprintf('Creating bucketed data\n');
    [pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpNormcube, pmFeatureParams.nbuckets(rp), npatients, maxdays, nmeasures); 
    toc
    fprintf('\n');
    
    % create feature/label examples from the data
    % need to add setting and using of the measures mask
    tic
    fprintf('Creating Features and Labels\n');
    [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels] ...
        = createFeaturesAndLabelsFcn(pmPatients, ...
        pmAntibiotics, pmAMPred, pmInterpDatacube, pmInterpNormcube, pmInterpVolcube, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ...
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
        'pmInterpVolcube', 'mvolstats', 'pmInterpSegVolcube', ...
        'pmInterpRangecube', 'pmInterpSegAvgcube', ...
        'pmFeatureIndex', 'pmFeatures', 'pmNormFeatures', ...
        'pmIVLabels', 'pmABLabels', 'pmExLabels', 'pmExLBLabels', 'pmExABLabels');
    toc
    fprintf('\n');
end

beep on;
beep;

