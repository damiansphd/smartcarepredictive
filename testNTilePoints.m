clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
featureparamfile = selectFeatureParameters();
featureparamfile = strcat(featureparamfile, '.xlsx');

pmThisFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

maxfeatureduration = max(pmThisFeatureParams.featureduration);

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fbasefilename = generateFileNameFromFeatureParams(pmThisFeatureParams(1,:));
featureinputmatfile = sprintf('%s.mat',fbasefilename);
fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
load(fullfile(basedir, subfolder, featureinputmatfile));

if pmThisFeatureParams.bucketfeat(1) == 2
    fprintf('Creating bucketed data\n');
    [pmBucketedcube, ntilepoints] = createPMBucketedcube(pmInterpNormcube, pmThisFeatureParams.nbuckets(1), npatients, maxdays, nmeasures); 
else
    pmBucketedcube = [];
end