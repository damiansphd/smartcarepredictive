clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
featureparamfile = selectFeatureParameters();
featureparamfile = strcat(featureparamfile, '.xlsx');

pmFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

maxfeatureduration = max(pmFeatureParams.featureduration);
maxnormwindow      = max(pmFeatureParams.normwindow);

fprintf('Creating Feature and Label files for %2d permutations of parameters\n', size(pmFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmFeatureParams,1)
    featureparamsrow = pmFeatureParams(rp,:);
    outputfilename = generateFileNameFromFullFeatureParams(featureparamsrow);
    fprintf('%2d. Generating features and labels for %s\n', rp, outputfilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % load model inputs
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    basefeatfile = generateFileNameFromBaseFeatureParams(featureparamsrow);
    fprintf('Loading base feature and label data: %s\n', basefeatfile);
    load(fullfile(basedir, subfolder, strcat(basefeatfile, '.mat')));
    toc
    fprintf('\n');
    
    % set various variables
    [featureduration, predictionduration, datefeat, nbuckets, navgseg, nvolseg, nbuckpmeas, ...
          nrawfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
          nvolsegfeatures, ncchangefeatures, npmeanfeatures, npstdfeatures, ...
          nbuckpmeanfeatures, nbuckpstdfeatures, ndatefeatures, ndemofeatures] = ...
            setBaseNumMeasAndFeatures(featureparamsrow, nmeasures);
    
    % set measures masks for the particular feature combination requested
    tic
    fprintf('Setting measures masks for features\n');
    [measures] = preprocessMeasuresMask(measures, nmeasures, featureparamsrow);
    toc
    fprintf('\n');
    
    tic
    fprintf('Extracting relevant features for measures\n');
    rawmeasmask    = logical(duplicateMeasuresByFeatures(measures.RawMeas', featureduration, nmeasures));
    bucketmeasmask = logical(duplicateMeasuresByFeatures(measures.BucketMeas', featureduration * nbuckets, nmeasures));
    rangemask      = logical(measures.Range');
    volmask        = logical(duplicateMeasuresByFeatures(measures.Volatility', (featureduration - 1), nmeasures));
    avgsegmask     = logical(duplicateMeasuresByFeatures(measures.AvgSeg', navgseg, nmeasures));
    volsegmask     = logical(duplicateMeasuresByFeatures(measures.VolSeg', nvolseg, nmeasures));
    cchangemask    = logical(measures.CChange');
    pmeanmask      = logical(measures.PMean');
    pstdmask       = logical(measures.PStd');
    buckpmeanmask  = logical(duplicateMeasuresByFeatures(measures.BuckPMean', nbuckpmeas, nmeasures));
    buckpstdmask   = logical(duplicateMeasuresByFeatures(measures.BuckPStd', nbuckpmeas, nmeasures));
    
    ndatefeats = size(pmDateFeats,2);
    if featureparamsrow.datefeat == 0
        datemask = false(1, ndatefeats);
    else
        datemask = true(1, ndatefeats);
    end
    
    ndemofeats = size(pmDemoFeats,2);
    if featureparamsrow.demofeat == 1
        demomask = false(1, ndemofeats);
    elseif featureparamsrow.demofeat == 2
        demomask = true(1, ndemofeats);
    else
        demomask = false(1, ndemofeats);
        demomask(featureparamsrow.demofeat - 2) = true;
    end
    
    pmNormFeatures = [pmRawMeasFeats(:, rawmeasmask), ...
                      pmBuckMeasFeats(:, bucketmeasmask), ...
                      pmRangeFeats(:, rangemask), ...
                      pmVolFeats(:, volmask), ...
                      pmAvgSegFeats(:, avgsegmask), ...
                      pmVolSegFeats(:, volsegmask), ...
                      pmCChangeFeats(:, cchangemask), ...
                      pmPMeanFeats(:, pmeanmask), ...
                      pmPStdFeats(:, pstdmask), ...
                      pmBuckPMeanFeats(:, buckpmeanmask), ...
                      pmBuckPStdFeats(:, buckpstdmask), ...
                      pmDateFeats(:, datemask), ...
                      pmDemoFeats(:, demomask)];
    toc
    
    % save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%s.mat',outputfilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', ...
        'pmRawDatacube', 'pmInterpDatacube',  ...
        'maxdays', 'measures', 'nmeasures', 'ntilepoints', ...
        'pmFeatureParams', 'rp', ...
        'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
        'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
        'pmBucketedcube', 'pmInterpVolcube', 'mvolstats', 'pmInterpSegVolcube', ...
        'pmInterpRangecube', 'pmInterpSegAvgcube', ...
        'pmFeatureIndex', 'pmMuIndex', 'pmSigmaIndex', ...
        'pmRawMeasFeats', 'pmBuckMeasFeats', 'pmRangeFeats', 'pmVolFeats', 'pmCChangeFeats', ...
        'pmPMeanFeats', 'pmBuckPMeanFeats', 'pmDateFeats', 'pmDemoFeats', ...
        'pmNormFeatures', ...
        'pmIVLabels', 'pmABLabels', 'pmExLabels', 'pmExLBLabels', 'pmExABLabels');
    toc
    fprintf('\n');
end

beep on;
beep;

