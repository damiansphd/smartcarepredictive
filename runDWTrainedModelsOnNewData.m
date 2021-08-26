clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

basedir = setBaseDir();
subfolder = 'DataFiles';

% Choose feature version, label method and raw measures combination
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

% Choose predictive classifier version for above choices
fprintf('Choose the trained predictive classifier version to run\n');
typetext = ' ModelResults';
[pcbasemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
pcmodelresultsfile = sprintf('%s.mat', pcbasemodelresultsfile);
pcbasemodelresultsfile = strrep(pcbasemodelresultsfile, typetext, '');
fprintf('\n');

% Choose quality classifier version for above choices
fprintf('Choose the trained quality classifier version to run\n');
typetext = 'QCResults';
[qcbasemodelresultsfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcmodelresultsfile = sprintf('%s.mat', qcbasemodelresultsfile);
qcbasemodelresultsfile = strrep(qcbasemodelresultsfile, typetext, '');
fprintf('\n');

% Choose model features for data to run on
fprintf('Choose the data set to run models on\n');
[mfbasefeatureparamfile, ~, ~, validresponse] = selectModelFeatureParameters(fv1);
if ~validresponse
    return
end
fprintf('\n');
featureparamfile     = strcat(mfbasefeatureparamfile, '.xlsx');
pmThisFeatureParams  = readtable(fullfile(basedir, subfolder, featureparamfile));
nfeatureparamsets = size(pmThisFeatureParams,1);

% load trained predictive classifier
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', pcmodelresultsfile);
load(fullfile(basedir, subfolder, pcmodelresultsfile), ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');        
if pmOtherRunParams.runtype ~= 2
    fprintf('Need to have pc model trained on all training data, not CV folds\n');
    return;
end
        
% load trained quality classifier
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading quality classifier results data for %s\n', qcmodelresultsfile);
load(fullfile(basedir, subfolder, qcmodelresultsfile), ...
        'pmQCModelRes', 'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
        'pmQSConstr');
toc
fprintf('\n');
if pmMPOtherRunParams.runtype ~= 2
    fprintf('Need to have qc model trained on all training data, not CV folds\n');
    return;
end

% choose the operating threshold for the quality classifier
[qcopthres, validresponse] = selectFromArrayByIndex('Operating Threshold', [pmQCModelRes.PredOp; 0.6; 0.7; 0.8; 0.9; 0.95]);
if validresponse == 0
    return;
end

nrows = 20;
pmTrModNewDataResTable = createTrModNewDataResTable(nrows); % hardcode for now, increase as necessary
row = 1;

for fs = 1:nfeatureparamsets
    
    fprintf('%2d of %2d Feature/Model Parameter combinations\n', fs, nfeatureparamsets);
    fprintf('---------------------------------------------\n');

    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    fbasefilename = generateFileNameFromModFeatureParams(pmThisFeatureParams(fs,:));
    featureinputmatfile = sprintf('%s.mat',fbasefilename);
    fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
    load(fullfile(basedir, subfolder, featureinputmatfile), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'measures', 'nmeasures', 'pmModFeatParamsRow', ...
        'pmNormFeatures', 'pmNormFeatNames');
    psplitfile = sprintf('%spatientsplit.mat', pmThisFeatureParams.StudyDisplayName{fs});
    fprintf('Loading patient splits from file %s\n', psplitfile);
    load(fullfile(basedir, subfolder, psplitfile));
    toc
    fprintf('\n');
    
    tic
    % if the trained model study is the same as the new data, then choose train vs test split
    % else run for whole dataset.
    if ismember(pmFeatureParamsRow.StudyDisplayName, pmModFeatParamsRow.StudyDisplayName)
        [runtype, ~, validresponse] = selectRunMode();
        if runtype == 1
            [~, ~, ~, ~, ...
             ~, ~, ...
             featindex, ~, ~, normfeatures, ...
             labels, patsplit, ~, testidx] ...
             = splitTestFeaturesNew(pmFeatureIndex, zeros(size(pmFeatureIndex, 1), 1), zeros(size(pmFeatureIndex, 1), 1), pmNormFeatures, ...
                                    pmExABxElLabels, pmPatientSplit, nsplits);
                                
            datawinarray   = pmDataWinArray(~testidx, :, :);
            datascope = 'Train';
        else
            [featindex, ~, ~, normfeatures, ...
             labels, patsplit, ...
             ~, ~, ~, ~, ...
             ~, ~, ~, testidx] ...
             = splitTestFeaturesNew(pmFeatureIndex, zeros(size(pmFeatureIndex, 1), 1), zeros(size(pmFeatureIndex, 1), 1), pmNormFeatures, ...
                                    pmExABxElLabels, pmPatientSplit, nsplits);

            datawinarray   = pmDataWinArray(testidx, :, :);
            datascope = 'Held-Out Test';
        end
    else
        featindex    = pmFeatureIndex;
        normfeatures = pmNormFeatures;
        labels       = pmExABxElLabels;
        patsplit     = pmPatientSplit;
        datawinarray = pmDataWinArray;
        datascope    = 'All';
    end
    
    datawin       = pmModFeatParamsRow.datawinduration;
    normwin       = pmModFeatParamsRow.normwinduration;
    totalwin      = datawin + normwin;
    nexamples     = size(featindex, 1);
    nfolds        = 1;
    nnormfeatures = size(normfeatures, 2);
    
    % create features for quality classifier
    dummyarray = zeros(nexamples, totalwin, nmeasures);
    mswinarray = zeros(nexamples, totalwin, nmeasures);
    mswinarray(isnan(datawinarray)) = 1;
    
    qcmodfeatparamrow             = pmModFeatParamsRow;
    qcmodfeatparamrow.msfeat      = qcmodfeatparamrow.rawmeasfeat;
    qcmodfeatparamrow.rawmeasfeat = 1;
    qcmodfeatparamrow.volfeat     = 1;
    qcmodfeatparamrow.pmeanfeat   = 1;
    
    [qcfeatures, ~, qcmeasures] = createModelFeaturesFcn(dummyarray, ...
            mswinarray, dummyarray, dummyarray, qcmodfeatparamrow, nexamples, totalwin, measures, nmeasures);
    
    
    % run predictive classifier on all days & calc daily qs
    fprintf('\n');
    fprintf('Running predictive classifier on new data set - all days\n');
    fold       = 1;
    pcmodel    = pmModelRes.pmNDayRes(1).Folds(fold).Model;
    pcmodelver = pmModelParamsRow.ModelVer{1};
    pclossfunc = pmOtherRunParams.lossfunc;
    origidx    = featindex.ScenType == 0;
    norigex    = sum(origidx);
    pmAllPCRes = createModelDayResStuct(norigex, fold, 1);
    pmAllPCRes = predictPredModel(pmAllPCRes, pcmodel, normfeatures(origidx, :), labels(origidx, :), pcmodelver, pclossfunc);
    pmAllPCRes = calcModelQualityScores(pmAllPCRes, labels(origidx, :), norigex);
    daysscope  = 'All';
    pmTrModNewDataResTable(row, :) = updateTrModNewDataResTableRow(pmTrModNewDataResTable(row, :), pmFeatureParamsRow, ...
            pcmodelresultsfile, qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureinputmatfile, ...
            datascope, daysscope, nexamples, nexamples, sum(labels(origidx, :)), pmAllPCRes);
    row = row + 1;
    fprintf('\n');
    
    % run quality classifier on all days
    fprintf('\n');
    fprintf('Running quality classifier on new data set\n');
    qcmodel    = pmQCModelRes.Folds(fold).Model;
    qcmodelver = pmMPModelParamsRow.ModelVer{1};
    qclossfunc = 'hinge'; % hardcoded for now - until add this to mp other run parameters
    pmAllQCRes = createQCModelResStruct(nexamples, 1);
    pmAllQCRes = predictPredModel(pmAllQCRes, qcmodel, qcfeatures(origidx, :), zeros(norigex, 1), qcmodelver, qclossfunc);
    pmAllQCRes.Loss = 0; % Loss calculation does not make sense for new data as we don't have labels to compare to
    
    % create index of safe days
    safeidx    = pmAllQCRes.Pred >= qcopthres;
    nsafedays  = sum(safeidx);
    fprintf('There are %d safe days out of a total of %d days (%.1f%%)\n', nsafedays, nexamples, 100 * nsafedays / nexamples);
    
    % calc daily qs on pred classifier safe days
    fprintf('\n');
    fprintf('Running predictive classifier on new data set - safe days\n');
    unionidx = safeidx & origidx;
    nsafeorigdays = sum(unionidx);
    pmSafePCRes = createModelDayResStuct(nsafeorigdays, fold, 1);
    pmSafePCRes = predictPredModel(pmSafePCRes, pcmodel, normfeatures(unionidx, :), labels(unionidx, :), pcmodelver, pclossfunc);
    pmSafePCRes = calcModelQualityScores(pmSafePCRes, labels(unionidx, :), nsafeorigdays);
    daysscope  = 'Safe';
    pmTrModNewDataResTable(row, :) = updateTrModNewDataResTableRow(pmTrModNewDataResTable(row, :), pmFeatureParamsRow, ...
            pcmodelresultsfile, qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureinputmatfile, ...
            datascope, daysscope, nsafedays, nexamples, sum(labels(unionidx, :)), pmSafePCRes);
    row = row + 1;
    fprintf('\n');
    
    toc
    fprintf('\n');
    
    
    % train new model on safe days
    if ~ismember(pmFeatureParamsRow.StudyDisplayName, pmModFeatParamsRow.StudyDisplayName)
        
        sfdatawinarray = pmDataWinArray(safeidx, :, :);
        nsfexamples    = sum(safeidx);
        nfolds         = 1;
        nnormfeatures  = size(pmNormFeatures, 2);
        
        [testfeatindex, ~, ~, testnormfeatures, ...
        testlabels, testpatsplit, ... 
        trcvfeatindex, ~, ~, trcvnormfeatures, ...
        trcvlabels, trcvpatsplit, ~, testidx] ...
             = splitTestFeaturesNew(pmFeatureIndex(safeidx, :), zeros(nsfexamples, 1), zeros(nsfexamples, 1), pmNormFeatures(safeidx, :), ...
                                    pmExABxElLabels(safeidx), pmPatientSplit, nsplits);
                                
        trcvdatawinarray = sfdatawinarray(~testidx, :, :);
        
        fprintf('\n');
        fprintf('Training predictive classifier on new data set - safe days\n');
        
        pcmodelver = pmModelParamsRow.ModelVer{1};
        [modeltype, mmethod] = setModelTypeAndMethod(pcmodelver);
        lrval  = pmHyperParamQS.HyperParamQS.LearnRate(1);
        ntrval = pmHyperParamQS.HyperParamQS.NumTrees(1);
        mlsval = pmHyperParamQS.HyperParamQS.MinLeafSize(1);
        mnsval = pmHyperParamQS.HyperParamQS.MaxNumSplit(1);
        fvsval = pmHyperParamQS.HyperParamQS.FracVarsToSample(1);
        pclossfunc = pmOtherRunParams.lossfunc;
        
        fold  = 1;
        foldhpcomb = 1;
        origidx = testfeatindex.ScenType == 0;
        norigex = sum(origidx);
        pmNewSfDayRes = createModelDayResStuct(norigex, fold, 0);

        if ismember(pmModelParamsRow.ModelVer{1}, {'vPM1', 'vPM4','vPM10', 'vPM11', 'vPM12', 'vPM13'})
            % train model
            fprintf('Training...');
            [pmNewSfDayRes] = trainPredModel(pcmodelver, pmNewSfDayRes, trcvnormfeatures, trcvlabels, ...
                                pmNormFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
            fprintf('Done\n');

            % calculate predictions and quality scores on training data
            fprintf('Tr: ');
            pmTrRes = createModelDayResStuct(size(trcvfeatindex, 1), fold, 0);
            pmTrRes = predictPredModel(pmTrRes, pmNewSfDayRes.Folds(fold).Model, trcvnormfeatures, trcvlabels, pcmodelver, pclossfunc);
            pmTrRes = calcModelQualityScores(pmTrRes, trcvlabels, size(trcvfeatindex, 1));
            datascope  = 'Train';
            daysscope  = 'Safe';
            tempfeatparams = pmFeatureParamsRow;
            tempfeatparams.StudyDisplayName = pmModFeatParamsRow.StudyDisplayName;
            pmTrModNewDataResTable(row, :) = updateTrModNewDataResTableRow(pmTrModNewDataResTable(row, :), tempfeatparams, ...
                'N/A', qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureinputmatfile, ...
                datascope, daysscope, size(trcvfeatindex, 1), size(trcvfeatindex, 1), sum(trcvlabels), pmTrRes);
            row = row + 1;
            fprintf('\n');

            fprintf('Test: ');
            pmTestRes = createModelDayResStuct(norigex, fold, 0);
            pmTestRes = predictPredModel(pmTestRes, pmNewSfDayRes.Folds(fold).Model, testnormfeatures(origidx, :), testlabels(origidx, :), pcmodelver, pclossfunc);
            pmTestRes = calcModelQualityScores(pmTestRes, testlabels(origidx, :), norigex);
            datascope  = 'Test';
            daysscope  = 'Safe';
            pmTrModNewDataResTable(row, :) = updateTrModNewDataResTableRow(pmTrModNewDataResTable(row, :), tempfeatparams, ...
                'N/A', qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureinputmatfile, ...
                datascope, daysscope, size(testfeatindex, 1), size(testfeatindex, 1), sum(testlabels(origidx, :)), pmTestRes);
            row = row + 1;
            fprintf('\n');
            
            % also store results on overall model results structure
            pmNewSfDayRes.Pred = pmTestRes.Pred;
            pmNewSfDayRes.Loss(fold) = pmTestRes.Loss;

        else
            fprintf('Unsupported model version\n');
            return;
        end
        
    end
        
    % save individual results ?
    
end

% remove unused rows
if row <= nrows
    pmTrModNewDataResTable(row:end, :) = [];
end

tic
% save results to matlab archive + excel
timenow = datestr(clock(),30);

subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%sNewDataRes %s.mat', pcbasemodelresultsfile, timenow);
fprintf('Saving results to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmTrModNewDataResTable', ...
    'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams', ...
    'pmQCModelRes', 'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
    'pmQSConstr', 'qcopthres', 'pmThisFeatureParams');

subfolder = 'ExcelFiles';
outputfilename = sprintf('%sNewDataRes %s.xlsx', pcbasemodelresultsfile, timenow);
fprintf('Saving table to file %s\n', outputfilename);
writetable(pmTrModNewDataResTable, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'DataResults');
toc
fprintf('\n');


