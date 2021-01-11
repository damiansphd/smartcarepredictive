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

filetext  = 'QCDataset';
batchsize = 1000;

[basemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading hyperparameters for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), 'pmHyperParamQS');
toc
fprintf('\n');

basemodelresultsfile = shortenQCFileName(basemodelresultsfile, pmHyperParamQS.HyperParamQS);
qcbaselinefile       = strrep(basemodelresultsfile, ' ModelResults', 'QCBaseline');
qcdatasetfile        = strrep(basemodelresultsfile, ' ModelResults', filetext);

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading baseline quality scores from file %s\n', qcbaselinefile);
load(fullfile(basedir, subfolder, sprintf('%s.mat', qcbaselinefile)), ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', 'measures', 'nmeasures');
toc
fprintf('\n');

if pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern classifier only works on fully interpolated data\n');
    return
end
nfeatureparamsets = 1;

[qcinputfiles, nbatchfiles] = getQCBatchInputFiles(qcdatasetfile, batchsize);
[pmMissPattIndex, pmMissPattArray, pmMissPattQS, pmMissPattQSPct] = concatenateQCInputBatchFiles(qcinputfiles, nbatchfiles);


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

[mpruntype, rtsuffix, validresponse] = selectRunMode();
if validresponse == 0
    return;
end

% calculate labels for missingness dataset
qsmeasure = 'AvgEPV';
fprintf('Label Threshold\n');
labels   = setLabelsForMSDataset(pmMissPattQSPct, qsmeasure, qsthreshold/100);
fprintf('Bad False Positive Threshold\n');
fplabels = setLabelsForMSDataset(pmMissPattQSPct, qsmeasure, fpthreshold/100);

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
                    
                    if mpruntype == 1

                        pmQCModelRes = createQCModelResStruct(nexamples, nqcfolds);

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

                        %pmQCModelRes = calcModelQualityScores(pmQCModelRes, labels, nexamples);
                        pmQCModelRes = calcQCModelQualityScores(pmQCModelRes, labels, fplabels, nexamples);

                        fprintf('Overall:\n');
                        fprintf('CV: ');
                        fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
                        fprintf('PR = %.3f%%, ROC = %.3f%%, Acc = %.3f%%, PosAcc = %.3f%%, NegAcc = %.3f%%\n', ...
                            pmQCModelRes.PRAUC, pmQCModelRes.ROCAUC, pmQCModelRes.Acc, pmQCModelRes.PosAcc, pmQCModelRes.NegAcc);
                        fprintf('CV: ');
                        fprintf('QCCost = %.6f, IdxOp = %d TPROp = %.3f%%, FPROp = %.3f%%, PrecOp = %.3f%%, RecallOp = %.3f%%\n', ...
                            pmQCModelRes.QCCostOp, pmQCModelRes.IdxOp, pmQCModelRes.TPROp, pmQCModelRes.FPROp, pmQCModelRes.PrecisionOp, pmQCModelRes.RecallOp);
                    
                    elseif mpruntype == 2
                        
                        pmQCModelRes = createQCModelResStruct(nexamples, 1);
                        fold = 1;
                        foldhpcomb = 1;
                        nqcfolds = 1;
                        fprintf('Training...');
                        [pmQCModelRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmQCModelRes, pmMissPattArray, labels, ...
                                            pmQCFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                        fprintf('Done\n');
                        % calculate predictions and quality scores on training data
                        % comment this out once checked this runtype works
                        % ok
                        fprintf('Tr: ');
                        [pmTrRes] = calcQCPredAndQS(pmQCModelRes.Folds(fold).Model, pmMissPattArray, labels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                            lrval, ntrval, mlsval, mnsval, fvsval);
                        pmQCModelRes.Pred       = pmTrRes.Pred;
                        pmQCModelRes.Loss(fold) = pmTrRes.Loss;
                        pmQCModelRes = calcQCModelQualityScores(pmQCModelRes, labels, fplabels, nexamples);
                        
                    else
                        fprintf('**** Unknown run type ****\n');
                    end
                    
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

pmMPOtherRunParams              = struct();
pmMPOtherRunParams.runtype      = mpruntype;
mpoptext = sprintf('rt%d', pmMPOtherRunParams.runtype);
                    
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
baseqcdatasetfile = strrep(qcdatasetfile, filetext, '');
baseqcdatasetfile = sprintf('%sne%d%s%s%sth%s%dfp%dcf%.4f', baseqcdatasetfile, nexamples, mpmodeltext, mphptext, mpoptext, qsmeasure, qsthreshold, fpthreshold, pmQCModelRes.QCCostOp);
outputfilename = sprintf('%sQCResults.mat', baseqcdatasetfile);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmQCModelRes', 'pmQCFeatNames', ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
    'labels', 'fplabels', 'qcsplitidx', 'nexamples', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', 'measures', 'nmeasures', ...
    'qsmeasure', 'qsthreshold', 'fpthreshold');
toc
fprintf('\n');


%if mpruntype == 1
    
    plotsubfolder = sprintf('Plots/QC/%s', baseqcdatasetfile);
    mkdir(fullfile(basedir, plotsubfolder));

    % plot PR and ROC curves
    plotQCPRAndROCCurves(pmQCModelRes, plotsubfolder, baseqcdatasetfile)

    % plot calibration curve
    calcAndPlotQCCalibration(pmQCModelRes, labels, pmMissPattIndex, nqcfolds, ...
        baseqcdatasetfile, plotsubfolder);

    % plot QS vs Missingness
    %[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);
    plotMissingnessQSFcn(pmQCModelRes, pmMissPattIndex, pmMissPattQSPct, labels, ...
        qsthreshold, fpthreshold, pmQCModelRes.PredOp, baseqcdatasetfile, plotsubfolder);

    plotMissQSByMeasFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
        qsthreshold, fpthreshold, pmQCModelRes.PredOp, measures, datawin, baseqcdatasetfile, plotsubfolder, 'AvgEPV');

    plotMissQSByOutcomeFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
        qsthreshold, fpthreshold, pmQCModelRes.PredOp, measures, datawin, baseqcdatasetfile, plotsubfolder, 'AvgEPV');

%end
    
beep on;
beep;
