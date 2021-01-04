clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

% logic to load in results for a given feature&label version, label method and raw measures combination
[fv1, validresponse] = selectFeatVer();
if validresponse == 0
    return;
end
[lb1, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
[rm1, validresponse] = selectRawMeasComb();
if validresponse == 0
    return;
end
typetext = 'QCResults';
[basemodelresultsfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, typetext, '');

% load trained quality classifier
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading quality classifier results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
        'pmQCModelRes', 'pmQCFeatNames', ...
        'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
        'labels', 'qcsplitidx', 'nexamples', ...
        'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
        'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
        'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'measures', 'nmeasures', 'qsmeasure', 'qsthreshold', 'fpthreshold');

toc
fprintf('\n');

datawin = pmFeatureParamsRow.datawinduration;
weekwin = 7;
nrawmeasures = sum(measures.RawMeas);

% 1) Pick a starting pattern e.g. no missingness, or a true positive.
%       a. The pattern will be 25-days for non-cycling or 7-days for cycling on a weekly period.
[pmQCDRIndex, pmQCDRArray, ~, ~] = createDWMissPattTables(1, nrawmeasures, pmFeatureParamsRow.datawinduration);

% 2) Consider all possible moves from that pattern - each gives a new pattern.  Optionally, remove cyclic duplicates.
%		a. You can define the moves - a simple move is flip one point from observed to missing.
%       b. Other possible moves would be to flip a point from missing to observed, or a shift (left or right) of a missing point 

% 3) For each new pattern, determine if it is green.
%		a. In the cyclic case, you will need to ensure all days are green by taking 25-day windows of the 7-day pattern repeating.

% 4) For green moves, pick the 'best' according to some metric and go back to step 1.
%		a. In the cyclic case, this could be the move which gives the least worst score.

% 5) If no green moves, stop and output the pattern.

% 6) Repeat from different starting patterns.

