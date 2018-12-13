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
        if ~isequal(pmThisFeatureParams.Version{fs}, pmModelParams.Version{mp})
            mbasefilename = strrep(mbasefilename, pmThisFeatureParams.Version{fs}, pmModelParams.Version{mp});
        end

        tic
        % for the 'Ex Start to Treatment' label, there is only one task.
        % for the other label methods, use the predictionduration from the
        % feature parameters record
        if (pmModelParams.labelmethod(mp) == 5 || pmModelParams.labelmethod(mp) == 6)
            predictionduration == 1
        else
            predictionduration = pmThisFeatureParams.predictionduration(fs);
        end
        
        nexamples = size(pmNormFeatures,1);
        
        % separate out test data and keep aside
        [pmTestFeatureIndex, pmTestFeatures, pmTestNormFeatures, pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, ...
         pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, ...
         pmTrCVPatientSplit, nfolds] = ...
            splitTestFeatures(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmExLabels, pmABLabels, pmExLBLabels, pmPatientSplit, nsplits);
        
        ntrcvexamples = size(pmTrCVNormFeatures,1);
        
        pmModelRes = struct('ModelType', 'Logistic Regression', 'RunParams', mbasefilename);
        
        for n = 1:predictionduration
            
            fprintf('Running Logistic Regression model for Label %d\n', n);
            
            pmDayRes = struct('Model'    , [], 'LLH', 0.0        , 'Pred'     , zeros(ntrcvexamples,1), ...
                              'PredSort' , zeros(ntrcvexamples,1), 'LabelSort', zeros(ntrcvexamples,1), ...
                              'Precision', zeros(ntrcvexamples,1), 'Recall'   , zeros(ntrcvexamples,1), ...
                              'TPR'      , zeros(ntrcvexamples,1), 'FPR'      , zeros(ntrcvexamples,1), ...
                              'PRAUC'    , 0.0                   , 'ROCAUC'   , 0.0, ...
                              'Accuracy' , 0.0);
                          
            if     pmModelParams.labelmethod(mp) == 1
                trcvlabels = pmTrCVIVLabels(:,n);
            elseif pmModelParams.labelmethod(mp) == 2
                trcvlabels = pmTrCVExLabels(:,n);
            elseif pmModelParams.labelmethod(mp) == 3
                trcvlabels = pmTrCVABLabels(:,n);
            elseif pmModelParams.labelmethod(mp) == 4
                trcvlabels = pmTrCVExLBLabels(:,n);
            else
                fprintf('Unknown label method\n');
                return;
            end
                
            for fold = 1:nfolds
                
                fprintf('CV Fold %d\n', fold);
                
                [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, trlabels, ...
                 pmCVFeatureIndex, pmCVFeatures, pmCVNormFeatures, cvlabels, cvidx] ...
                    = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);

                %if     pmModelParams.labelmethod(mp) == 1
                %    trlabels = pmTrIVLabels(:,n);
                %elseif pmModelParams.labelmethod(mp) == 2
                %    trlabels = pmTrExLabels(:,n);
                %elseif pmModelParams.labelmethod(mp) == 3
                %    trlabels = pmTrABLabels(:,n);
                %elseif pmModelParams.labelmethod(mp) == 4
                %    trlabels = pmTrExLBLabels(:,n);
                %else
                %    fprintf('Unknown label method\n');
                %    return;
                %end
                
                
                fprintf('Training...');
                if isequal(pmModelParams.Version{mp}, 'vPM1')
                    pmDayRes.Model = compact(fitglm(pmTrNormFeatures, trlabels, ...
                        'linear', ...
                        'Distribution', 'binomial', ...
                        'Link', 'logit'));
                
                    fprintf('Predicting on CV set...');
                    pmDayRes.Pred(cvidx) = predict(pmDayRes.Model, pmCVNormFeatures);
                    
                elseif isequal(pmModelParams.Version{mp}, 'vPM2')
                    [pmDayRes.Model, pmDayRes.LLH] = logitBin(pmTrNormFeatures', trlabels', 1.0);
                    fprintf('Predicting on CV set...');
                    [~, temppred] = logitBinPred(pmDayRes.Model, pmCVNormFeatures');
                    pmDayRes.Pred(cvidx) = temppred';
                else
                    fprintf('Unknown model version\n');
                    return
                end
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
    
            pmDayRes.PRAUC  = 100 * trapz(pmDayRes.Recall, pmDayRes.Precision);
            pmDayRes.ROCAUC = 100 * trapz(pmDayRes.FPR   , pmDayRes.TPR);
            pmDayRes.Accuracy = sum(abs(pmDayRes.PredSort - pmDayRes.LabelSort))/ntrcvexamples;
            fprintf('PR AUC = %.2f, ROC AUC = %.2f, Accuracy = %.2f\n', pmDayRes.PRAUC, pmDayRes.ROCAUC, pmDayRes.Accuracy);
            fprintf('\n');
            
            pmModelRes.pmNDayRes(n) = pmDayRes;
            
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
            'pmTestFeatureIndex', 'pmTestFeatures', 'pmTestNormFeatures', 'pmTestIVLabels', 'pmTestExLabels', 'pmTestABLabels', 'pmTestExLBLabels', ...
            'pmTrCVFeatureIndex', 'pmTrCVFeatures', 'pmTrCVNormFeatures', 'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels',...
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
        toc
        fprintf('\n');
    end
end

beep on;
beep;
