clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
runparameterfile = selectModelRunParameters();
runparameterfile = strcat(runparameterfile, '.xlsx');

pmRunParameters = readtable(fullfile(basedir, subfolder, runparameterfile));

pmModelResults = struct('ModelType', [], 'Model', [], 'FPrate',[], 'TPrate', [], 'Thresh', [], 'AUC', [], ...
    'OptROCPt', [], 'Pred', [], 'PredLogical', [], 'TP', [], 'TN', [], 'FP', [], 'FN', []);

nmodels = size(pmRunParameters,1);


for a = 1:nmodels
    
    basefilename = generateFileNameFromRunParameters(pmRunParameters(a,:));
    
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    modelinputsmatfile = sprintf('%s.mat',basefilename);
    fprintf('Loading predictive model input data from file %s\n', modelinputsmatfile);
    load(fullfile(basedir, subfolder, modelinputsmatfile));
    toc
    fprintf('\n');

    % add loop over prediction duration (and adjust indexing into structure
    % either just add more instances to structure, or make the structure 2d
    % I think making 2d would be better
    
    tic
    fprintf('Running Logistic Regression model\n');
    pmModelResults(a).ModelType = 'Logistic Regression';
    
    pmModelResults(a).Model = fitglm(pmTrNormFeatures, pmTrIVLabels(:,1), ...
        'linear', ...
        'Distribution', 'binomial', ...
        'Link', 'logit');

    costmatrix = [0 pmRunParameters.costmethod(a); (1 - pmRunParameters.costmethod(a)) 0];

    [pmModelResults(a).FPRate, pmModelResults(a).TPRate, pmModelResults(a).Thresh, ...
        pmModelResults(a).AUC, pmModelResults(a).OptROCPt] = perfcurve(pmTrIVLabels(:,1), ...
        pmModelResults(a).Model.Fitted.Probability, 1, 'Cost', costmatrix);
    toc
    fprintf('\n');
    
    tic
    fprintf('Plotting Results\n');
    
    plotsacross = 1;
    plotsdown = 1;
    name1 = sprintf('%s-PM ROC Plot (AUC=%.2f)', basefilename, 100 * pmModelResults(a).AUC);
    [f1,p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
    ax1 = subplot(plotsdown, plotsacross, 1, 'Parent',p1);

    plot(pmModelResults(a).FPRate, pmModelResults(a).TPRate);
    hold on
    plot(pmModelResults(a).OptROCPt(1),pmModelResults(a).OptROCPt(2),'ro');
    xlabel('False positive rate'); 
    ylabel('True positive rate');
    title(sprintf('PM ROC Plot (AUC %.2f%%)', 100 * pmModelResults(a).AUC));
    hold off

    basedir = setBaseDir();
    subfolder = 'Plots';
    savePlotInDir(f1, name1, basedir, subfolder);
    close(f1);
    thresh = pmModelResults(a).Thresh(pmModelResults(a).FPRate>(pmModelResults(a).OptROCPt(1)*.999) & pmModelResults(a).FPRate<(pmModelResults(a).OptROCPt(1)*1.001));
    thresh = thresh(1);
    
    pmModelResults(a).Pred = predict(pmModelResults(a).Model, pmValNormFeatures);
    pmModelResults(a).PredLogical = pmModelResults(a).Pred > thresh;
    
    pmModelResults(a).TP = sum(pmModelResults(a).PredLogical == 1 & pmValIVLabels(:,1) == 1);
    pmModelResults(a).TN = sum(pmModelResults(a).PredLogical == 0 & pmValIVLabels(:,1) == 0);
    pmModelResults(a).FP = sum(pmModelResults(a).PredLogical == 1 & pmValIVLabels(:,1) == 0);
    pmModelResults(a).FN = sum(pmModelResults(a).PredLogical == 0 & pmValIVLabels(:,1) == 1);
    
    fprintf('TP: %d TN: %d FP: %d FN: %d - Total: %d ValSetSize %d\n', pmModelResults(a).TP, ...
        pmModelResults(a).TN, pmModelResults(a).FP, pmModelResults(a).FN, ...
        (pmModelResults(a).TP + pmModelResults(a).TN + pmModelResults(a).FP +pmModelResults(a).FN), ...
        size(pmValIVLabels(:,1),1));
    
    plotsacross = 1;
    plotsdown = 1;
    name2 = sprintf('%s-PM Confusion Matrix', basefilename);
    [f2,p2] = createFigureAndPanel(name1, 'Portrait', 'A4');
    ax2 = subplot(plotsdown, plotsacross, 1, 'Parent',p2);
    cm = confusionmat(pmValIVLabels(:,1), pmModelResults(a).PredLogical);
    plotConfMat(ax2, cm, [{'False'} {'True'}])
    basedir = setBaseDir();
    subfolder = 'Plots';
    savePlotInDir(f2, name2, basedir, subfolder);
    close(f2);
    toc
    fprintf('\n');
end