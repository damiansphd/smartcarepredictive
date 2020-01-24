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
if ~ismember(basehpparamfile, '')
    hpparamfile          = strcat(basehpparamfile, '.xlsx');
    pmHyperParams        = readtable(fullfile(basedir, subfolder, hpparamfile));
    [lrarray, ntrarray, mlsarray, mnsarray, fvsarray, nlr, ntr, nmls, nmns, nfvs] = setHyperParameterArrays(pmHyperParams);
    
else
    lrarray = 1; ntrarray = 1; mlsarray = 1; mnsarray = 1; fvsarray = 1; nlr = 1; ntr = 1; nmls = 1; nmns = 1; nfvs = 1;
end
hpsuffix = sprintf('lr%.2f-%.2flc%d-%dml%d-%dns%d-%dfv%.2f-%.2f', ...
                    lrarray(1),  lrarray(end),  ntrarray(1), ntrarray(end), ...
                    mlsarray(1), mlsarray(end), mnsarray(1), mnsarray(end), ...
                    fvsarray(1), fvsarray(end));
                
nbssamples = 50; % temporary hardcoding - replace with model parameter when have more time
epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time

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
        mbasefilename = sprintf('%s%s', mbasefilename, hpsuffix);
        
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
        nnormfeatures = size(pmTrCVNormFeatures, 2);
        
        [labels] = setLabelsForLabelMethod(pmModelParams.labelmethod(mp), pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);
        trcvlabels = labels(:);
        
        % for the 'Ex Start to Treatment' label, there is only one task.
        % for the other label methods, use the predictionduration from the
        % feature parameters record
        if (pmModelParams.labelmethod(mp) == 5 || pmModelParams.labelmethod(mp) == 6)
            predictionduration = 1;
        else
            fprintf('These models only support label method 5 and 6\n');
            break;
        end
        
        if isequal(pmModelParams.ModelVer{mp}, 'vPM10')
            modeltype = 'Random Forest';
            mmethod   = 'Bag';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM11')
            modeltype = 'RUS Boosted Tree Ensemble';
            mmethod   = 'RUSBoost';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM12')
            modeltype = 'Logit Boosted Tree Ensemble';
            mmethod   = 'LogitBoost';
        end
        
        fprintf('Running %s model for Label method %d\n', modeltype, pmModelParams.labelmethod(mp));
        fprintf('\n');
        
        nhpcomb      = nlr * ntr * nmls * nmns * nfvs;
 
        pmHyperParamQS = struct('FeatureParams', [], 'ModelParams', []);
        pmHyperParamQS.FeatureParams = pmThisFeatureParams(fs, :);
        pmHyperParamQS.ModelParams   = pmModelParams(mp,:);
        
        hyperparamQS = table('Size',[nhpcomb, 16], ...
                        'VariableTypes', {'double', 'double', 'double', 'double', 'double', ...
                                          'double', 'double', 'double', 'double', 'double', 'double',...
                                          'double', 'double', 'double', 'double', 'double'}, ...
                        'VariableNames', {'LearnRate', 'NumTrees', 'MinLeafSize', 'MaxNumSplit', 'FracVarsToSample', ...
                                          'AvgLoss', 'PScore', 'ElecPScore', 'AvgEpiTPred', 'AvgEpiFPred', 'AvgEPV', ...
                                          'PRAUC', 'ROCAUC', 'Acc', 'PosAcc', 'NegAcc'});    

        for lr = 1:nlr
            lrval = lrarray(lr);
            for tr = 1:ntr
                ntrval = ntrarray(tr);
                for mls = 1:nmls
                    mlsval = mlsarray(mls);
                    for mns = 1:nmns
                        for fvs = 1:nfvs
                            fvsval = fvsarray(fvs);
                        
                            tic
                            mnsval = mnsarray(mns);
                            hpcomb = ((lr - 1) * ntr * nmls * nmns * nfvs) + ((tr - 1) * nmls * nmns * nfvs) + ((mls - 1) * nmns * nfvs) + ((mns - 1) * nfvs) + fvs;

                            fprintf('%2d of %2d Hyperparameter combinations\n', hpcomb, nhpcomb);

                            pmModelRes = struct('ModelType', modeltype, 'RunParams', mbasefilename);

                            pmDayRes = struct('Folds'      , [], 'LLH', 0.0        , 'Pred'       , zeros(ntrcvexamples,1), ...
                                              'PredSort'   , zeros(ntrcvexamples,1), 'LabelSort'  , zeros(ntrcvexamples,1), ...
                                              'Precision'  , zeros(ntrcvexamples,1), 'Recall'     , zeros(ntrcvexamples,1), ...
                                              'TPR'        , zeros(ntrcvexamples,1), 'FPR'        , zeros(ntrcvexamples,1), ...
                                              'Loss'       , zeros(nfolds, 1)      , 'AvgLoss'    , 0.0, ...
                                              'PRAUC'      , 0.0                   , 'ROCAUC'     , 0.0, ...
                                              'Acc'        , 0.0                   , 'PosAcc'     , 0.0, ...
                                              'NegAcc'     , 0.0                   , ...
                                              'HighP'      , 0.0                   , 'MedP'       , 0.0, ....
                                              'LowP'       , 0.0                   , 'ElecHighP'  , 0.0, ...
                                              'ElecMedP'   , 0.0                   , 'ElecLowP'   , 0.0, ...
                                              'PScore'     , 0.0                   , 'ElecPScore' , 0.0, ...
                                              'AvgEpiTPred', 0.0                   , 'AvgEpiFPred', 0.0, ...
                                              'AvgEPV'     , 0.0                   , ...
                                              'bsPRAUC'    , zeros(nbssamples,1)   , 'bsROCAUC'   , zeros(nbssamples,1), ...
                                              'bsAcc'      , zeros(nbssamples,1)   , 'bsPosAcc'   , zeros(nbssamples,1), ...
                                              'bsNegAcc'   , zeros(nbssamples,1));

                            for fold = 1:nfolds

                                fprintf('CV Fold %d: ', fold);

                                [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
                                 pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] ...
                                    = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);

                                if ismember(pmModelParams.ModelVer{mp}, {'vPM10', 'vPM11', 'vPM12'})
                                    fprintf('Training...');
                                    rng(2); % for reproducibility
                                    template = templateTree('Reproducible', true, ...
                                        'MinLeafSize', mlsval, ...
                                        'MaxNumSplits', mnsval, ...
                                        'NumVariablesToSample', floor(fvsval * nnormfeatures));
                                    pmDayRes.Folds(fold).Model = compact(fitcensemble(pmTrNormFeatures, trlabels, ...
                                        'Method', mmethod, ...
                                        'NumLearningCycles', ntrval, ...
                                        'Learners', template, ...
                                        'PredictorNames', pmNormFeatNames));
                                    pmDayRes.Loss(fold) = loss(pmDayRes.Folds(fold).Model, pmCVNormFeatures, cvlabels, 'Lossfun', 'hinge');
                                    fprintf('Loss fcn = %.6f ', pmDayRes.Loss(fold));
                                    fprintf('Predicting on CV set...');
                                    [~, tempscore] = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures);
                                    tempscore = tempscore ./ sum(tempscore, 2);
                                    pmDayRes.Pred(cvidx) = tempscore(:, 2);
                                
                                %elseif isequal(pmModelParams.ModelVer{mp}, 'vPM11')
                                %    fprintf('Training...');
                                %    rng(2); % for reproducibility
                                %    template = templateTree('Reproducible', true, ...
                                %        'MinLeafSize', mlsval, ...
                                %        'MaxNumSplits', mnsval);
                                %    pmDayRes.Folds(fold).Model = compact(fitcensemble(pmTrNormFeatures, trlabels, ...
                                %        'Method', mmethod, ...
                                %        'NumLearningCycles', lcval, ...
                                %        'Learners', template));
                                %    fprintf('Predicting on CV set...');
                                %    [templabel, tempscore] = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures);
                                %    pmDayRes.Pred(cvidx) = tempscore(:, 2);
                                %elseif isequal(pmModelParams.ModelVer{mp}, 'vPM12')
                                %    fprintf('Training...');
                                %    rng(2); % for reproducibility
                                %    template = templateTree('Reproducible', true, 'MinLeafSize', mlsval, 'MaxNumSplits', mnsval);
                                %    pmDayRes.Folds(fold).Model = compact(fitcensemble(pmTrNormFeatures, trlabels, ...
                                %        'Method', mmethod, ...
                                %        'NumLearningCycles', lcval, ...
                                %        'Learners', template));
                                %    fprintf('Predicting on CV set...');
                                %    pmDayRes.Pred(cvidx) = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures);
                                %else
                                %    fprintf('Unknown model version\n');
                                %    return
                                
                                
                                end
                                fprintf('Done\n');

                            end

                            fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
                            [pmDayRes, pmAMPredUpd] = calcPredQualityScore(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmTrCVPatientSplit);
                            pmDayRes = calcModelQualityScores(pmDayRes, trcvlabels, ntrcvexamples);
                            pmDayRes = calcAvgEpiPred(pmDayRes, pmTrCVFeatureIndex, trcvlabels, epilen);                       

                            fprintf('\n');

                            hyperparamQS.LearnRate(hpcomb)        = lrval;
                            hyperparamQS.NumTrees(hpcomb)         = ntrval;
                            hyperparamQS.MinLeafSize(hpcomb)      = mlsval;
                            hyperparamQS.MaxNumSplit(hpcomb)      = mnsval;
                            hyperparamQS.FracVarsToSample(hpcomb) = fvsval;
                            hyperparamQS.AvgLoss(hpcomb)          = mean(pmDayRes.Loss);
                            hyperparamQS.PScore(hpcomb)           = pmDayRes.PScore;
                            hyperparamQS.ElecPScore(hpcomb)       = pmDayRes.ElecPScore;
                            hyperparamQS.PRAUC(hpcomb)            = pmDayRes.PRAUC;
                            hyperparamQS.ROCAUC(hpcomb)           = pmDayRes.ROCAUC;
                            hyperparamQS.Acc(hpcomb)              = pmDayRes.Acc;
                            hyperparamQS.PosAcc(hpcomb)           = pmDayRes.PosAcc;
                            hyperparamQS.NegAcc(hpcomb)           = pmDayRes.NegAcc;
                            hyperparamQS.AvgEpiTPred(hpcomb)      = pmDayRes.AvgEpiTPred;
                            hyperparamQS.AvgEpiFPred(hpcomb)      = pmDayRes.AvgEpiFPred;
                            hyperparamQS.AvgEPV(hpcomb)           = pmDayRes.AvgEPV;

                            toc
                            fprintf('\n');
                        end
                    end
                end
            end
        end
        
        pmHyperParamQS.HyperParamQS   = hyperparamQS;
        pmModelRes.pmNDayRes(1) = pmDayRes;
        
        pmFeatureParamsRow = pmThisFeatureParams(fs,:);
        pmModelParamsRow   = pmModelParams(mp,:);

        fprintf('\n');

        tic
        basedir = setBaseDir();
        subfolder = 'MatlabSavedVariables';
        outputfilename = sprintf('%s ModelResults.mat', mbasefilename);
        fprintf('Saving output variables to file %s\n', outputfilename);
        save(fullfile(basedir, subfolder, outputfilename), ...
            'pmTestFeatureIndex', 'pmTestMuIndex', 'pmTestSigmaIndex', 'pmTestNormFeatures', ...
            'pmTestIVLabels', 'pmTestExLabels', 'pmTestABLabels', 'pmTestExLBLabels', 'pmTestExABLabels', 'pmTestExABxElLabels', ...
            'pmTrCVFeatureIndex', 'pmTrCVMuIndex', 'pmTrCVSigmaIndex', 'pmTrCVNormFeatures', ...
            'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels', 'pmTrCVExABLabels', 'pmTrCVExABxElLabels',...
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmAMPredUpd', 'pmHyperParamQS');
        toc
        fprintf('\n');
        
        tic
        % save hyperparameter quality scores table
        basedir = setBaseDir();
        subfolder = 'ExcelFiles';
        hpfilename = sprintf('%s HP.xlsx', mbasefilename);
        fprintf('Saving hyperparameter quality scores results to excel file %s\n', hpfilename);
        writetable(pmHyperParamQS.HyperParamQS, fullfile(basedir, subfolder, hpfilename), 'Sheet', 'HyperParamQS');
        toc
        
    end
end

beep on;
beep;
