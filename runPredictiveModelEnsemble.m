clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
[basefeatureparamfile, ~, ~, validresponse] = selectFeatureParameters();
if validresponse == 0
    return;
end
featureparamfile     = strcat(basefeatureparamfile, '.xlsx');
pmThisFeatureParams  = readtable(fullfile(basedir, subfolder, featureparamfile));
nfeatureparamsets = size(pmThisFeatureParams,1);

[basemodelparamfile, ~, ~, validresponse] = selectModelRunParameters();
if validresponse == 0
    return;
end
modelparamfile       = strcat(basemodelparamfile, '.xlsx');
pmModelParams        = readtable(fullfile(basedir, subfolder, modelparamfile));
nmodelparamsets   = size(pmModelParams,1);
ncombinations     = nfeatureparamsets * nmodelparamsets;

[basehpparamfile, ~, ~, validresponse] = selectHyperParameters();
if validresponse == 0
    return;
end
pmHyperParams        = readtable(fullfile(basedir, subfolder, strcat(basehpparamfile, '.xlsx')));
[lrarray, ntrarray, mlsarray, mnsarray, fvsarray, nlr, ntr, nmls, nmns, nfvs, hpsuffix] = setHyperParameterArrays(pmHyperParams);
                
[btmode, btsuffix, validresponse] = selectBSMode();
if validresponse == 0
    return;
end

[runtype, rtsuffix, validresponse] = selectRunMode();
if validresponse == 0
    return;
end
                
nbssamples = 50; % temporary hardcoding - replace with model parameter when have more time
epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time

pmBSAllQS = struct('FeatureParams', [], 'ModelParams', []);

