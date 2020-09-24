clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

basedir = setBaseDir();
subfolder = 'DataFiles';
[basefeatureparamfile, ~, ~, validresponse] = selectFeatureParameters();
if validresponse == 0
    return;
end
featureparamfile     = strcat(basefeatureparamfile, '.xlsx');
pmThisFeatureParams  = readtable(fullfile(basedir, subfolder, featureparamfile));
nfeatureparamsets = size(pmThisFeatureParams,1);
if nfeatureparamsets > 1
    fprintf('Missingness Pattern Script only accepts a single feature parameter set\n');
    return;
end

[basemodelparamfile, ~, ~, validresponse] = selectModelRunParameters();
if validresponse == 0
    return;
end
modelparamfile       = strcat(basemodelparamfile, '.xlsx');
pmModelParams        = readtable(fullfile(basedir, subfolder, modelparamfile));
nmodelparamsets   = size(pmModelParams,1);
if nmodelparamsets > 1
    fprintf('Missingness Pattern Script only accepts a single model parameter set\n');
    return;
end

ncombinations     = nfeatureparamsets * nmodelparamsets;

[basehpparamfile, ~, ~, validresponse] = selectHyperParameters();
if validresponse == 0
    return;
end
pmHyperParams        = readtable(fullfile(basedir, subfolder, strcat(basehpparamfile, '.xlsx')));
if size(pmHyperParams, 1) > 1
    fprintf('Missingness Pattern Script only accepts a single hyper-parameter set\n');
    return;
end

[lrarray, ntrarray, mlsarray, mnsarray, fvsarray, nlr, ntr, nmls, nmns, nfvs, hpsuffix] = setHyperParameterArrays(pmHyperParams);

[runtype, rtsuffix, validresponse] = selectRunMode();
if validresponse == 0
    return;
end
                
epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time
plotbyfold = 0; % set to 1 if you want to print the pr & roc curves by fold

fs = 1;
mp = 1;
        
combnbr = ((fs - 1) * nmodelparamsets) + mp;

