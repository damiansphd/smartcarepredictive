clear; close all; clc;

[studynbr, studydisplayname, pmStudyInfo] = selectStudy();
nstudies = size(pmStudyInfo,1);

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';

tic
fprintf('Creating Measures table\n');
[measures, nmeasures] = createMeasuresTable(pmStudyInfo, nstudies, basedir, subfolder);
toc
fprintf('\n');

tic
fprintf('Creating Raw Datacube\n');
[pmStudyInfo, pmPatients, pmAntibiotics, pmAMPred, pmRawDatacube, npatients, maxdays] = createPMRawDatacube(pmStudyInfo, measures, nmeasures, nstudies, basedir, subfolder);
toc
fprintf('\n');

% calculate measurement stats (overall and by patient)
tic
fprintf('Calculating measurement stats (overall and by patient\n');
[pmOverallStats, pmPatientMeasStats] = calcMeasurementStats(pmRawDatacube, pmPatients, measures, npatients, maxdays, nmeasures, studydisplayname);
toc
fprintf('\n');

% interpolate missing data
tic
fprintf('Interpolating missing data\n');
[pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures); 
toc
fprintf('\n');

% handle missing features (eg no sleep measures for a given patient)
tic
fprintf('Handling missing features\n');
[pmInterpDatacube] = handleMissingFeatures(pmPatients, pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures); 
toc
fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%spredictivemodelinputs.mat', studydisplayname);
fprintf('Saving output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'studynbr', 'studydisplayname', 'pmStudyInfo', ...
    'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
    'pmOverallStats', 'pmPatientMeasStats', ...
    'pmRawDatacube', 'pmInterpDatacube', 'maxdays', ...
    'measures', 'nmeasures');
toc