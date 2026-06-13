clear; close all; clc;

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';

tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

[studynbr, studydisplayname, pmStudyInfo] = selectStudy();
nstudies = size(pmStudyInfo,1);

if nstudies > 1
    fprintf('**** This function is only designed to work with a single study ****\n');
    return
end

study = pmStudyInfo.Study{1};
tic
% load cdPatient, pmPatients and study offset info to get mapping between PartitionKey and Patient Info
[datamatfile, clinicalmatfile, ~] = getRawDataFilenamesForStudy(study);
[cdPatient, ~, ~, ~, ~, ~, ~, ...
        ~, ~, ~, ~, ~, ~, ~] = loadAndHarmoniseClinVars(clinicalmatfile, subfolder, study);
[~, acoffset, ~] = loadAndHarmoniseMeasVars(datamatfile, subfolder, study);
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat',study);
fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile), 'pmPatients');
fprintf('\n');

% create table to hold breathe scores
nrows = 0;
[pmSignal] = createSignalTable(nrows);
toc
fprintf('\n');

tic
% find all breathe score files
signaldir = 'Signal';
basesignalfilename = 'patient_';
rerundir = sprintf('%sRerun', study);

[signalfiles, nsignalfiles] = getSignalFiles(rerundir, signaldir, basesignalfilename);

fprintf('Starting ingestion of files\n');
fprintf('---------------------------\n');

% loop over file list, ingest each one
% note - there are sometimes multiple files per day - Pat has recommended
% always using the 11pm (ish) version but will check with Kirsty/Lucy and
% revert

for i = 1:nsignalfiles
    fprintf('%3d of %3d: Processing file %s\n', i, nsignalfiles, signalfiles{i});
    pmSignal = addSignalRowsFromRerunFile(study, signaldir, acoffset, signalfiles{i}, pmSignal, pmPatients, cdPatient);
end
toc
fprintf('\n');
fprintf('pmSignal table has %d rows\n', size(pmSignal, 1));

% delete out rows with null scores for both predictive and safety
% classifiers
%delidx = isnan(pmSignal.PredScore) & isnan(pmSignal.SafetyScore);
%fprintf('Deleting %d rows with null scores for both classifiers\n', sum(delidx));
%pmSignal(delidx, :) = [];
%fprintf('pmSignal table now has %d rows\n', size(pmSignal, 1));
%fprintf('\n');

% sort data
pmSignal = sortrows(pmSignal, {'PatientNbr', 'RelCalcDatedn'});


% save results - matlab archive and excel
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%ssignalsrerun.mat', study);
fprintf('Saving signal data to matlab file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'studynbr', 'studydisplayname', ...
    'pmStudyInfo', 'pmSignal');

subfolder = 'ExcelFiles';
outputfilename = sprintf('%ssignalsrerun.xlsx', study);
fprintf('Saving signal data to excel file %s\n', outputfilename);
writetable(pmSignal, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'pmSignal');
toc

% analyse null results

prednullidx   = isnan(pmSignal.PredScore);
safenullidx   = isnan(pmSignal.SafetyScore);
bothnullidx   = isnan(pmSignal.PredScore) & isnan(pmSignal.SafetyScore);
eithernullidx = isnan(pmSignal.PredScore) | isnan(pmSignal.SafetyScore);

fprintf('Number of null pred classifier results   = %d\n', sum(prednullidx));
fprintf('Number of null safety classifier results = %d\n', sum(safenullidx));
fprintf('Number of null both classifier results   = %d\n', sum(bothnullidx));
fprintf('Number of null either classifier results = %d\n', sum(eithernullidx));

if (sum(bothnullidx) == sum(eithernullidx))
    fprintf('All null results are for both classifiers\n');
else
    fprintf('**** Some results have null for only one classifier - investigate ****\n');
end