fprintf('%2d of %2d Feature/Model Parameter combinations\n',combnbr, ncombinations);
fprintf('---------------------------------------------\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fbasefilename = generateFileNameFromFullFeatureParams(pmThisFeatureParams(fs,:));
featureinputmatfile = sprintf('%s.mat',fbasefilename);
fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
load(fullfile(basedir, subfolder, featureinputmatfile));
psplitfile = sprintf('%spatientsplit.mat', pmThisFeatureParams.StudyDisplayName{fs});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

mbasefilename = generateFileNameFromFullModelParams(fbasefilename, pmModelParams(mp,:));
mbasefilename = sprintf('%s%s%s', mbasefilename, hpsuffix, rtsuffix);
plotsubfolder = sprintf('Plots/%s', mbasefilename);

if plotbyfold == 1
    mkdir(fullfile(basedir, plotsubfolder));
end

featureduration = pmThisFeatureParams.featureduration(fs);
nexamples = size(pmNormFeatures,1);

% add check on only raw measures features being used
if pmThisFeatureParams.volfeat > 1 || pmThisFeatureParams.pmeanfeat > 1
    fprintf('Missingness Pattern script only runs for raw measures\n');
    return
end
% add check on fully interpolated dataset only being used
if pmThisFeatureParams.interpmethod ~= 1 || pmThisFeatureParams.augmethod ~= 1
   fprintf('Missingness Pattern script only runs on fully interpolated unaugmented data-set\n');
    return
end 
% copy pmNormFeatures to pmOrigNormFeatures
pmOrigNormFeatures = pmNormFeatures;
nrawfeatures = sum(contains(pmNormFeatNames, {'RM'}));
nrawmeas = sum(measures.RawMeas);

nmisspatts = 200;
rng(2);
[pmMissPattIndex, pmMissPattArray, pmMissPattQS] = createMissPattTables(nmisspatts, nrawfeatures);

% add for loop here over number of missingness patterns required
for mi = 1:nmisspatts
     
    % restore orig norm features to normfeatures
    pmNormFeatures = pmOrigNormFeatures;

    % apply missingness pattern at random (see augment function)
    [pmNormFeatures, pmMissPattIndex(mi, :), pmMissPattArray(mi, :)] = ...
        applyMissPattToDataSet(pmNormFeatures, pmMissPattIndex(mi, :), pmMissPattArray(mi, :), nrawfeatures, nrawmeas, pmThisFeatureParams.msconst);
    
    %   train/predict model for 4-fold CV
    %   calc pred qual scores
    %   store results in arrays - scenario description array, missingness pattern array and qual score
    %   array

    % separate out test data and keep aside
    [pmTestFeatureIndex, pmTestMuIndex, pmTestSigmaIndex, pmTestNormFeatures, ...
     pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, pmTestExABLabels, pmTestExABxElLabels, ...
     pmTestPatientSplit, ...
     pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, ...
     pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels,...
     pmTrCVPatientSplit, nfolds] ...
     = splitTestFeatures(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmNormFeatures, pmIVLabels, pmExLabels, ...
                         pmABLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels, pmPatientSplit, nsplits);

    ntrcvexamples = size(pmTrCVNormFeatures, 1);
    ntestexamples = size(pmTestNormFeatures, 1);
    nnormfeatures = size(pmTrCVNormFeatures, 2);
    if runtype == 2
        nfolds = 1;
    end

    [labels] = setLabelsForLabelMethod(pmModelParams.labelmethod(mp), pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);
    trcvlabels = labels(:);
    [labels] = setLabelsForLabelMethod(pmModelParams.labelmethod(mp), pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, pmTestExABLabels, pmTestExABxElLabels);
    testlabels = labels(:);

    % for the 'Ex Start to Treatment' label, there is only one task.
    % for the other label methods, use the predictionduration from the
    % feature parameters record
    if (pmModelParams.labelmethod(mp) == 5 || pmModelParams.labelmethod(mp) == 6)
        predictionduration = 1;
    else
        fprintf('These models only support label method 5 and 6\n');
        return;
    end

    [modeltype, mmethod] = setModelTypeAndMethod(pmModelParams.ModelVer{mp});
    fprintf('Running %s model for Label method %d\n', modeltype, pmModelParams.labelmethod(mp));
    fprintf('\n');

    nhpcomb      = nlr * ntr * nmls * nmns * nfvs;
    [hyperparamQS, foldhpTrQS, foldhpCVQS, foldhpTestQS] = createHpQSTables(nhpcomb, nfolds);

    lr = 1;
    lrval = lrarray(lr);
    tr = 1;
    ntrval = ntrarray(tr);
    mls = 1;
    mlsval = mlsarray(mls);
    mns = 1;
    mnsval = mnsarray(mns);
    fvs = 1;
    fvsval = fvsarray(fvs);

    tic
    hpcomb = ((lr - 1) * ntr * nmls * nmns * nfvs) + ((tr - 1) * nmls * nmns * nfvs) + ((mls - 1) * nmns * nfvs) + ((mns - 1) * nfvs) + fvs;

    fprintf('%2d of %2d Hyperparameter combinations\n', hpcomb, nhpcomb);

    if runtype == 1
        % run n-fold cross-validation
        origidx = pmTrCVFeatureIndex.ScenType == 0;
        norigex = sum(origidx);
        pmDayRes = createModelDayResStuct(norigex, nfolds, 1);
        %pmDayRes = createModelDayResStuct(ntrcvexamples, nfolds, nbssamples);

        for fold = 1:nfolds

            foldhpcomb = (hpcomb - 1) * nfolds + fold;

            fprintf('Fold %d: ', fold);

            [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
             pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] ...
                = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);

            origcvidx = cvidx & pmTrCVFeatureIndex.ScenType == 0;

            if ismember(pmModelParams.ModelVer{mp}, {'vPM1', 'vPM4', 'vPM10', 'vPM11', 'vPM12', 'vPM13'})
                % train model
                fprintf('Training...');
                [pmDayRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmDayRes, pmTrNormFeatures, trlabels, ...
                                    pmNormFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                fprintf('Done\n');

                % calculate predictions and quality scores on training data
                fprintf('Tr: ');
                [foldhpTrQS, pmTrRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTrQS, pmTrFeatureIndex, ...
                                    pmTrNormFeatures, trlabels, fold, foldhpcomb, pmAMPred, ...
                                    pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                    lrval, ntrval, mlsval, mnsval, fvsval);
                if plotbyfold == 1
                    filename = sprintf('%s-Tr-F%d', mbasefilename, fold);
                    plotPRAndROCCurvesForPaper(pmTrRes, [] , 'na', plotsubfolder, filename);
                end

                % calculate predictions and quality scores on cv data
                fprintf('CV: ');
                [foldhpCVQS, pmCVRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpCVQS, pmTrCVFeatureIndex(origcvidx, :), ...
                                            pmTrCVNormFeatures(origcvidx, :), trcvlabels(origcvidx), fold, foldhpcomb, pmAMPred, ...
                                            pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                            lrval, ntrval, mlsval, mnsval, fvsval);
                %[foldhpCVQS, pmCVRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpCVQS, pmCVFeatureIndex, ...
                %                            pmCVNormFeatures, cvlabels, fold, foldhpcomb, pmAMPred, ...
                %                            pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                %                            lrval, ntrval, mlsval, mnsval, fvsval);
                if plotbyfold == 1
                    filename = sprintf('%s-CV-F%d', mbasefilename, fold);
                    plotPRAndROCCurvesForPaper(pmCVRes, '', '', plotsubfolder, filename);
                end

                % also store results on overall model results structure
                pmDayRes.Pred(origcvidx) = pmCVRes.Pred;
                %pmDayRes.Pred(cvidx) = pmCVRes.Pred; %tempscore(:, 2);
                pmDayRes.Loss(fold)  = pmCVRes.Loss;
            else
                fprintf('Unsupported model version\n');
                return;
            end
        end

        fprintf('Overall:\n');
        fprintf('CV: ');
        fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
        [pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, trcvlabels(origidx), norigex, pmAMPred, pmTrCVFeatureIndex(origidx, :), pmPatientSplit, epilen);
        %[pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmPatientSplit, epilen);

        fprintf('\n');
        
        % add row to MissPatt QS table
        pmMissPattQS.PScore(mi)      = pmDayRes.PScore;
        pmMissPattQS.ElecPScore(mi)  = pmDayRes.ElecPScore;
        pmMissPattQS.AvgEpiTPred(mi) = pmDayRes.AvgEpiTPred;
        pmMissPattQS.AvgEpiFPred(mi) = pmDayRes.AvgEpiFPred;
        pmMissPattQS.AvgEPV(mi)      = pmDayRes.AvgEPV;
        pmMissPattQS.PRAUC(mi)       = pmDayRes.PRAUC;
        pmMissPattQS.ROCAUC(mi)      = pmDayRes.ROCAUC;
        pmMissPattQS.Acc(mi)         = pmDayRes.Acc;
        pmMissPattQS.PosAcc(mi)      = pmDayRes.PosAcc;
        pmMissPattQS.NegAcc(mi)      = pmDayRes.NegAcc;

        hyperparamQS(hpcomb, :) = setHyperParamQSrow(hyperparamQS(hpcomb, :), lrval, ntrval, mlsval, mnsval, fvsval, pmDayRes);

        toc
        fprintf('\n');

    elseif runtype == 2
        % run on held-out test data
        fold = 1;
        foldhpcomb = 1;
        origidx = pmTestFeatureIndex.ScenType == 0;
        norigex = sum(origidx);
        pmDayRes = createModelDayResStuct(norigex, fold, nbssamples);
        %pmDayRes = createModelDayResStuct(ntestexamples, fold, nbssamples);

        if ismember(pmModelParams.ModelVer{mp}, {'vPM1', 'vPM4','vPM10', 'vPM11', 'vPM12', 'vPM13'})
            % train model
            fprintf('Training...');
            [pmDayRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmDayRes, pmTrCVNormFeatures, trcvlabels, ...
                                pmNormFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
            fprintf('Done\n');

            % calculate predictions and quality scores on training data
            fprintf('Tr: ');
            [foldhpTrQS, pmTrRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTrQS, pmTrCVFeatureIndex, ...
                                pmTrCVNormFeatures, trcvlabels, fold, foldhpcomb, pmAMPred, ...
                                pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                lrval, ntrval, mlsval, mnsval, fvsval);
            if plotbyfold == 1
                filename = sprintf('%s-Tr-F%d', mbasefilename, fold);
                plotPRAndROCCurvesForPaper(pmTrRes, [] , 'na', plotsubfolder, filename);
            end

            fprintf('Test: ');
            [foldhpTestQS, pmTestRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTestQS, pmTestFeatureIndex(origidx, :), ...
                                        pmTestNormFeatures(origidx, :), testlabels(origidx), fold, foldhpcomb, pmAMPred, ...
                                        pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);
            %[foldhpTestQS, pmTestRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTestQS, pmTestFeatureIndex, ...
            %                            pmTestNormFeatures, testlabels, fold, foldhpcomb, pmAMPred, ...
            %                            pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
            %                            lrval, ntrval, mlsval, mnsval, fvsval);
            if plotbyfold == 1
                filename = sprintf('%s-Test-F%d', mbasefilename, fold);
                plotPRAndROCCurvesForPaper(pmTestRes, '', '', plotsubfolder, filename);
            end

            % also store results on overall model results structure
            pmDayRes.Pred       = pmTestRes.Pred;
            pmDayRes.Loss(fold) = pmTestRes.Loss;

        else
            fprintf('Unsupported model version\n');
            return;
        end

        fprintf('Overall:\n');
        fprintf('Test: ');
        fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
        [pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, testlabels(origidx), ntestexamples, pmAMPred, pmTestFeatureIndex(origidx, :), pmPatientSplit, epilen);
        %[pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, testlabels, ntestexamples, pmAMPred, pmTestFeatureIndex, pmPatientSplit, epilen);

        fprintf('\n');

        hyperparamQS(hpcomb, :) = setHyperParamQSrow(hyperparamQS(hpcomb, :), lrval, ntrval, mlsval, mnsval, fvsval, pmDayRes);

        toc
        fprintf('\n');

    else
        fprintf('Unknown run mode\n');
        return
    end

end

pmFeatureParamsRow = pmThisFeatureParams(fs,:);
pmModelParamsRow   = pmModelParams(mp,:);

pmHyperParamsRow = struct();
pmHyperParamsRow.learnrate = lrval;
pmHyperParamsRow.numtrees = ntrval;
pmHyperParamsRow.minleafsz = mlsval;
pmHyperParamsRow.maxnumsplit = mnsval;
pmHyperParamsRow.fracvarsamp = fvsval;

pmOtherRunParams = struct();
pmOtherRunParams.btmode     = 2;
pmOtherRunParams.runtype    = runtype;
pmOtherRunParams.nbssamples = 0;
pmOtherRunParams.epilen     = epilen;
pmOtherRunParams.lossfunc   = lossfunc;

fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%s MPRes.mat', mbasefilename);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams');
toc
fprintf('\n');

beep on;
beep;
