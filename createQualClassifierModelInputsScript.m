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

basemodelresultsfile = shortenQCFileName(basemodelresultsfile, pmHyperParamQS.HyperParamQS);
qcbaselinefile       = strrep(basemodelresultsfile, ' ModelResults', 'QCBaseline');
qcdatasetfile        = strrep(basemodelresultsfile, ' ModelResults', 'QCDataset');

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

tic
fprintf('Loading baseline quality scores from file %s\n', qcbaselinefile);
load(fullfile(basedir, subfolder, sprintf('%s.mat', qcbaselinefile)), 'pmBaselineIndex', 'pmBaselineQS');
toc
fprintf('\n');

epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time
nqcfolds = 2; % number of folds for the nested cross validation for the quality classifier
batchsize = 1000; % number of examples in each batch

npcexamples = size(pmFeatureIndex, 1);
nrawmeasures = sum(measures.RawMeas);

[qcinputfiles, nbatchfiles] = getQCBatchInputFiles(qcdatasetfile, batchsize);
if nbatchfiles > 0
    lastbatch = getQCLastBatchFile(qcinputfiles, qcdatasetfile, nbatchfiles, batchsize);
else
    lastbatch = 0;
end
[batchto, validresponse] = selectBatchNbr('finish', lastbatch + 1, lastbatch + 100);
if validresponse == 0
    return;
end
fprintf('\n');

%mpfrom = (lastbatch * batchsize) + 1;
%mpto   = (batchto   * batchsize)    ;
%nmptotal = mpto;
%nmpthisrun = mpto - mpfrom + 1;
%if nmptotal > npcexamples
%    nactmisspatts = npcexamples;
%    nsynmisspatts = nmptotal - nactmisspatts;
%else
%    nactmisspatts = nmptotal;
%    nsynmisspatts = 0;
%end
%fprintf('Running for batch size %d from batch %d to %d\n', batchsize, lastbatch + 1, batchto);
%fprintf('\n');

%[pmMissPattIndexThisRun, ~, ~, ~] ... 
%    = createDWMissPattTables(nmptotal, nrawmeasures, pmFeatureParamsRow.datawinduration);

%rng(2);
%[pmMissPattIndexThisRun] = createDWMissScenarios(pmMissPattIndexThisRun, npcexamples, nqcfolds, nactmisspatts, nsynmisspatts, mpfrom, mpto);

[pmMissPattIndexThisRun] = createDWMissScenarios(lastbatch, batchto, batchsize, npcexamples, nqcfolds, nrawmeasures, pmFeatureParamsRow.datawinduration);

for ba = 1:(batchto - lastbatch)
    
    thisbatch = lastbatch + ba;
    
    % extract the relevant rows for this batch
    pmMissPattIndex = pmMissPattIndexThisRun(((ba - 1) * batchsize) + 1:(ba * batchsize), :);
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
    pmOtherRunParams.batchsize  = batchsize;

    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%sB%d-%d.mat', qcdatasetfile, batchsize, thisbatch);
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
