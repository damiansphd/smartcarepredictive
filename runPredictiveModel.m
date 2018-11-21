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

% cut and pasted here. Add back in below when ready to do train vs cv split
%tic
%fprintf('Split into training and validation sets\n');
%[pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrIVLabels, ...
%    pmValFeatureIndex, pmValFeatures, pmValNormFeatures, pmValIVLabels] = ...
%    splitTrainVsVal(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmFeatureParams.trainpct(rp)); 
%toc
%fprintf('\n');

for fs = 1:nfeatureparamsets
    
    for mp = 1:nmodelparamsets 
    
        tic
        basedir = setBaseDir();
        subfolder = 'MatlabSavedVariables';
        fbasefilename = generateFileNameFromFeatureParams(pmThisFeatureParams(fs,:));
        featureinputmatfile = sprintf('%s.mat',fbasefilename);
        fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
        load(fullfile(basedir, subfolder, featureinputmatfile));
        toc
        fprintf('\n');
        mbasefilename = generateFileNameFromModelParams(fbasefilename, pmModelParams(mp,:));

        predictionduration = pmThisFeatureParams.predictionduration(fs);
        nexamples = size(pmNormFeatures,1);
        
        pmModelRes = struct('ModelType', 'Logistic Regression', 'RunParams', mbasefilename);

        for n = 1:predictionduration
            tic
            fprintf('Running Logistic Regression model for Label %d\n', n);
            
            pmDayRes = struct('Model',     [], 'Pred',   [], 'PredSort', [], 'LabelSort', [], ...
            'TP'       , zeros(nexamples,1), 'FP'    , zeros(nexamples,1), 'TN' , zeros(nexamples,1), 'FN' , zeros(nexamples,1), ...
            'Precision', zeros(nexamples,1), 'Recall', zeros(nexamples,1), 'TPR', zeros(nexamples,1), 'FPR', zeros(nexamples,1), ...
            'PRAUC'    , 0.0               , 'ROCAUC', 0.0, 'Accuracy', 0.0);
            
            if pmModelParams.labelmethod(mp) == 1
                labels = pmIVLabels(:,n);
            else
                labels = pmExLabels(:,n);
            end
            
            pmDayRes.Model = compact(fitglm(pmNormFeatures, labels, ...
                'linear', ...
                'Distribution', 'binomial', ...
                'Link', 'logit'));
            
            pmDayRes.Pred = predict(pmDayRes.Model, pmNormFeatures);
            
            [pmDayRes.PredSort, sortidx] = sort(pmDayRes.Pred, 'descend');
            pmDayRes.LabelSort = labels(sortidx);

            for a = 1:nexamples
                pmDayRes.TP(a)        = sum(pmDayRes.LabelSort(1:a) == 1);
                pmDayRes.FP(a)        = sum(pmDayRes.LabelSort(1:a) == 0);
                pmDayRes.TN(a)        = sum(pmDayRes.LabelSort(a+1:nexamples) == 0);
                pmDayRes.FN(a)        = sum(pmDayRes.LabelSort(a+1:nexamples) == 1);
                pmDayRes.Precision(a) = pmDayRes.TP(a) / (pmDayRes.TP(a) + pmDayRes.FP(a));
                pmDayRes.Recall(a)    = pmDayRes.TP(a) / (pmDayRes.TP(a) + pmDayRes.FN(a)); 
                pmDayRes.TPR(a)       = pmDayRes.Recall(a);
                pmDayRes.FPR(a)       = pmDayRes.FP(a) / (pmDayRes.FP(a) + pmDayRes.TN(a));
            end
    
            pmDayRes.PRAUC  = trapz(pmDayRes.Recall, pmDayRes.Precision);
            pmDayRes.ROCAUC = trapz(pmDayRes.FPR   , pmDayRes.TPR);
            pmDayRes.Accuracy = sum(abs(pmDayRes.PredSort - pmDayRes.LabelSort))/nexamples;
            fprintf('PR AUC = %.2f, ROC AUC = %.2f, Accuracy = %.2f\n', pmDayRes.PRAUC, pmDayRes.ROCAUC, pmDayRes.Accuracy);
            
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
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow');
        toc
        fprintf('\n');
    end
end

