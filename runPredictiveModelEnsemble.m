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
hpsuffix = sprintf('lr%.2f-%.2fnt%d-%dml%d-%dns%d-%dfv%.2f-%.2f', ...
                    lrarray(1),  lrarray(end),  ntrarray(1), ntrarray(end), ...
                    mlsarray(1), mlsarray(end), mnsarray(1), mnsarray(end), ...
                    fvsarray(1), fvsarray(end));
                
[bsmode, validresponse] = selectBSMode();
if validresponse == 0
    return;
end

[runmode, validresponse] = selectRunMode();
if validresponse == 0
    return;
end
                
nbssamples = 50; % temporary hardcoding - replace with model parameter when have more time
epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time

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
        
        [modeltype, mmethod] = setModelTypeAndMethod(pmModelParams.ModelVer{mp});
        fprintf('Running %s model for Label method %d\n', modeltype, pmModelParams.labelmethod(mp));
        fprintf('\n');
        
        nhpcomb      = nlr * ntr * nmls * nmns * nfvs;
 
        %pmHyperParamQS = struct('FeatureParams', [], 'ModelParams', []);
        %pmHyperParamQS.FeatureParams = pmThisFeatureParams(fs, :);
        %pmHyperParamQS.ModelParams   = pmModelParams(mp,:);
        
        [hyperparamQS, hyperparamqsrow, foldhpTrQS, foldhpCVQS, foldhprow] = createHpQSTables(nhpcomb);
        
        %hyperparamQS = table('Size',[nhpcomb, 20], ...
        %                'VariableTypes', {'double', 'double', 'double', 'double', 'double', ...
        %                                  'double', 'double', 'double', 'double', 'double', 'double',...
        %                                  'double', 'double', 'double', 'double', 'double', ...
        %                                  'double', 'double', 'double', 'double'}, ...
        %                'VariableNames', {'LearnRate', 'NumTrees', 'MinLeafSize', 'MaxNumSplit', 'FracVarsToSample', ...
        %                                  'AvgLoss', 'PScore', 'ElecPScore', 'AvgEpiTPred', 'AvgEpiFPred', 'AvgEPV', ...
        %                                  'PRAUC', 'ROCAUC', 'Acc', 'PosAcc', 'NegAcc', ...
        %                                  'MaxNumNodes', 'AvgNumNodes', 'MaxBranchNodes', 'AvgBranchNodes'});
        %hyperparamqsrow = hyperparamQS(1, :);
        % 
        %temp = array2table(1);
        %temp.Properties.VariableNames{'Var1'} = 'Fold';
        %pmFoldHpTrQS = [temp, hyperparamQS(1, :)];
        %foldhprow = pmFoldHpTrQS;
        %pmFoldHpTrQS(1,:) = [];
        %pmFoldHpCVQS = [temp, hyperparamQS(1, :)];
        %pmFoldHpCVQS(1,:) = [];
        
        plotsubfolder = sprintf('Plots/%s', mbasefilename);
        mkdir(fullfile(basedir, plotsubfolder));

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

                            %pmModelRes = struct('ModelType', modeltype, 'RunParams', mbasefilename);

                            pmDayRes = createModelDayResStuct(ntrcvexamples, nfolds, nbssamples);

                            for fold = 1:nfolds

                                fprintf('Fold %d: ', fold);

                                [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
                                 pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] ...
                                    = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);
                                
                                if ismember(pmModelParams.ModelVer{mp}, {'vPM10', 'vPM11', 'vPM12', 'vPM13'})
                                    % train model
                                    fprintf('Training...');
                                    [pmDayRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmDayRes, pmTrNormFeatures, trlabels, ...
                                                        pmNormFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                                    fprintf('Done\n');
                                    
                                    % create predictions on training set
                                    ntrexamples = size(pmTrNormFeatures, 1);
                                    pmTrRes     = createModelDayResStuct(ntrexamples, 1, 0);
                                    pmTrRes     = predictPredModel(pmTrRes, pmDayRes.Folds(fold).Model, pmTrNormFeatures, trlabels, lossfunc);
                                    fprintf('Tr: ');
                                    fprintf('LR: %.2f NT: %3d MLS: %3d MNS: %3d FVS: %.2f- ', lrval, ntrval, mlsval, mnsval, fvsval);
                                    fprintf('Loss: %.6f ', pmTrRes.Loss);
                                    
                                    % calculate training set quality scores
                                    pmTrRes        = calcAllQualScores(pmTrRes, trlabels, ntrexamples, pmAMPred, pmTrFeatureIndex, pmTrCVPatientSplit, epilen);
                                    foldhprow.Fold = fold;
                                    foldhprow      = setHyperParamQSrow(foldhprow, lrval, ntrval, mlsval, mnsval, fvsval, pmTrRes);
                                    foldhprow      = setHyperParamQSTreeInfo(foldhprow, pmDayRes.Folds(fold).Model);
                                    foldhpTrQS     = [foldhpTrQS; foldhprow];
                                    %filename = sprintf('%s-Tr-F%d', mbasefilename, fold);
                                    %plotPRAndROCCurvesForPaper(pmTrRes, [] , 'na', plotsubfolder, filename);
                                    fprintf('\n');
                                    
                                    % create predictions on cv set
                                    ncvexamples    = size(pmCVNormFeatures, 1);
                                    pmCVRes        = createModelDayResStuct(ncvexamples, 1, 0);
                                    pmCVRes        = predictPredModel(pmCVRes, pmDayRes.Folds(fold).Model, pmCVNormFeatures, cvlabels, lossfunc);
                                    fprintf('CV: ');
                                    fprintf('LR: %.2f NT: %3d MLS: %3d MNS: %3d FVS: %.2f- ', lrval, ntrval, mlsval, mnsval, fvsval);
                                    fprintf('Loss: %.6f ', pmCVRes.Loss);
                                    
                                    % calculate cross validation set quality scores
                                    pmCVRes        = calcAllQualScores(pmCVRes, cvlabels, ncvexamples, pmAMPred, pmCVFeatureIndex, pmTrCVPatientSplit, epilen);
                                    foldhprow.Fold = fold;
                                    foldhprow      = setHyperParamQSrow(foldhprow, lrval, ntrval, mlsval, mnsval, fvsval, pmCVRes);
                                    foldhprow      = setHyperParamQSTreeInfo(foldhprow, pmDayRes.Folds(fold).Model);
                                    foldhpCVQS     = [foldhpCVQS; foldhprow];
                                    %filename = sprintf('%s-CV-F%d', mbasefilename, fold);
                                    %plotPRAndROCCurvesForPaper(pmCVRes, '', '', plotsubfolder, filename);
                                    fprintf('\n');
                                    
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
                            [pmDayRes, pmAMPredUpd] = calcAllQualScores(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmTrCVPatientSplit, epilen);
                            
                            fprintf('\n');
                            
                            hyperparamQS(hpcomb, :) = setHyperParamQSrow(hyperparamqsrow, lrval, ntrval, mlsval, mnsval, fvsval, pmDayRes);
                            
                            toc
                            fprintf('\n');
                        end
                    end
                end
            end
        end
        
        pmHyperParamQS = struct('FeatureParams', [], 'ModelParams', []);
        pmHyperParamQS.FeatureParams = pmThisFeatureParams(fs, :);
        pmHyperParamQS.ModelParams   = pmModelParams(mp,:);
        pmHyperParamQS.HyperParamQS  = hyperparamQS;
        pmHyperParamQS.FoldHpTrQS    = foldhpTrQS;
        pmHyperParamQS.FoldHpCVQS    = foldhpCVQS;
        
        pmModelRes = struct('ModelType', modeltype, 'RunParams', mbasefilename);
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
        writetable(foldhpTrQS, fullfile(basedir, subfolder, hpfilename), 'Sheet', 'TrainQS');
        writetable(foldhpCVQS, fullfile(basedir, subfolder, hpfilename), 'Sheet', 'CrossValQS');
        toc
        
    end
end

beep on;
beep;
