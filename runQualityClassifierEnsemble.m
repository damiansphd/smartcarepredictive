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
filetext = ' QCDataset';

[baseqcinputfile] = selectQCInputFile(fv1, lb1, rm1, filetext);
qcresultsfile = sprintf('%s.mat', baseqcinputfile);
baseqcinputfile = strrep(baseqcinputfile, filetext, '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading qualiy classifier input data for %s\n', qcresultsfile);
load(fullfile(basedir, subfolder, qcresultsfile), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', 'measures', 'nmeasures');

if pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern classifier only works on fully interpolated data\n');
    return
end
nfeatureparamsets = 1;

[basemodelparamfile, ~, ~, validresponse] = selectModelRunParameters();
if validresponse == 0
    return;
end
subfolder = 'DataFiles';
modelparamfile    = strcat(basemodelparamfile, '.xlsx');
pmModelParams     = readtable(fullfile(basedir, subfolder, modelparamfile));
nmodelparamsets   = 1;
ncombinations     = 1;

[basehpparamfile, ~, ~, validresponse] = selectHyperParameters();
if validresponse == 0
    return;
end
pmHyperParams        = readtable(fullfile(basedir, subfolder, strcat(basehpparamfile, '.xlsx')));
[lrarray, ntrarray, mlsarray, mnsarray, fvsarray, nlr, ntr, nmls, nmns, nfvs, hpsuffix] = setHyperParameterArrays(pmHyperParams);

[qsthreshold, validresponse] = selectThreshPercentage('Label', 0, 100);
if validresponse == 0
    return;
end

[fpthreshold, validresponse] = selectThreshPercentage('False Positive', 0, qsthreshold);
if validresponse == 0
    return;
end

% calculate labels for missingness dataset
qsmeasure = 'AvgEPV';
labels = setLabelsForMSDataset(pmMissPattQSPct, qsmeasure, qsthreshold/100);

lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time

nexamples = size(pmMissPattIndex, 1);

% create split index for held out test data and folds
qcsplitidx = createQCSplitIndex(pmMissPattIndex);

nnormfeatures = size(pmMissPattArray, 2);
datawin = pmFeatureParamsRow.datawinduration;

pmQCFeatNames = reshape(cellstr(cellstr('MS-' + string(measures.ShortName(logical(measures.MSMeas)))     + '-') + string(datawin:-1:1))', ...
                    [1 sum(measures.MSMeas)     * datawin]           );      

fs = 1;
mp = 1;

[modeltype, mmethod] = setModelTypeAndMethod(pmModelParams.ModelVer{mp});


nhpcomb      = nlr * ntr * nmls * nmns * nfvs;
%[hyperparamQS, foldhpTrQS, foldhpCVQS, foldhpTestQS] = createHpQSTables(nhpcomb, nqcfolds);

for lr = 1:nlr
    lrval = lrarray(lr);
    for tr = 1:ntr
        ntrval = ntrarray(tr);
        for mls = 1:nmls
            mlsval = mlsarray(mls);
            for mns = 1:nmns
                mnsval = mnsarray(mns);
                for fvs = 1:nfvs
                    fvsval = fvsarray(fvs);

                    tic
                    hpcomb = ((lr - 1) * ntr * nmls * nmns * nfvs) + ((tr - 1) * nmls * nmns * nfvs) + ((mls - 1) * nmns * nfvs) + ((mns - 1) * nfvs) + fvs;

                    fprintf('%2d of %2d Hyperparameter combinations\n', hpcomb, nhpcomb);

                    pmQCModelRes = createQCModelResStuct(nexamples, nqcfolds);

                    for fold = 1:nqcfolds

                        foldhpcomb = fold;

                        fprintf('Fold %d: ', fold);

                        [~, pmTrMPArray, ~, trlabels, ...
                         ~, pmCVMPArray, ~, cvlabels, cvidx] ...
                            = splitTrCVQCFeats(pmMissPattIndex, pmMissPattArray, pmMissPattQS, labels, qcsplitidx, fold); 

                        fprintf('Training...');
                        [pmQCModelRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmQCModelRes, pmTrMPArray, trlabels, ...
                                            pmQCFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                        fprintf('Done\n');

                        % calculate predictions and quality scores on training data
                        fprintf('Tr: ');
                        [~] = calcQCPredAndQS(pmQCModelRes.Folds(fold).Model, pmTrMPArray, trlabels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);

                        % calculate predictions and quality scores on cv data
                        fprintf('CV: ');
                        [pmCVRes] = calcQCPredAndQS(pmQCModelRes.Folds(fold).Model, pmCVMPArray, cvlabels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);

                        % also store results on overall model results structure
                        pmQCModelRes.Pred(cvidx) = pmCVRes.Pred;
                        pmQCModelRes.Loss(fold)  = pmCVRes.Loss;

                    end

                    fprintf('Overall:\n');
                    fprintf('CV: ');
                    fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
                    pmQCModelRes = calcModelQualityScores(pmQCModelRes, labels, nexamples);

                    fprintf('\n');

                    toc
                    fprintf('\n');
 
                end
            end
        end
    end
end

pmMPModelParamsRow   = pmModelParams(mp,:);
mpmodeltext = sprintf('mv%slm%d', pmMPModelParamsRow.ModelVer{1}, pmMPModelParamsRow.labelmethod);

pmMPHyperParamsRow              = struct();
pmMPHyperParamsRow.learnrate    = lrval;
pmMPHyperParamsRow.numtrees     = ntrval;
pmMPHyperParamsRow.minleafsize  = mlsval;
pmMPHyperParamsRow.maxnumsplits = mnsval;
pmMPHyperParamsRow.fracvarssamp = fvsval;
mphptext = sprintf('lr%.2fnt%dml%dns%dfv%.2f', pmMPHyperParamsRow.learnrate, pmMPHyperParamsRow.numtrees, ...
    pmMPHyperParamsRow.minleafsize, pmMPHyperParamsRow.maxnumsplits, pmMPHyperParamsRow.fracvarssamp);
                    
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
baseqcinputfile = sprintf('%s%s%sth%s%d', baseqcinputfile, mpmodeltext, mphptext, qsmeasure, qsthreshold);
outputfilename = sprintf('%sQCResults.mat', baseqcinputfile);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmQCModelRes', 'pmQCFeatNames', ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
    'labels', 'qcsplitidx', 'nexamples', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'measures', 'nmeasures', ...
    'qsmeasure', 'qsthreshold');
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/QC/%s', baseqcinputfile);
mkdir(fullfile(basedir, plotsubfolder));

% plot PR and ROC curves
plotQCPRAndROCCurves(pmQCModelRes, plotsubfolder, baseqcinputfile)

% plot calibration curve
calcAndPlotQCCalibration(pmQCModelRes, labels, pmMissPattIndex, nqcfolds, ...
    baseqcinputfile, plotsubfolder);

% plot QS vs Missingness
[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);
plotMissingnessQSFcn(pmQCModelRes, pmMissPattIndex, pmMissPattQSPct, labels, ...
    qsthreshold, fpthreshold, rocthresh, baseqcinputfile, plotsubfolder);

beep on;
beep;
