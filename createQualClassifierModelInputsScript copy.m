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
[basemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
baseqcinputfile = strrep(basemodelresultsfile, ' ModelResults', 'QCDataset');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading trained predictive model and run parameters for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');

if pmFeatureParamsRow.interpmethod ~= 0 && pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern script only works on data with either no or full interpolation\n');
    return
end

pmModelByFold = pmModelRes.pmNDayRes.Folds;
clear('pmModelRes');

% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
if pmFeatureParamsRow.augmethod > 1
    findaugtext = sprintf('au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('au1');
    featureparamsfile = strrep(featureparamsfile, findaugtext, replaceaugtext);
end
featureparamsfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsfile), 'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

tic
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time
nqcfolds = 2; % number of folds for the nested cross validation for the quality classifier
%batchsize = 1000; % number of examples in each batch
basebatchsize = 10; % temporary small number to test logic

npcexamples = size(pmFeatureIndex, 1);
nrawmeasures = sum(measures.RawMeas);

[qcinputfiles, nbatchfiles] = getQCBatchInputFiles(baseqcinputfile);
if nbatchfiles > 0
    nlastbatch = getQCLastBatchFile(qcinputfiles, baseqcinputfile, nbatchfiles, basebatchsize);
else
    nlastbatch = 0;
end
[nbatchto, validresponse] = selectBatchNbr('finish', nlastbatch + 1, nlastbatch + 100);
if validresponse == 0
    return;
end
fprintf('\n');

if nlastbatch == 0 
    mpfrom = (nlastbatch * basebatchsize) + 1;
else
    mpfrom = (nlastbatch * basebatchsize) + nqcfolds + 1;
end
mpto   = (nbatchto   * basebatchsize) + nqcfolds;
nmptotal = mpto;
nmpthisrun = mpto - mpfrom + 1;
if nmptotal > npcexamples + nqcfolds
    nactmisspatts = npcexamples;
    nsynmisspatts = nmptotal - nactmisspatts - nqcfolds;
else
    nactmisspatts = nmptotal - nqcfolds;
    nsynmisspatts = 0;
end
fprintf('Running for batch size %d from batch %d to %d\n', basebatchsize, nlastbatch + 1, nbatchto);
fprintf('\n');

[pmMissPattIndexThisRun, ~, ~, ~] ... 
    = createDWMissPattTables(nmptotal, nrawmeasures, pmFeatureParamsRow.datawinduration);

rng(2);
[pmMissPattIndexThisRun] = createDWMissScenarios(pmMissPattIndexThisRun, npcexamples, nqcfolds, nactmisspatts, nsynmisspatts, mpfrom, mpto);

for ba = 1:(nbatchto - nlastbatch)
    
    thisbatch = nlastbatch + ba;
    if thisbatch == 1
        batchsize = basebatchsize + nqcfolds;
        offset    = 0;
    else
        batchsize = basebatchsize;
        offset    = nqcfolds;
    end
    
    % extract the relevant rows for this batch
    pmMissPattIndex = pmMissPattIndexThisRun(((ba - 1) * batchsize) + offset + 1:(ba * batchsize) + offset, :);
    [~, pmMissPattArray, pmMissPattQS, pmMissPattQSPct] = createDWMissPattTables(batchsize, nrawmeasures, pmFeatureParamsRow.datawinduration);

    % create the mapping of pred classifier folds to quality classifier folds
    if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
       pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
    else
        fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
    end

    %rng(2);
    %[pmMissPattIndex] = createDWMissScenarios(pmMissPattIndex, npcexamples, nqcfolds, nactmisspatts, nsynmisspatts, mpfrom, mpto);

    % loop over the number of missingness patterns required
    for mi = 1:batchsize
        qcfold = pmMissPattIndex.QCFold(mi);
        fprintf('Batch %d: %d of %d: Qual Classifier fold %d, Pred Classifier folds ', thisbatch, mi, batchsize, qcfold);
        fprintf('%d ', pcfolds(qcfold, :));
        fprintf('\n');
        % apply missingness pattern at random (see augment function)
        [pmMSDataWinArray, pmMissPattIndex(mi, :), pmMissPattArray(mi, :)] = applyMissPattToDataWinArray(pmDataWinArray, ...
                pmMissPattIndex(mi, :), pmMissPattArray(mi, :), measures, nmeasures, pmFeatureParamsRow);

        [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
            createModFeaturesFromDWArrays(pmMSDataWinArray, pmOverallStats, npcexamples, measures, nmeasures, pmModFeatParamsRow);

        % separate out test data and keep aside
        [~, ~, ~, ~, ~, ~, pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
            trcvlabels, ~, npcfolds] = splitTestFeaturesNew(pmFeatureIndex, ...
            pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
            pmExABxElLabels, pmPatientSplit, nsplits);

        [pmMissPattQS(mi, :)] = calcPCMPPredictAndQS(pmMissPattQS(mi, :), pmModelByFold, pmTrCVFeatureIndex, ...
            pmTrCVNormFeatures, trcvlabels, pmPatientSplit, pmAMPred, ...
            qcfold, nqcfolds, npcfolds, pcfolds, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, ...
            epilen, lossfunc);
    end

    % save baseline QS scores by fold
    if thisbatch == 1
        pmBaselineIndex = pmMissPattIndex(1:nqcfolds, :);
        pmBaselineQS    = pmMissPattQS(1:nqcfolds, :);
        pmMissPattIndex(1:nqcfolds, :) = [];
        pmMissPattArray(1:nqcfolds, :) = [];
        pmMissPattQS(1:nqcfolds, :)    = [];
        pmMissPattQSPct(1:nqcfolds, :) = [];
    else
        % need to load in baseline QS from batch 1 file
    end

    % populate the relative percentage QS table
    for i = 1:nqcfolds
        bidx = pmBaselineIndex.QCFold == i;
        midx = pmMissPattIndex.QCFold == i;
        pmMissPattQSPct(midx, :) = array2table(table2array(pmMissPattQS(midx, :)) ./ table2array(pmBaselineQS(bidx, :)));
    end

    pmHyperParamsRow = struct();
    pmHyperParamsRow.learnrate   = pmHyperParamQS.HyperParamQS.LearnRate;
    pmHyperParamsRow.numtrees    = pmHyperParamQS.HyperParamQS.NumTrees;
    pmHyperParamsRow.minleafsz   = pmHyperParamQS.HyperParamQS.MinLeafSize;
    pmHyperParamsRow.maxnumsplit = pmHyperParamQS.HyperParamQS.MaxNumSplit;
    pmHyperParamsRow.fracvarsamp = pmHyperParamQS.HyperParamQS.FracVarsToSample;

    
    pmOtherRunParams.btmode     = 2;
    % no need to update runtype
    pmOtherRunParams.nbssamples = 0;
    pmOtherRunParams.epilen     = epilen;
    pmOtherRunParams.lossfunc   = lossfunc;
    pmOtherRunParams.nqcfolds   = nqcfolds;
    pmOtherRunParams.batchsize  = basebatchsize;

    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%sB%d-%d.mat', baseqcinputfile, basebatchsize, thisbatch);
    fprintf('Saving model output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
        'pmBaselineIndex', 'pmBaselineQS', 'pmModelByFold', 'nqcfolds', ...
        'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
        'measures', 'nmeasures', 'thisbatch', 'ba', 'batchsize');
    toc
    fprintf('\n');
    
end

beep on;
beep;
