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
filetext = ' QCDataset';

[baseqcinputfile] = selectQCInputFile(fv1, lb1, rm1, filetext);
qcresultsfile = sprintf('%s.mat', baseqcinputfile);
baseqcinputfile = strrep(baseqcinputfile, filetext, '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading qualiy classifier input data for %s\n', qcresultsfile);
load(fullfile(basedir, subfolder, qcresultsfile), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
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

[qsthreshold, validresponse] = selectThreshPercentage();
if validresponse == 0
    return;
end

% calculate labels for missingness dataset
qsmeasure = 'AvgEPV';
labels = setLabelsForMSDataset(pmMissPattQSPct, qsmeasure, qsthreshold/100);

lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time

nexamples = size(pmMissPattIndex, 1);

% create split index for held out test data and folds
qcsplitidx = createQCSplitIndex(pmMissPattIndex);

nnormfeatures = size(pmMissPattArray, 2);
datawin = pmFeatureParamsRow.datawinduration;

pmMPFeatNames = reshape(cellstr(cellstr('MS-' + string(measures.ShortName(logical(measures.MSMeas)))     + '-') + string(datawin:-1:1))', ...
                    [1 sum(measures.MSMeas)     * datawin]           );      

fs = 1;
mp = 1;

[modeltype, mmethod] = setModelTypeAndMethod(pmModelParams.ModelVer{mp});


nhpcomb      = nlr * ntr * nmls * nmns * nfvs;
%[hyperparamQS, foldhpTrQS, foldhpCVQS, foldhpTestQS] = createHpQSTables(nhpcomb, nqcfolds);

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

                    pmQCModelRes = createQCModelResStuct(nexamples, nqcfolds);

                    for fold = 1:nqcfolds

                        foldhpcomb = fold;

                        fprintf('Fold %d: ', fold);

                        [~, pmTrMPArray, ~, trlabels, ...
                         ~, pmCVMPArray, ~, cvlabels, cvidx] ...
                            = splitTrCVQCFeats(pmMissPattIndex, pmMissPattArray, pmMissPattQS, labels, qcsplitidx, fold); 

                        fprintf('Training...');
                        [pmQCModelRes] = trainPredModel(pmModelParams.ModelVer{mp}, pmQCModelRes, pmTrMPArray, trlabels, ...
                                            pmMPFeatNames, nnormfeatures, fold, mmethod, lrval, ntrval, mlsval, mnsval, fvsval);
                        fprintf('Done\n');

                        % calculate predictions and quality scores on training data
                        fprintf('Tr: ');
                        [~] = calcQCPredAndQS(pmQCModelRes.Folds(fold).Model, pmTrMPArray, trlabels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);

                        % calculate predictions and quality scores on cv data
                        fprintf('CV: ');
                        [pmCVRes] = calcQCPredAndQS(pmQCModelRes.Folds(fold).Model, pmCVMPArray, cvlabels, pmModelParams.ModelVer{mp}, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);

                        % also store results on overall model results structure
                        pmQCModelRes.Pred(cvidx) = pmCVRes.Pred;
                        pmQCModelRes.Loss(fold)  = pmCVRes.Loss;

                    end

                    fprintf('Overall:\n');
                    fprintf('CV: ');
                    fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
                    pmQCModelRes = calcModelQualityScores(pmQCModelRes, labels, nexamples);

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
baseqcinputfile = sprintf('%s%s%sth%s%d', baseqcinputfile, mpmodeltext, mphptext, qsmeasure, qsthreshold);
outputfilename = sprintf('%sQCResults.mat', baseqcinputfile);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmQCModelRes', ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
    'labels', 'qcsplitidx', 'nexamples', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'measures', 'nmeasures', 'qsmeasure', 'qsthreshold');
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

[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);

baseplotname1 = sprintf('%s-PRROC', baseqcinputfile);
plotsubfolder = sprintf('Plots/MissPatQS');

randomprec = sum(pmQCModelRes.LabelSort) / size(pmQCModelRes.LabelSort, 1);
xl = [0 1];
yl = [0 1];

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

ax = subplot(1, 2, 1, 'Parent', p);

