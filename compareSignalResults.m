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
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat',study);
fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile), 'pmPatients');
fprintf('\n');

% load original signal results
origfilename = sprintf('%ssignals.mat', study);
fprintf('Loading original signal data from matlab file %s\n', origfilename);
load(fullfile(basedir, subfolder, origfilename), 'pmSignal');
pmSignalOrig = pmSignal;

% load original signal results
rerunfilename = sprintf('%ssignalsrerun.mat', study);
fprintf('Loading rerun signal data from matlab file %s\n', rerunfilename);
load(fullfile(basedir, subfolder, rerunfilename), 'pmSignal');
pmSignalRerun = pmSignal;

pmSignalJoin = outerjoin(pmSignalRerun, pmSignalOrig, 'Type', 'left', 'LeftKeys', {'PatientNbr', 'RelCalcDatedn'}, ...
        'RightKeys', {'PatientNbr', 'RelCalcDatedn'}, 'RightVariables', {'PredScore', 'SafetyScore', 'SignalState'});

diffpredidx = abs(pmSignalJoin.PredScore_pmSignalRerun - pmSignalJoin.PredScore_pmSignalOrig) > 0.001;
fprintf ('There are %d different prediction scores between original and rerun files\n', sum(diffpredidx));
writetable(pmSignalJoin(diffpredidx, :), fullfile(basedir, 'ExcelFiles', 'Signal Differences.xlsx'), 'Sheet', 'Diff PredScore');

diffsafeidx = abs(pmSignalJoin.SafetyScore_pmSignalRerun - pmSignalJoin.SafetyScore_pmSignalOrig) > 0.001;
fprintf ('There are %d different safety scores between original and rerun files\n', sum(diffsafeidx));
writetable(pmSignalJoin(diffsafeidx, :), fullfile(basedir, 'ExcelFiles', 'Signal Differences.xlsx'), 'Sheet', 'Diff SafetyScore');

blanksignalrerunidx = ~ismember(pmSignalJoin.SignalState_pmSignalRerun, {'White', 'Red', 'Amber', 'Green'});
fprintf ('There are %d blank signal states in the Rerun files\n', sum(blanksignalrerunidx));
writetable(pmSignalJoin(blanksignalrerunidx, :), fullfile(basedir, 'ExcelFiles', 'Signal Differences.xlsx'), 'Sheet', 'Blank SignalState - Rerun');

blanksignalorigidx = ~ismember(pmSignalJoin.SignalState_pmSignalOrig, {'White', 'Red', 'Amber', 'Green'});
fprintf ('There are %d blank signal states in the Original files\n', sum(blanksignalorigidx));
writetable(pmSignalJoin(blanksignalorigidx, :), fullfile(basedir, 'ExcelFiles', 'Signal Differences.xlsx'), 'Sheet', 'Blank SignalState - Orig');

temprerun = pmSignalJoin.SignalState_pmSignalRerun;
temporig = pmSignalJoin.SignalState_pmSignalOrig;
diffsignalidx = ~strcmp(temprerun, temporig);

diffsignalnotblankidx = diffsignalidx & ~blanksignalrerunidx & ~blanksignalorigidx;
fprintf ('There are %d different signal states between original and rerun files (excluding blanks)\n', sum(diffsignalnotblankidx));
writetable(pmSignalJoin(diffsignalnotblankidx, :), fullfile(basedir, 'ExcelFiles', 'Signal Differences.xlsx'), 'Sheet', 'Diff SignalState');




