clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
basefeatureparamfile = selectFeatureParameters();
featureparamfile = strcat(basefeatureparamfile, '.xlsx');
pmFeatureParams = readtable(fullfile(basedir, subfolder, featureparamfile));

basemodelparamfile = selectModelRunParameters();
modelparamfile = strcat(basemodelparamfile, '.xlsx');
pmModelParams = readtable(fullfile(basedir, subfolder, modelparamfile));

nfeatureparamsets = size(pmFeatureParams,1);
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
        fbasefilename = generateFileNameFromFeatureParams(pmFeatureParams(fs,:));
        featureinputmatfile = sprintf('%s.mat',fbasefilename);
        fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
        load(fullfile(basedir, subfolder, featureinputmatfile));
        toc
        fprintf('\n');
        mbasefilename = generateFileNameFromModelParams(fbasefilename, pmModelParams(mp,:));

        predictionduration = pmFeatureParams.predictionduration(fs);
    
        pmModelRes = struct('ModelType', [], 'RunParams', [], 'pmLabel', []);
    
        pmModelRes.ModelType = 'Logistic Regression';
        pmModelRes.RunParams = mbasefilename;
    
        pmLabel = struct('Model', [], 'FPrate',[], 'TPrate', [], 'Thresh', [], 'AUC', [], ...
        'OptROCPt', [], 'Pred', [], 'PredLogical', [], 'TP', [], 'TN', [], 'FP', [], 'FN', []);
    
        if predictionduration <= 6
            plotsacross = 2;
        else
            plotsacross = 3;
        end
        plotsdown = ceil(predictionduration/plotsacross);
    
        baseplotname1 = sprintf('%s-PM ROC Plot', mbasefilename);
        baseplotname2 = sprintf('%s-PM Confusion Matrix', mbasefilename);
        [f1,p1] = createFigureAndPanel(baseplotname1, 'Portrait', 'A4');
        [f2,p2] = createFigureAndPanel(baseplotname2, 'Portrait', 'A4');
    
        for l = 1:predictionduration
        
            tic
            fprintf('Running Logistic Regression model for Label %d\n', l);
            
            if pmModelParams.labelmethod(mp) == 1
                labels = pmIVLabels(:,l);
            else
                labels = pmExLabels(:,l);
            end
            
            pmLabel(l).Model = fitglm(pmNormFeatures, labels, ...
                'linear', ...
                'Distribution', 'binomial', ...
                'Link', 'logit');

            costmatrix = [0 pmModelParams.costmethod(mp); (1 - pmModelParams.costmethod(mp)) 0];

            [pmLabel(l).FPrate, pmLabel(l).TPrate, pmLabel(l).Thresh, ...
                pmLabel(l).AUC, pmLabel(l).OptROCPt] = perfcurve(labels, ...
                pmLabel(l).Model.Fitted.Probability, 1, 'Cost', costmatrix);
        
            thresh = pmLabel(l).Thresh(pmLabel(l).FPrate>=(pmLabel(l).OptROCPt(1)*.99) & pmLabel(l).FPrate<=(pmLabel(l).OptROCPt(1)*1.01));
            thresh = thresh(1);
    
            pmLabel(l).Pred = predict(pmLabel(l).Model, pmNormFeatures);
            pmLabel(l).PredLogical = pmLabel(l).Pred > thresh;
    
            pmLabel(l).TP = sum(pmLabel(l).PredLogical == 1 & pmIVLabels(:,l) == 1);
            pmLabel(l).TN = sum(pmLabel(l).PredLogical == 0 & pmIVLabels(:,l) == 0);
            pmLabel(l).FP = sum(pmLabel(l).PredLogical == 1 & pmIVLabels(:,l) == 0);
            pmLabel(l).FN = sum(pmLabel(l).PredLogical == 0 & pmIVLabels(:,l) == 1);
    
            fprintf('TP: %d TN: %d FP: %d FN: %d - Total: %d FeatureSetSize %d\n', pmLabel(l).TP, ...
                pmLabel(l).TN, pmLabel(l).FP, pmLabel(l).FN, ...
                (pmLabel(l).TP + pmLabel(l).TN + pmLabel(l).FP + pmLabel(l).FN), ...
                size(labels,1));
    
            fprintf('Plotting Results\n');
        
            name1 = sprintf('%s - Label %d (AUC=%.2f)', baseplotname1, l, 100 * pmLabel(l).AUC);
            ax1(l) = subplot(plotsdown, plotsacross, l, 'Parent',p1);
            hold on
            plot(ax1(l), pmLabel(l).OptROCPt(1), pmLabel(l).OptROCPt(2),'ro');
            line(ax1(l), pmLabel(l).FPrate, pmLabel(l).TPrate);
            xlabel(ax1(l), 'False positive rate'); 
            ylabel(ax1(l), 'True positive rate');
            title(ax1(l), sprintf('Label %d - AUC %.2f%%', l, 100 * pmLabel(l).AUC));
            hold off

            name2 = sprintf('%s - Label %d', baseplotname2, l);
            ax2(l) = subplot(plotsdown, plotsacross, l, 'Parent',p2);
            cm = confusionmat(labels, pmLabel(l).PredLogical);
            plotConfMat(ax2(l), cm, [{'False'} {'True'}], l)
        
            toc
            fprintf('\n');
        end

        % save plots
        basedir = setBaseDir();
        plotsubfolder = strcat('Plots/', mbasefilename);
        mkdir(fullfile(basedir, plotsubfolder));
        savePlotInDir(f1, baseplotname1, basedir, plotsubfolder);
        savePlotInDir(f2, baseplotname2, basedir, plotsubfolder);
        close(f1);
        close(f2);
        toc
        fprintf('\n');
    
        pmModelRes.pmLabel = pmLabel;
        pmFeatureParamsRow = pmFeatureParams(fs,:);
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

