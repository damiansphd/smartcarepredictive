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

pmPatMerge = innerjoin(pmPatients, cdPatient, 'LeftKeys', {'ID'}, 'RightKeys', {'ID'}, 'RightVariables', {'StudyNumber', 'StudyNumber2', 'StudyEmail', 'Cohort'});

% create table to hold breathe scores
nrows = size(pmPatients, 1);
[pmUXVizExamples] = createUXVizTable(nrows);
toc
fprintf('\n');

% fill in logic to populate the table
pmUXVizExamples.Study        = pmPatMerge.Study;
pmUXVizExamples.Hospital     = pmPatMerge.Hospital;
pmUXVizExamples.PatientNbr   = pmPatMerge.PatientNbr;
pmUXVizExamples.PatientID    = pmPatMerge.ID;
pmUXVizExamples.StudyNumber  = pmPatMerge.StudyNumber;
pmUXVizExamples.StudyNumber2 = pmPatMerge.StudyNumber2;
pmUXVizExamples.StudyEmail   = pmPatMerge.StudyEmail;
pmUXVizExamples.Cohort       = pmPatMerge.Cohort;
pmUXVizExamples.FromRelDn    = pmPatMerge.RelFirstMeasdn;
pmUXVizExamples.ToRelDn      = pmPatMerge.RelLastMeasdn;
pmUXVizExamples.Period       = pmUXVizExamples.ToRelDn - pmUXVizExamples.FromRelDn + 1;
for i = 1:nrows
    pmUXVizExamples.Description{i}  = sprintf('%s/%d/%s/%s/%s', pmUXVizExamples.Hospital{i}, ...
            pmUXVizExamples.PatientID(i), pmUXVizExamples.StudyNumber{i}, pmUXVizExamples.StudyNumber2{i}, pmUXVizExamples.Cohort{i});
end

pmUXVizExamples(pmUXVizExamples.Period < 50, :) = [];

% save results - matlab archive and excel
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('UXViz-%s-AllParticipants.mat', study);
fprintf('Saving UXViz examples to matlab file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'pmUXVizExamples');

subfolder = 'ExcelFiles';
outputfilename = sprintf('UXViz-%s-AllParticipants.xlsx', study);
fprintf('Saving UXViz examples to excel file %s\n', outputfilename);
writetable(pmUXVizExamples, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'pmUXVizExamples');
toc

