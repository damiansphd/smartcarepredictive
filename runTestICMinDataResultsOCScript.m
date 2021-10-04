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

fprintf('Select Inner (Predictive) Classifier Min Data Rules results file\n');
typetext = 'QCDRResultsICNew';
[baseqcdrresfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcdrresfile = sprintf('%s.mat', baseqcdrresfile);
baseqcdrresfile = strrep(baseqcdrresfile, typetext, '');

fprintf('Select Outer (Quality) Classifier model results file\n');
typetext = 'QCResults';
[basemodelresultsfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, typetext, '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading Inner (Predictive) Classifier Min Data Rules results for %s\n', qcdrresfile);
load(fullfile(basedir, subfolder, qcdrresfile), ...
    'pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmQSConstr');
toc
fprintf('\n');

qcdrindex      = pmQCDRIndex(idx, :);
qcdrmp3D       = pmQCDRMissPatt(idx, :, :);
qcdrdw3D       = pmQCDRDataWin(idx, :, :);
qcdrfeats      = pmQCDRFeatures(idx, :);
qcdrcyclicpred = pmQCDRCyclicPred(idx, :);
clear('pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred');

% load trained quality classifier
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading quality classifier results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
        'pmQCModelRes', 'pmQCFeatNames', 'nqcfolds', ...
        'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams');
toc
fprintf('\n');

% choose the operating threshold for the quality classifier
[qcopthres, validresponse] = selectFromArrayByIndex('Operating Threshold', [pmQCModelRes.PredOp; 0.6; 0.7; 0.8; 0.9; 0.95]);
if validresponse == 0
    return;
end

fprintf('\n');
fprintf('Checking the minimum data pattern from the inner (predictive) classifier\n');
fprintf('\n');
printMissPattFcn(qcdrindex, qcdrmp3D, qcdrmeasures, nrawmeas, mpdur);

[qcdrindex, qcdrmp3D, qcdrdw3D, qcdrfeats, qcdrcyclicpred] = ...
            calcCyclicPredsForMP(pmQCModelRes, pmMPModelParamsRow.ModelVer, ...
                    qcdrindex, qcdrmp3D, qcdrdw3D, qcdrfeats, qcdrcyclicpred, ...
                    qcdrindex, qcdrmp3D, mpdur, dwdur, nrawmeas, cyclicdur, iscyclic, qcopthres);

fprintf('Min cyclic Outer (Quality) classifier predicted: %.2f%%\n', 100 * qcdrindex.SelPred(2));
fprintf('All cyclic preds: ');
fprintf('%.4f%% ', 100 * qcdrcyclicpred(2, :));
fprintf('\n');
fprintf('At operating threshold %.2f, the Outer (Quality) classifier would predict ', qcopthres);
if qcdrindex.MoveAccepted
    fprintf('SAFE');
else
    fprintf('NOT SAFE');
end
fprintf('\n');
fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%sqot%.2f%s.mat', baseqcdrresfile, qcopthres, 'TestQCDRResICNew');
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'qcdrindex', 'qcdrmp3D', 'qcdrdw3D', 'qcdrfeats', 'qcdrcyclicpred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmQCModelRes', 'pmQCFeatNames', 'nqcfolds', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
    'pmQSConstr', 'qcopthres');
toc
fprintf('\n');

