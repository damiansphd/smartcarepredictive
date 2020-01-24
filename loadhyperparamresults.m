clear; close all; clc;

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
[basemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, ' ModelResults', '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile));

tic
% save hyperparameter quality scores table
basedir = setBaseDir();
subfolder = 'ExcelFiles';
hpfilename = sprintf('%s HyperParamResults.xlsx', basemodelresultsfile);
fprintf('Saving hyperparameter quality scores results to excel file %s\n', hpfilename);
writetable(pmHyperParamQS.HyperParamQS, fullfile(basedir, subfolder, hpfilename), 'Sheet', 'HyperParamQS');
toc



%view(Ens.Trained{t})
