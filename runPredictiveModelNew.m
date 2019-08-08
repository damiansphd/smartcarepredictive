 clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
basefeatureparamfile = selectFeatureParameters();
featureparamfile = strcat(basefeatureparamfile, '.xlsx');
pmThisFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

basemodelparamfile = selectModelRunParameters();
modelparamfile = strcat(basemodelparamfile, '.xlsx');
pmModelParams = readtable(fullfile(basedir, subfolder, modelparamfile));

nfeatureparamsets = size(pmThisFeatureParams,1);
nmodelparamsets   = size(pmModelParams,1);
ncombinations     = nfeatureparamsets * nmodelparamsets;

nbssamples = 50; % temporary hardcoding - replace with model parameter when have more time

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
        
        pmBSAllQS(combnbr).FeatureParams = pmThisFeatureParams(fs, :);
        pmBSAllQS(combnbr).ModelParams   = pmModelParams(mp,:);

        tic
        % for the 'Ex Start to Treatment' label, there is only one task.
        % for the other label methods, use the predictionduration from the
        % feature parameters record
        if (pmModelParams.labelmethod(mp) == 5 || pmModelParams.labelmethod(mp) == 6)
            predictionduration = 1;
        else
            predictionduration = pmThisFeatureParams.predictionduration(fs);
        end

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
        
        ntrcvexamples = size(pmTrCVNormFeatures,1);
        
        if isequal(pmModelParams.ModelVer{mp}, 'vPM1')
            modeltype = 'MATLAB Logistic Regression';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM2')
            modeltype = 'PRML Logistic Regression';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM3')
            modeltype = 'ADA Boost Tree Ensemble';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM4')
            modeltype = 'Decision Tree';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM5')
            modeltype = 'RUS Boost Tree Ensemble';
        elseif isequal(pmModelParams.ModelVer{mp}, 'vPM6')
            modeltype = 'Manual Model';
        elseif ismember(pmModelParams.ModelVer{mp}, {'vPM7', 'vPM8', 'vPM9'})
            modeltype = 'Clinical Fuchs Model';    
        end
        
        pmModelRes = struct('ModelType', modeltype, 'RunParams', mbasefilename);
        
        for n = 1:predictionduration
            
            fprintf('Running %s model for Label %d\n', modeltype, n);
            
            pmDayRes = struct('Folds'     , [], 'LLH', 0.0        , 'Pred'      , zeros(ntrcvexamples,1), ...
                              'PredSort'  , zeros(ntrcvexamples,1), 'LabelSort' , zeros(ntrcvexamples,1), ...
                              'Precision' , zeros(ntrcvexamples,1), 'Recall'    , zeros(ntrcvexamples,1), ...
                              'TPR'       , zeros(ntrcvexamples,1), 'FPR'       , zeros(ntrcvexamples,1), ...
                              'PRAUC'     , 0.0                   , 'ROCAUC'    , 0.0, ...
                              'Acc'       , 0.0                   , 'PosAcc'    , 0.0, ...
                              'NegAcc'    , 0.0                   , ...
                              'HighP'     , 0.0                   , 'MedP'      , 0.0, ....
                              'LowP'      , 0.0                   , 'ElecHighP' , 0.0, ...
                              'ElecMedP'  , 0.0                   , 'ElecLowP'  , 0.0, ...
                              'PScore'    , 0.0                   , 'ElecPScore', 0.0, ...
                              'bsPRAUC'   , zeros(nbssamples,1)   , 'bsROCAUC'  , zeros(nbssamples,1), ...
                              'bsAcc'     , zeros(nbssamples,1)   , 'bsPosAcc'  , zeros(nbssamples,1), ...
                              'bsNegAcc'  , zeros(nbssamples,1));
                              
            [labels] = setLabelsForLabelMethod(pmModelParams.labelmethod(mp), pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);
            trcvlabels = labels(:,n);
            
            for fold = 1:nfolds

                fprintf('CV Fold %d\n', fold);

                [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
                 pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] ...
                    = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);

                if isequal(pmModelParams.ModelVer{mp}, 'vPM1')
                    fprintf('Training...');
                    %pmDayRes.Model(fold) = compact(fitglm(pmTrNormFeatures, trlabels, ...
                    %    'linear', ...
                    %    'Distribution', 'binomial', ...
                    %    'Link', 'logit'));
                    pmDayRes.Folds(fold).Model = compact(fitglm(pmTrNormFeatures, trlabels, ...
                        'linear', ...
                        'Distribution', 'binomial', ...
                        'Link', 'logit'));
                    fprintf('Predicting on CV set...');
                    pmDayRes.Pred(cvidx) = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures);

                elseif isequal(pmModelParams.ModelVer{mp}, 'vPM2')
                    fprintf('Training...');
                    [pmDayRes.Folds(fold).Model, pmDayRes.LLH] = logitBin(pmTrNormFeatures', trlabels', 1.0);
                    fprintf('Predicting on CV set...');
                    [~, temppred] = logitBinPred(pmDayRes.Folds(fold).Model, pmCVNormFeatures');
                    pmDayRes.Pred(cvidx) = temppred';

                elseif isequal(pmModelParams.ModelVer{mp}, 'vPM3')
                    fprintf('Training...');
                    template = templateTree('MaxNumSplits', 40);
                    pmDayRes.Folds(fold).Model = compact(fitcensemble(pmTrNormFeatures, trlabels, ...
                        'Method', 'AdaBoostM1', ...
                        'NumLearningCycles', 60, ...
                        'Learners', template, ...
                        'LearnRate', 0.1));
                    fprintf('Predicting on CV set...');
                    pmDayRes.Pred(cvidx) = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures);

                elseif isequal(pmModelParams.ModelVer{mp}, 'vPM4')
                    fprintf('Training...');
                    pmDayRes.Folds(fold).Model = compact(fitctree(pmTrNormFeatures, trlabels, ...
                        'SplitCriterion', 'gdi', ...
                        'MaxNumSplits', 20, ...
                        'Surrogate', 'off'));
                    fprintf('Predicting on CV set...');
                    pmDayRes.Pred(cvidx) = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures);

                elseif isequal(pmModelParams.ModelVer{mp}, 'vPM5')
                    fprintf('Training...');
                    template = templateTree('MaxNumSplits', 40);
                    pmDayRes.Folds(fold).Model = compact(fitcensemble(pmTrNormFeatures, trlabels, ...
                        'Method', 'RUSBoost', ...
                        'NumLearningCycles', 60, ...
                        'Learners', template, ...
                        'LearnRate', 0.1, ...
                        'RatioToSmallest', 1));
                    fprintf('Predicting on CV set...');
                    pmDayRes.Pred(cvidx) = predict(pmDayRes.Folds(fold).Model, pmCVNormFeatures); 

                elseif isequal(pmModelParams.ModelVer{mp}, 'vPM6')
                    fprintf('Predicting with manual rules...');
                    pmDayRes.Pred(cvidx) = manualPredModel(pmInterpNormcube, ...
                        pmCVNormFeatures, pmDayRes.Pred(cvidx), measures, nmeasures, ...
                        npatients, maxdays, featureduration);
                    
                elseif ismember(pmModelParams.ModelVer{mp}, {'vPM7', 'vPM8', 'vPM9'})
                    fprintf('Predicting with clinical fuchs criteria...');
                    if isequal(pmModelParams.ModelVer{mp}, 'vPM7')
                        coughthresh = 0.3;
                        lfuncthresh = 0.1;
                    elseif isequal(pmModelParams.ModelVer{mp}, 'vPM8')
                        coughthresh = 0.2;
                        lfuncthresh = 0.1;
                    elseif isequal(pmModelParams.ModelVer{mp}, 'vPM9')
                        coughthresh = 0.1;
                        lfuncthresh = 0.1;
                    else
                        fprintf('**** Unknown Model Version ****\n');
                        return
                    end
                    pmDayRes.Pred(cvidx) = clinicalFuchsPredModel(pmCVMuIndex, pmCVSigmaIndex, ...
                        pmCVNormFeatures, pmDayRes.Pred(cvidx), measures, featureduration, coughthresh, lfuncthresh );

                else
                    fprintf('Unknown model version\n');
                    return
                end
                fprintf('Done\n');

            end
            
            fprintf('\n');
            fprintf('Real Data Qual Scores:    ');
            [pmDayRes, pmAMPredUpd] = calcPredQualityScore(pmDayRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmTrCVPatientSplit);
            pmDayRes = calcModelQualityScores(pmDayRes, trcvlabels, ntrcvexamples);
            fprintf('\n');
            
            fprintf('\n');
            
            % create quality metrics for bootstrapping samples
            for s = 1:nbssamples
                rng(s);
                sampleidx = generateResampledIdx(ntrcvexamples, ntrcvexamples);
                tempRes = pmDayRes;
                tempRes.Pred = tempRes.Pred(sampleidx);
                templabels = trcvlabels(sampleidx);
                
                
                fprintf('BS Sample %2d Qual Scores: ', s);
                tempRes = calcModelQualityScores(tempRes, templabels, ntrcvexamples);
                fprintf('\n');
                pmDayRes.bsPRAUC(s)    = tempRes.PRAUC;
                pmDayRes.bsROCAUC(s)   = tempRes.ROCAUC;
                pmDayRes.bsAcc(s)      = tempRes.Acc;
                pmDayRes.bsPosAcc(s)   = tempRes.PosAcc;
                pmDayRes.bsNegAcc(s)   = tempRes.NegAcc;   
            end
            
            fprintf('\n');
            
            pmModelRes.pmNDayRes(n) = pmDayRes;
            
            pmDayRes.Folds     = [];
            pmDayRes.Pred      = [];
            pmDayRes.PredSort  = [];
            pmDayRes.LabelSort = [];
            pmDayRes.Precision = [];
            pmDayRes.Recall    = [];
            pmDayRes.TPR       = [];
            pmDayRes.FPR       = [];
            
            pmBSAllQS(combnbr).NDayQS(n) = pmDayRes;
            
        end
        
        toc
        fprintf('\n');

        pmFeatureParamsRow = pmThisFeatureParams(fs,:);
        pmModelParamsRow   = pmModelParams(mp,:);

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
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmAMPredUpd');
        toc
        fprintf('\n');
    end
    
end

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('BSQ-%s-%s.mat', basefeatureparamfile, basemodelparamfile );
fprintf('Saving output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
     'pmBSAllQS', 'basefeatureparamfile', 'basemodelparamfile', 'nbssamples', 'ncombinations');
toc
fprintf('\n');

beep on;
beep;
