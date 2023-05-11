clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

[studynbr, studyname, pmStudyInfo] = selectStudy();
nstudies = size(pmStudyInfo,1);

subfolder = 'MatlabSavedVariables';

modelinputsmatfile = sprintf('%s%s.mat', studyname, "predictivemodelinputs");
fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));

excelfolder = 'ExcelFiles';
mfilename = 'PredModPreProcData.xlsx';
fprintf('Saving input variables to excel file %s\n', mfilename);
writetable(pmPatients, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'pmPatients');
writetable(pmAntibiotics, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'pmAntibiotics');
writetable(pmAMPred, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'pmAMPred');
writetable(pmOverallStats, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'pmOverallStats');
writetable(pmPatientMeasStats, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'pmPatientMeasStats');

