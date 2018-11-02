clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
baserunparameterfile = selectModelRunParameters();
runparameterfile = strcat(baserunparameterfile, '.xlsx');

pmRunParameters = readtable(fullfile(basedir, subfolder, runparameterfile));

pmModelRes = struct('ModelType', [], 'RunParams', [], 'pmLabel', []);

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

    predictionduration = pmRunParameters.predictionduration(a);
    
    pmModelRes(a).ModelType = 'Logistic Regression';
    pmModelRes(a).RunParams = basefilename;
    
    pmLabel = struct('Model', [], 'FPrate',[], 'TPrate', [], 'Thresh', [], 'AUC', [], ...
    'OptROCPt', [], 'Pred', [], 'PredLogical', [], 'TP', [], 'TN', [], 'FP', [], 'FN', []);
    
    if predictionduration <= 6
        plotsacross = 2;
    else
        plotsacross = 3;
    end
    plotsdown = ceil(predictionduration/plotsacross);
    
    baseplotname1 = sprintf('%s-PM ROC Plot', basefilename);
    baseplotname2 = sprintf('%s-PM Confusion Matrix', basefilename);
    [f1,p1] = createFigureAndPanel(baseplotname1, 'Portrait', 'A4');
    [f2,p2] = createFigureAndPanel(baseplotname2, 'Portrait', 'A4');
    
    for l = 1:predictionduration
        
        tic
        fprintf('Running Logistic Regression model for Label %d\n', l);
        
        pmLabel(l).Model = fitglm(pmNormFeatures, pmIVLabels(:,l), ...
            'linear', ...
            'Distribution', 'binomial', ...
            'Link', 'logit');

        costmatrix = [0 pmRunParameters.costmethod(a); (1 - pmRunParameters.costmethod(a)) 0];

        [pmLabel(l).FPrate, pmLabel(l).TPrate, pmLabel(l).Thresh, ...
            pmLabel(l).AUC, pmLabel(l).OptROCPt] = perfcurve(pmIVLabels(:,l), ...
            pmLabel(l).Model.Fitted.Probability, 1, 'Cost', costmatrix);
        
        thresh = pmLabel(l).Thresh(pmLabel(l).FPrate>=(pmLabel(l).OptROCPt(1)*.99) & pmLabel(l).FPrate<=(pmLabel(l).OptROCPt(1)*1.01));
        thresh = thresh(1);
    
        pmLabel(l).Pred = predict(pmLabel(l).Model, pmNormFeatures);
        pmLabel(l).PredLogical = pmLabel(l).Pred > thresh;
    
        pmLabel(l).TP = sum(pmLabel(l).PredLogical == 1 & pmIVLabels(:,l) == 1);
        pmLabel(l).TN = sum(pmLabel(l).PredLogical == 0 & pmIVLabels(:,l) == 0);
        pmLabel(l).FP = sum(pmLabel(l).PredLogical == 1 & pmIVLabels(:,l) == 0);
        pmLabel(l).FN = sum(pmLabel(l).PredLogical == 0 & pmIVLabels(:,l) == 1);
    
        fprintf('TP: %d TN: %d FP: %d FN: %d - Total: %d ValSetSize %d\n', pmLabel(l).TP, ...
            pmLabel(l).TN, pmLabel(l).FP, pmLabel(l).FN, ...
            (pmLabel(l).TP + pmLabel(l).TN + pmLabel(l).FP + pmLabel(l).FN), ...
            size(pmIVLabels(:,l),1));
    
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
        cm = confusionmat(pmIVLabels(:,l), pmLabel(l).PredLogical);
        plotConfMat(ax2(l), cm, [{'False'} {'True'}], l)
        
        toc
        fprintf('\n');
    end

    % save plots
    basedir = setBaseDir();
    plotsubfolder = strcat('Plots/', baserunparameterfile);
    mkdir(fullfile(basedir, plotsubfolder));
    savePlotInDir(f1, baseplotname1, basedir, plotsubfolder);
    savePlotInDir(f2, baseplotname2, basedir, plotsubfolder);
    close(f1);
    close(f2);
    toc
    fprintf('\n');
    
    pmModelRes(a).pmLabel = pmLabel;
end

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%s ModelResults.mat',baserunparameterfile);
fprintf('Saving output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmRunParameters', 'nmodels', 'pmModelRes');
toc
fprintf('\n');
