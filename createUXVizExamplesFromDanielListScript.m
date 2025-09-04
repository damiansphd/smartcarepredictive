clear; close all; clc;

basedir = setBaseDir();
mlsubfolder = 'MatlabSavedVariables';
dfsubfolder = 'DataFiles';

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
        ~, ~, ~, ~, ~, ~, ~] = loadAndHarmoniseClinVars(clinicalmatfile, mlsubfolder, study);
[physdata, acoffset, ~] = loadAndHarmoniseMeasVars(datamatfile, mlsubfolder, study);
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat',study);
fprintf('Loading model input data\n');
load(fullfile(basedir, mlsubfolder, modelinputsmatfile), 'pmPatients');
fprintf('\n');

%pmPatMerge = innerjoin(pmPatients, cdPatient, 'LeftKeys', {'ID'}, 'RightKeys', {'ID'}, 'RightVariables', {'StudyNumber', 'StudyNumber2', 'StudyEmail', 'Cohort'});

% **** update the file name here ****
inputfile = 'Input-DanielList 20250113.xlsx';

dlopts = detectImportOptions(fullfile(basedir, dfsubfolder, inputfile));
inputtable  = readtable(fullfile(basedir, dfsubfolder, inputfile));
nuxexs = size(inputtable,1);

% ***** check the columns in the input file - in the Study ID column, Daniel
% sometimes includes StudyNumber2, and also the Study Number field ****
% current columns selected work for the 20240913 version of the example
% list

if sum(~ismember(inputtable.StudyID, cdPatient.StudyNumber2)) > 0
    fprintf("Patients in Daniel List not found in Clinical Data\n");
    inputtable(~ismember(inputtable.StudyID, cdPatient.StudyNumber2),:)
end

pmPatMerge = innerjoin(inputtable, cdPatient,  'LeftKeys', {'StudyID'}, 'RightKeys', {'StudyNumber2'}, ...
        'LeftVariables', {'Start', 'End'}, 'RightVariables', {'ID', 'Hospital', 'StudyNumber', 'StudyNumber2', 'StudyDate', 'StudyEmail', 'Cohort'});

if sum(~ismember(pmPatMerge.ID, pmPatients.ID)) > 0
    fprintf("Patients in Daniel List who have entered no data)\n");
    inputtable(~ismember(pmPatMerge.ID, pmPatients.ID),:)
end

pmPatMerge = innerjoin(pmPatMerge, pmPatients, 'LeftKeys', {'ID'}, 'RightKeys', {'ID'}, 'RightVariables', ...
        {'Study', 'PatientNbr', 'FirstMeasDate', 'LastMeasDate', 'StudyStartdn', 'FirstMeasdn', 'LastMeasdn'});



nrows = size(pmPatMerge, 1);

% create table to hold breathe scores
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
pmUXVizExamples.FromRelDn    = max(datenum(pmPatMerge.Start), datenum(pmPatMerge.FirstMeasDate)) - datenum(pmPatMerge.FirstMeasDate) + 1;
pmUXVizExamples.ToRelDn      = min(datenum(pmPatMerge.End), datenum(pmPatMerge.LastMeasDate)) - datenum(pmPatMerge.FirstMeasDate) + 1;
pmUXVizExamples.Period       = pmUXVizExamples.ToRelDn - pmUXVizExamples.FromRelDn + 1;
for i = 1:nrows
    pmUXVizExamples.Description{i}  = sprintf('%s/%d/%s/%s/%s', pmUXVizExamples.Hospital{i}, ...
    pmUXVizExamples.PatientID(i), pmUXVizExamples.StudyNumber{i}, pmUXVizExamples.StudyNumber2{i}, pmUXVizExamples.Cohort{i});
end

if sum(pmUXVizExamples.Period <= 0) > 0
    fprintf("Patients in Daniel List who have no data in the requested time window\n");
    pmUXVizExamples(pmUXVizExamples.Period <= 0, {'StudyNumber2' , 'StudyEmail'})
end

pmUXVizExamples(pmUXVizExamples.Period <= 0, :) = [];

% save results - matlab archive and excel
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('UXViz-%s-DanielList.mat', study);
fprintf('Saving UXViz examples to matlab file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'pmUXVizExamples');

subfolder = 'ExcelFiles';
outputfilename = sprintf('UXViz-%s-DanielList.xlsx', study);
fprintf('Saving UXViz examples to excel file %s\n', outputfilename);
writetable(pmUXVizExamples, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'pmUXVizExamples');
toc

