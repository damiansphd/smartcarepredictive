clear; close all; clc;

[studynbr, studydisplayname, pmStudyInfo] = selectStudy();
nstudies = size(pmStudyInfo,1);

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
featureduration = 20;
predictionduration = 15;

tic
fprintf('Creating Measures table\n');
[measures, nmeasures] = createMeasuresTable(pmStudyInfo, nstudies, basedir, subfolder);
toc
fprintf('\n');

tic
fprintf('Creating Raw Datacube\n');
[pmStudyInfo, pmPatients, pmAntibiotics, pmRawDatacube, npatients, maxdays] = createPMRawDatacube(pmStudyInfo, measures, nmeasures, nstudies, basedir, subfolder);
toc
fprintf('\n');

% remove Temperature measure and associated data due to insufficient data
idx = ismember(measures.DisplayName, {'Temperature'});
pmRawDatacube(:,:,measures.Index(idx)) = [];
measures(idx,:) = [];
nmeasures = size(measures,1);
measures.Index = [1:nmeasures]';

% interpolate missing data
% for gaps more than  x days, set mask to skip this day from creating a
% feature/label example
tic
fprintf('Interpolating missing data\n');
[pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures); 
toc
fprintf('\n');

% create feature/label examples from the data
% need to add setting and using of the measures mask
tic
fprintf('Creating Features and Labels\n');
[pmFeatureIndex, pmFeatures, pmLabels] = createFeaturesAndLabels(pmStudyInfo, pmPatients, pmAntibiotics, ...
    pmRawDatacube, measures, nmeasures, npatients, maxdays, featureduration, predictionduration);
toc
fprintf('\n');

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%spredictivemodelinputs.mat', studydisplayname);
fprintf('Saving output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'studynbr', 'studydisplayname', 'pmStudyInfo', ...
    'pmPatients', 'npatients', 'pmAntibiotics', ...
    'pmRawDatacube', 'pmInterpDatacube', 'maxdays', 'pmFeatureIndex', 'pmFeatures', 'pmLabels', ...
    'measures', 'nmeasures');
toc