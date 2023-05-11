clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

[studynbr, studydisplayname, pmStudyInfo] = selectStudy();
nstudies = size(pmStudyInfo,1);

subfolder = 'MatlabSavedVariables';

a=1;
fprintf('Processing study %s\n', pmStudyInfo.StudyName{a});
study = pmStudyInfo.Study{a};
[datamatfile, clinicalmatfile, ~] = getRawDataFilenamesForStudy(study);
[physdata, offset] = loadAndHarmoniseMeasVars(datamatfile, subfolder, study);
[cdPatient, ~, ~, cdAntibiotics, ~, ~, ~, ...
    ~, ~, ~, ~, ~, ~, ~] = loadAndHarmoniseClinVars(clinicalmatfile, subfolder, study);

fprintf('Loading alignment model prediction results\n');
load(fullfile(basedir, subfolder, pmStudyInfo.AMPredMatFile{a}), 'amInterventions', 'ex_start');

% convert offset variable to a table
offsettable = array2table(offset);

excelfolder = 'ExcelFiles';
mfilename = 'PredModInputData.xlsx';
fprintf('Saving input variables to excel file %s\n', mfilename);
writetable(physdata, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'BRphysdata');
writetable(offsettable, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'offset');
writetable(cdPatient, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'brPatient');
writetable(cdAntibiotics, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'brAntibiotics');
writetable(amInterventions, fullfile(basedir, excelfolder, mfilename), 'Sheet', 'amInterventions');




        