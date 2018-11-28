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

for fs = 1:nfeatureparamsets
    
    for mp = 1:nmodelparamsets 
    
        tic
        basedir = setBaseDir();
        subfolder = 'MatlabSavedVariables';
        fbasefilename = generateFileNameFromFeatureParams(pmThisFeatureParams(fs,:));
        featureinputmatfile = sprintf('%s.mat',fbasefilename);
        fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
        load(fullfile(basedir, subfolder, featureinputmatfile));
        psplitfile = sprintf('%spatientsplit.mat', pmThisFeatureParams.StudyDisplayName{fs});
        fprintf('Loading patient splits from file %s\n', psplitfile);
        load(fullfile(basedir, subfolder, psplitfile));
        toc
        fprintf('\n');
        mbasefilename = generateFileNameFromModelParams(fbasefilename, pmModelParams(mp,:));

        predictionduration = pmThisFeatureParams.predictionduration(fs);
        nexamples = size(pmNormFeatures,1);
        
        % separate out test data and keep aside
        [pmTestFeatureIndex, pmTestFeatures, pmTestNormFeatures, pmTestIVLabels, pmTestExLabels, ...
         pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, pmTrCVIVLabels, pmTrCVExLabels, ...
         pmTrCVPatientSplit, nfolds] = ...
            splitTestFeatures(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmExLabels, pmPatientSplit, nsplits);
        
        ntrcvexamples = size(pmTrCVNormFeatures,1);
        
        for n = 1:predictionduration
            
            fprintf('Running Logistic Regression model for Label %d\n', n);
            pmModelRes = struct('ModelType', 'Logistic Regression', 'RunParams', mbasefilename);
            
            pmDayRes = struct('Model'    , []                    , 'Pred'     , zeros(ntrcvexamples,1), ...
                              'PredSort' , zeros(ntrcvexamples,1), 'LabelSort', zeros(ntrcvexamples,1), ...
                              'Precision', zeros(ntrcvexamples,1), 'Recall'   , zeros(ntrcvexamples,1), ...
                              'TPR'      , zeros(ntrcvexamples,1), 'FPR'      , zeros(ntrcvexamples,1), ...
                              'PRAUC'    , 0.0                   , 'ROCAUC'   , 0.0, ...
                              'Accuracy' , 0.0);
                          
            if pmModelParams.labelmethod(mp) == 1
                    trcvlabels = pmTrCVIVLabels(:,n);
                else
                    trcvlabels = pmTrCVExLabels(:,n);
            end
                
            for fold = 1:nfolds
                
                tic
                fprintf('CV Fold %d: ', fold);
                
                [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrIVLabels, pmTrExLabels, ...
                 pmCVFeatureIndex, pmCVFeatures, pmCVNormFeatures, pmCVIVLabels, pmCVExLabels, cvidx] ...
                    = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, pmTrCVIVLabels, pmTrCVExLabels, ...
                              pmTrCVPatientSplit, fold);

                if pmModelParams.labelmethod(mp) == 1
                    trlabels = pmTrIVLabels(:,n);
                else
                    trlabels = pmTrExLabels(:,n);
                end
                
                fprintf('Training...');
                pmDayRes.Model = compact(fitglm(pmTrNormFeatures, trlabels, ...
                    'linear', ...
                    'Distribution', 'binomial', ...
                    'Link', 'logit'));
                
                fprintf('Predicting on CV set...');
                pmDayRes.Pred(cvidx) = predict(pmDayRes.Model, pmCVNormFeatures);
                
                fprintf('Done\n');
                
            end
            
            [pmDayRes.PredSort, sortidx] = sort(pmDayRes.Pred, 'descend');
            pmDayRes.LabelSort = trcvlabels(sortidx);

            for a = 1:ntrcvexamples
                TP        = sum(pmDayRes.LabelSort(1:a) == 1);
                FP        = sum(pmDayRes.LabelSort(1:a) == 0);
                TN        = sum(pmDayRes.LabelSort(a+1:ntrcvexamples) == 0);
                FN        = sum(pmDayRes.LabelSort(a+1:ntrcvexamples) == 1);
                pmDayRes.Precision(a) = TP / (TP + FP);
                pmDayRes.Recall(a)    = TP / (TP + FN); 
                pmDayRes.TPR(a)       = pmDayRes.Recall(a);
                pmDayRes.FPR(a)       = FP / (FP + TN);
            end
    
            pmDayRes.PRAUC  = trapz(pmDayRes.Recall, pmDayRes.Precision);
            pmDayRes.ROCAUC = trapz(pmDayRes.FPR   , pmDayRes.TPR);
            pmDayRes.Accuracy = sum(abs(pmDayRes.PredSort - pmDayRes.LabelSort))/ntrcvexamples;
            fprintf('PR AUC = %.2f, ROC AUC = %.2f, Accuracy = %.2f\n', pmDayRes.PRAUC, pmDayRes.ROCAUC, pmDayRes.Accuracy);
            fprintf('\n');
            
            pmModelRes.pmNDayRes(n) = pmDayRes;
        end

        pmFeatureParamsRow = pmThisFeatureParams(fs,:);
        pmModelParamsRow   = pmModelParams(mp,:);
        
        tic
        basedir = setBaseDir();
        subfolder = 'MatlabSavedVariables';
        outputfilename = sprintf('%s ModelResults.mat', mbasefilename);
        fprintf('Saving output variables to file %s\n', outputfilename);
        save(fullfile(basedir, subfolder, outputfilename), ...
            'pmTestFeatureIndex', 'pmTestFeatures', 'pmTestNormFeatures', 'pmTestIVLabels', 'pmTestExLabels', ...
            'pmTrCVFeatureIndex', 'pmTrCVFeatures', 'pmTrCVNormFeatures', 'pmTrCVIVLabels', 'pmTrCVExLabels', ...
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
        toc
        fprintf('\n');
    end
end