area(ax, pmQCModelRes.Recall, pmQCModelRes.Precision, ...
    'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);

line(ax, [0, 1], [randomprec, randomprec], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);
ax.FontSize = axisfontsize; 
ax.TickDir = 'out';     
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'Recall');
ylabel(ax, 'Precision');

prtext = sprintf('AUC = %.2f%%', pmQCModelRes.PRAUC);
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
area(ax, pmQCModelRes.FPR, pmQCModelRes.TPR, ...
    'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);

line(ax, [0, 1], [0, 1], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);

scatter(ax, pmQCModelRes.FPR(rocthreshidx), pmQCModelRes.TPR(rocthreshidx),  ...
        24, 'filled', 'o', ...
        'MarkerFaceColor', 'green', ...
        'MarkerEdgeColor', 'black');

ax.FontSize = axisfontsize; 
ax.TickDir = 'out';      
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'FPR');
ylabel(ax, 'TPR');

roctext = sprintf('AUC = %.2f%%', pmQCModelRes.ROCAUC);
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
plotMissingnessQSFcn(pmQCModelRes, pmMissPattIndex, pmMissPattQSPct, labels, qsthreshold, rocthresh, baseqcinputfile);


% set the number of bins to calibrate over
nbins = 10;
smalldatathresh = 30;
plotsperpage = 4;
plotsdownperpanel = 1;
plotsacross = 2;

% calculate bin edges & midpoints
binedges = zeros(1, nbins + 1);
for n = 1:nbins
    binedges(n + 1) = n / nbins;
end
binmids = zeros(1, nbins);
for n = 2:nbins + 1
    binmids(n - 1) = (binedges(n) + binedges(n - 1))/ 2;
end
fold = 0;
modelcalibration = calcModelCalibration(labels, pmQCModelRes.Pred, binedges, nbins, fold);
cplot = 1;

name = sprintf('%s Calib', baseqcinputfile);
[f, p] = createFigureAndPanel(name, 'Portrait', 'A4');
uipypos = 1 - cplot/plotsperpage;
uipysz  = 1/plotsperpage;
uiptitle = '';
sp(cplot) = uipanel('Parent', p, ...
              'BorderType', 'none', ...
              'OuterPosition', [0.0,uipypos, 1.0, uipysz], ...
              'Title', uiptitle, 'TitlePosition', 'centertop', 'FontSize', 8);
ax1 = gobjects(plotsdownperpanel * plotsacross, 1);

ax1(1) = subplot(plotsdownperpanel, plotsacross, 1, 'Parent', sp(cplot));
sdidx = (modelcalibration.NbrInBin(modelcalibration.Fold == fold) <= smalldatathresh);
plotModelCalibration(ax1(1), binmids, modelcalibration.Calibration(modelcalibration.Fold == fold), sdidx, [0.7, 0.7, 0.7], 'Blue', 'Red', 'Overall');

modelcalib = modelcalibration(modelcalibration.Fold == fold, :);

tabletitle = [  {sprintf('   BinRange    TrueLabels NbrInBin  Percentage')} ; ...
                {sprintf('-------------- ---------- --------  ----------')} ; ...
              ];

tabletext = tabletitle;
for a = 1:size(modelcalib,1)
    if sdidx(a) == true
        sdtext = '***';
    else
        sdtext = '';
    end
    rowstring = sprintf('%13s    %4.0f      %4.0f      %5.1f%%  %3s', modelcalib.BinRange{a}, ...
        modelcalib.TrueLabels(a), modelcalib.NbrInBin(a), modelcalib.Calibration(a), sdtext);
    tabletext = [tabletext ; rowstring];
end

plotnbr = 2 * (fold + 1);
axr = uicontrol('Parent', p, ... 
                'Units', 'normalized', ...
                'OuterPosition', [0.5,uipypos, 1.0, uipysz], ...
                'Style', 'text', ...
                'FontName', 'FixedWidth', ...
                'FontSize', 6, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'String', tabletext);
            
basedir = setBaseDir();
savePlotInDir(f, name, basedir, plotsubfolder);
close(f); 

beep on;
beep;