for fs = 1:nfeatureparamsets
    
    for mp = 1:nmodelparamsets
        
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
        mbasefilename = sprintf('%s%s%s%s', mbasefilename, hpsuffix, rtsuffix, btsuffix);
        plotsubfolder = sprintf('Plots/%s', mbasefilename);
        mkdir(fullfile(basedir, plotsubfolder));
        
        pmBSAllQS(combnbr).FeatureParams = pmThisFeatureParams(fs, :);
        pmBSAllQS(combnbr).ModelParams   = pmModelParams(mp,:);
        
        featureduration = pmThisFeatureParams.featureduration(fs);
        nexamples = size(pmNormFeatures,1);
        
        % separate out test data and keep aside
        [pmTestFeatureIndex, pmTestMuIndex, pmTestSigmaIndex, pmTestNormFeatures, ...
         pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, pmTestExABLabels, pmTestExABxElLabels, ...
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
            break;
        end
        
        [modeltype, mmethod] = setModelTypeAndMethod(pmModelParams.ModelVer{mp});
        fprintf('Running %s model for Label method %d\n', modeltype, pmModelParams.labelmethod(mp));
        fprintf('\n');
        
        nhpcomb      = nlr * ntr * nmls * nmns * nfvs;
        [hyperparamQS, foldhpTrQS, foldhpCVQS, foldhpTestQS] = createHpQSTables(nhpcomb, nfolds);
    
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

                            if runtype == 1
                                % run n-fold cross-validation
                                pmDayRes = createModelDayResStuct(ntrcvexamples, nfolds, nbssamples);

                                for fold = 1:nfolds
                                    
                                    foldhpcomb = (hpcomb - 1) * nfolds + fold;

                                    fprintf('Fold %d: ', fold);

                                    [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
                                     pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] ...
                                        = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);

                                    if ismember(pmModelParams.ModelVer{mp}, {'vPM1', 'vPM4', 'vPM10', 'vPM11', 'vPM12', 'vPM13'})
                                        % train model
                                        fprintf('Training...');
                                        [pmDayRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmDayRes, pmTrNormFeatures, trlabels, ...
                                                            pmNormFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                                        fprintf('Done\n');
                                        
                                        % calculate predictions and quality scores on training data
                                        fprintf('Tr: ');
                                        [foldhpTrQS, ~] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTrQS, pmTrFeatureIndex, ...
                                                            pmTrNormFeatures, trlabels, fold, foldhpcomb, pmAMPred, ...
                                                            pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                                            lrval, ntrval, mlsval, mnsval, fvsval);
                                        %filename = sprintf('%s-Tr-F%d', mbasefilename, fold);
                                        %plotPRAndROCCurvesForPaper(pmTrRes, [] , 'na', plotsubfolder, filename);
                                        

                                        % calculate predictions and quality scores on training data
                                        fprintf('CV: ');
                                        [foldhpCVQS, pmCVRes] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpCVQS, pmCVFeatureIndex, ...
                                                                    pmCVNormFeatures, cvlabels, fold, foldhpcomb, pmAMPred, ...
                                                                    pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                                                    lrval, ntrval, mlsval, mnsval, fvsval);
                                        %filename = sprintf('%s-CV-F%d', mbasefilename, fold);
                                        %plotPRAndROCCurvesForPaper(pmCVRes, '', '', plotsubfolder, filename);
                                        

                                        % also store results on overall model results structure
                                        pmDayRes.Pred(cvidx) = pmCVRes.Pred; %tempscore(:, 2);
                                        pmDayRes.Loss(fold)  = pmCVRes.Loss;
                                    else
                                        fprintf('Unsupported model version\n');
                                        return;
                                    end
                                end

                                fprintf('Overall:\n');
                                fprintf('CV: ');
                                fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
                                [pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmPatientSplit, epilen);

                                fprintf('\n');

                                hyperparamQS(hpcomb, :) = setHyperParamQSrow(hyperparamQS(hpcomb, :), lrval, ntrval, mlsval, mnsval, fvsval, pmDayRes);

                                toc
                                fprintf('\n');
                                
                            elseif runtype == 2
                                % run on held-out test data
                                fold = 1;
                                foldhpcomb = 1;
                                pmDayRes = createModelDayResStuct(ntestexamples, fold, nbssamples);
                                
                                if ismember(pmModelParams.ModelVer{mp}, {'vPM1', 'vPM4','vPM10', 'vPM11', 'vPM12', 'vPM13'})
                                    % train model
                                    fprintf('Training...');
                                    [pmDayRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmDayRes, pmTrCVNormFeatures, trcvlabels, ...
                                                        pmNormFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                                    fprintf('Done\n');
                                    
                                    % calculate predictions and quality scores on training data
                                    fprintf('Tr: ');
                                    [foldhpTrQS, ~] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTrQS, pmTrCVFeatureIndex, ...
                                                        pmTrCVNormFeatures, trcvlabels, fold, foldhpcomb, pmAMPred, ...
                                                        pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                                        lrval, ntrval, mlsval, mnsval, fvsval);
                                    %filename = sprintf('%s-Tr-F%d', mbasefilename, fold);
                                    %plotPRAndROCCurvesForPaper(pmTrRes, [] , 'na', plotsubfolder, filename);
                                    
                                    fprintf('Test: ');
                                    [foldhpTestQS, pmTestRes, pmAMPredUpd] = calcPredAndQS(pmDayRes.Folds(fold).Model, foldhpTestQS, pmTestFeatureIndex, ...
                                                                pmTestNormFeatures, testlabels, fold, foldhpcomb, pmAMPred, ...
                                                                pmPatientSplit, pmModelParams.ModelVer{mp}, epilen, lossfunc, ...
                                                                lrval, ntrval, mlsval, mnsval, fvsval);
                                    %filename = sprintf('%s-Test-F%d', mbasefilename, fold);
                                    %plotPRAndROCCurvesForPaper(pmTestRes, '', '', plotsubfolder, filename);
                                    
                                    % also store results on overall model results structure
                                    pmDayRes.Pred       = pmTestRes.Pred;
                                    pmDayRes.Loss(fold) = pmTestRes.Loss;
                                    
                                else
                                    fprintf('Unsupported model version\n');
                                    return;
                                end
                                
                            else
                                fprintf('Unknown run mode\n');
                                return
                            end
                        end
                    end
                end
            end
        end
        
        if btmode == 1
            if runtype == 1
                [pmDayRes] = calcBSQualScores(pmDayRes, trcvlabels, nbssamples, ntrcvexamples);
            else
                [pmDayRes] = calcBSQualScores(pmDayRes, testlabels, nbssamples, ntestexamples);
            end
        end
        
        pmHyperParamQS = struct('FeatureParams', [], 'ModelParams', []);
        pmHyperParamQS.FeatureParams = pmThisFeatureParams(fs, :);
        pmHyperParamQS.ModelParams   = pmModelParams(mp,:);
        pmHyperParamQS.HyperParamQS  = hyperparamQS;
        pmHyperParamQS.FoldHpTrQS    = foldhpTrQS;
        pmHyperParamQS.FoldHpCVQS    = foldhpCVQS;
        pmHyperParamQS.FoldHpTestQS  = foldhpTestQS;
        
        pmModelRes = struct('ModelType', modeltype, 'RunParams', mbasefilename);
        pmModelRes.pmNDayRes(1) = pmDayRes;
        
        pmDayRes.Folds     = [];
        pmDayRes.Pred      = [];
        pmDayRes.PredSort  = [];
        pmDayRes.LabelSort = [];
        pmDayRes.Precision = [];
        pmDayRes.Recall    = [];
        pmDayRes.TPR       = [];
        pmDayRes.FPR       = [];

        pmBSAllQS(combnbr).NDayQS(1) = pmDayRes;
        
        pmFeatureParamsRow = pmThisFeatureParams(fs,:);
        pmModelParamsRow   = pmModelParams(mp,:);

        fprintf('\n');

        tic
        basedir = setBaseDir();
        subfolder = 'MatlabSavedVariables';
        outputfilename = sprintf('%s ModelResults.mat', mbasefilename);
        fprintf('Saving model output variables to file %s\n', outputfilename);
        save(fullfile(basedir, subfolder, outputfilename), ...
            'pmTestFeatureIndex', 'pmTestMuIndex', 'pmTestSigmaIndex', 'pmTestNormFeatures', ...
            'pmTestIVLabels', 'pmTestExLabels', 'pmTestABLabels', 'pmTestExLBLabels', 'pmTestExABLabels', 'pmTestExABxElLabels', ...
            'pmTrCVFeatureIndex', 'pmTrCVMuIndex', 'pmTrCVSigmaIndex', 'pmTrCVNormFeatures', ...
            'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels', 'pmTrCVExABLabels', 'pmTrCVExABxElLabels',...
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmAMPredUpd', ...
            'pmHyperParamQS');
        toc
        fprintf('\n');
        
        tic
        % save hyperparameter quality scores table
        basedir = setBaseDir();
        subfolder = 'ExcelFiles';
        hpfilename = sprintf('%s HP.xlsx', mbasefilename);
        fprintf('Saving hyperparameter quality scores results to excel file %s\n', hpfilename);
        writetable(pmHyperParamQS.HyperParamQS, fullfile(basedir, subfolder, hpfilename), 'Sheet', 'HyperParamQS');
        writetable(pmHyperParamQS.FoldHpTrQS,   fullfile(basedir, subfolder, hpfilename), 'Sheet', 'TrainQS');
        writetable(pmHyperParamQS.FoldHpCVQS,   fullfile(basedir, subfolder, hpfilename), 'Sheet', 'CrossValQS');
        writetable(pmHyperParamQS.FoldHpTestQS, fullfile(basedir, subfolder, hpfilename), 'Sheet', 'TestQS');
        toc
        fprintf('\n');
        
    end
end

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('BSQ-%s-%s-%s%s.mat', basefeatureparamfile, basemodelparamfile, basehpparamfile, rtsuffix);
fprintf('Saving bootstrap results to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
     'pmBSAllQS', 'basefeatureparamfile', 'basemodelparamfile', 'nbssamples', 'ncombinations');
toc
fprintf('\n');

beep on;
beep;
