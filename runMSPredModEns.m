clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

% logic to load in results for a given feature&label version, label method and raw measures combination
[fv1, validresponse] = selectFeatVer();
if validresponse == 0
    return;
end
[lb1, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
[rm1, validresponse] = selectRawMeasComb();
if validresponse == 0
    return;
end
[basemsresultsfile] = selectMSPattFile(fv1, lb1, rm1);
msresultsfile = sprintf('%s.mat', basemsresultsfile);
basemsresultsfile = strrep(basemsresultsfile, ' MPRes', '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', msresultsfile);
load(fullfile(basedir, subfolder, msresultsfile), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmBaselineQS', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', 'measures', 'nmeasures');

if pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern classifier only works on fully interpolated data\n');
    return
end
nfeatureparamsets = 1;

[basemodelparamfile, ~, ~, validresponse] = selectModelRunParameters();
if validresponse == 0
    return;
end
subfolder = 'DataFiles';
modelparamfile    = strcat(basemodelparamfile, '.xlsx');
pmModelParams     = readtable(fullfile(basedir, subfolder, modelparamfile));
nmodelparamsets   = 1;
ncombinations     = 1;

[basehpparamfile, ~, ~, validresponse] = selectHyperParameters();
if validresponse == 0
    return;
end
pmHyperParams        = readtable(fullfile(basedir, subfolder, strcat(basehpparamfile, '.xlsx')));
[lrarray, ntrarray, mlsarray, mnsarray, fvsarray, nlr, ntr, nmls, nmns, nfvs, hpsuffix] = setHyperParameterArrays(pmHyperParams);

% calculate labels for missingness dataset
qsmeasure = 'AvgEPV';
qsthreshold = 0.9;
[baselineqsthresh] = calcQCthresh(table2array(pmBaselineQS(1, {qsmeasure})), qsthreshold);
labels = setLabelsForMSDataset(pmMissPattQS, qsmeasure, baselineqsthresh);

lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time

nexamples = size(pmMissPattIndex, 1);
nsplits = 5;

% create split index for held out test data and folds
mpsplitidx = createMPSplitIndex(nexamples, nsplits);

% split out held out test set
[pmTestMPIndex, pmTestMPArray, pmTestMPQS, testlabels, testmpsplitidx, ...
 pmTrCVMPIndex, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, trcvmpsplitidx, nfolds] ...
        = splitTestMPFeats(pmMissPattIndex, pmMissPattArray, pmMissPattQS, labels, mpsplitidx, nsplits);
    
ntrcvexamples = size(pmTrCVMPArray, 1);
ntestexamples = size(pmTestMPArray, 1);
nnormfeatures = size(pmTrCVMPArray, 2);
featureduration = pmFeatureParamsRow.featureduration;

pmMPFeatNames = reshape(cellstr(cellstr('MS-' + string(measures.ShortName(logical(measures.MSMeas)))     + '-') + string(featureduration:-1:1))', ...
                    [1 sum(measures.MSMeas)     * featureduration]           );      

fs = 1;
mp = 1;

[modeltype, mmethod] = setModelTypeAndMethod(pmModelParams.ModelVer{mp});


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

                    pmMSModelRes = createMSModelResStuct(ntrcvexamples, nfolds);

                    for fold = 1:nfolds

                        foldhpcomb = fold;

                        fprintf('Fold %d: ', fold);

                        [pmTrMPIndex, pmTrMPArray, pmTrMPQS, trlabels, ...
                         pmCVMPIndex, pmCVMPArray, pmCVMPQS, cvlabels, cvidx] ...
                            = splitTrCVMPFeats(pmTrCVMPIndex, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, trcvmpsplitidx, fold); 

                        fprintf('Training...');
                        [pmMSModelRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmMSModelRes, pmTrMPArray, trlabels, ...
                                            pmMPFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                        fprintf('Done\n');

                        % calculate predictions and quality scores on training data
                        fprintf('Tr: ');
                        [~] = calcMPPredAndQS(pmMSModelRes.Folds(fold).Model, pmTrMPArray, trlabels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);

                        % calculate predictions and quality scores on cv data
                        fprintf('CV: ');
                        [pmCVRes] = calcMPPredAndQS(pmMSModelRes.Folds(fold).Model, pmCVMPArray, cvlabels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);

                        % also store results on overall model results structure
                        pmMSModelRes.Pred(cvidx) = pmCVRes.Pred;
                        pmMSModelRes.Loss(fold)  = pmCVRes.Loss;

                    end

                    fprintf('Overall:\n');
                    fprintf('CV: ');
                    fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
                    pmMSModelRes = calcModelQualityScores(pmMSModelRes, trcvlabels, ntrcvexamples);

                    fprintf('\n');

                    toc
                    fprintf('\n');
 
                end
            end
        end
    end
end

pmMPModelParamsRow   = pmModelParams(mp,:);
mpmodeltext = sprintf('mv%slm%d', pmMPModelParamsRow.ModelVer{1}, pmMPModelParamsRow.labelmethod);

pmMPHyperParamsRow              = struct();
pmMPHyperParamsRow.learnrate    = lrval;
pmMPHyperParamsRow.numtrees     = ntrval;
pmMPHyperParamsRow.minleafsize  = mlsval;
pmMPHyperParamsRow.maxnumsplits = mnsval;
pmMPHyperParamsRow.fracvarssamp = fvsval;
mphptext = sprintf('lr%dnt%dml%dns%dfv%.2f', pmMPHyperParamsRow.learnrate, pmMPHyperParamsRow.numtrees, ...
    pmMPHyperParamsRow.minleafsize, pmMPHyperParamsRow.maxnumsplits, pmMPHyperParamsRow.fracvarssamp);
                    
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
basemsresultsfile = sprintf('%s%s%s', basemsresultsfile, mpmodeltext, mphptext);
outputfilename = sprintf('%sMSPred.mat', basemsresultsfile);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmMSModelRes', ...
    'pmTestMPIndex', 'pmTestMPArray', 'pmTestMPQS', 'testlabels', 'testmpsplitidx', ...
    'pmTrCVMPIndex', 'pmTrCVMPArray', 'pmTrCVMPQS', 'trcvlabels', 'trcvmpsplitidx', ...
    'pmBaselineQS', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow');
toc
fprintf('\n');

% plot PR/ROC curves for missingness classifier
titlefontsize = 14;
labelfontsize = 12;
axisfontsize = 10;
unitfontsize = 10;
widthinch = 8.25;
heightinch = 3;
name = '';

[rocthresh, rocthreshidx] = calculateROCOpThresh(pmMSModelRes.FPR, pmMSModelRes.TPR, pmMSModelRes.PredSort);

baseplotname1 = sprintf('%s-PRROC', basemsresultsfile);
plotsubfolder = sprintf('Plots/MissPatQS');

randomprec = sum(pmMSModelRes.LabelSort) / size(pmMSModelRes.LabelSort, 1);
xl = [0 1];
yl = [0 1];

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

ax = subplot(1, 2, 1, 'Parent', p);

area(ax, pmMSModelRes.Recall, pmMSModelRes.Precision, ...
    'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);

line(ax, [0, 1], [randomprec, randomprec], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);
ax.FontSize = axisfontsize; 
ax.TickDir = 'out';     
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'Recall');
ylabel(ax, 'Precision');

prtext = sprintf('AUC = %.2f%%', pmMSModelRes.PRAUC);
annotation(p,   'textbox',  ...
                'String', prtext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.2, 0.2, 0.15, 0.1], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', axisfontsize);

ax = subplot(1, 2, 2, 'Parent', p);

hold on;
area(ax, pmMSModelRes.FPR, pmMSModelRes.TPR, ...
    'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);

line(ax, [0, 1], [0, 1], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);

scatter(ax, pmMSModelRes.FPR(rocthreshidx), pmMSModelRes.TPR(rocthreshidx),  ...
        24, 'filled', 'o', ...
        'MarkerFaceColor', 'green', ...
        'MarkerEdgeColor', 'black');

ax.FontSize = axisfontsize; 
ax.TickDir = 'out';      
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'FPR');
ylabel(ax, 'TPR');

roctext = sprintf('AUC = %.2f%%', pmMSModelRes.ROCAUC);
annotation(p, 'textbox',  ...
                'String', roctext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.7, 0.2 0.15, 0.1], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', axisfontsize);
hold off;

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

% need to add correct vs incorrect colouring to the plot function
plotMissingnessQSFcn(pmMSModelRes, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, pmBaselineQS, qsthreshold, rocthresh, basemsresultsfile);


beep on;
beep;
