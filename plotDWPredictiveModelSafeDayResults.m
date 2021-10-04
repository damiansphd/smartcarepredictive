clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

mlsubfolder = 'MatlabSavedVariables';
dfsubfolder = 'DataFiles';

% Choose feature version, label method and raw measures combination
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

% Choose predictive classifier version for above choices
fprintf('Choose the trained predictive classifier version to run\n');
typetext = ' ModelResults';
[pcbasemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
pcmodelresultsfile = sprintf('%s.mat', pcbasemodelresultsfile);
pcbasemodelresultsfile = strrep(pcbasemodelresultsfile, typetext, '');
fprintf('\n');

% load trained predictive classifier and features/labels
tic
fprintf('Loading predictive model results data for %s\n', pcmodelresultsfile);
load(fullfile(basedir, mlsubfolder, pcmodelresultsfile), ...
            'pmTestFeatureIndex', 'pmTestNormFeatures', 'pmTestExABxElLabels', 'pmTestPatientSplit', ...
            'pmTrCVFeatureIndex', 'pmTrCVNormFeatures', 'pmTrCVExABxElLabels', 'pmTrCVPatientSplit', 'testidx', ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');

% load the predictive model inputs
tic
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, mlsubfolder, featureparamsmatfile), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', 'pmAMPred', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'measures', 'nmeasures', 'pmModFeatParamsRow', ...
        'pmNormFeatures', 'pmNormFeatNames');
toc
fprintf('\n');

% load in the safe method parameter file info to determine the various run
% iterations

[safeparamfile] = selectSafeMthdParamsFile();
safeparamrunarray = readtable(fullfile(basedir, dfsubfolder, sprintf('%s.xlsx', safeparamfile)));
nsafeparamruns = size(safeparamrunarray, 1);

pmSafeDayResTable = createTrModNewDataResTable(nsafeparamruns);

for sp = 1:nsafeparamruns

    safemethod = safeparamrunarray.safemethod(sp);
    
    fprintf('%d of %d: ', sp, nsafeparamruns);
   
    if safemethod == 0
        % run for all days
        fprintf('Running for all days\n');
        fprintf('\n');
        qcmodelresultsfile = '';
        qcopthres = 0.0;
        
    elseif safemethod == 1
        % using quality classifier to determine safe days
        qcmodelresultsfile = safeparamrunarray.qcmodelresultsfile{sp};
        qcopthres = safeparamrunarray.qcopthres(sp);
        
        fprintf('Running for safe days - quality classifier, op thresh %.2f\n', qcopthres);
        fprintf('\n');
        
        % load trained quality classifier
        tic
        fprintf('Loading quality classifier results data for %s\n', qcmodelresultsfile);
        load(fullfile(basedir, mlsubfolder, qcmodelresultsfile), ...
                'pmQCModelRes', 'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
                'pmQSConstr');
        toc
        fprintf('\n');
        if pmMPOtherRunParams.runtype ~= 2
            fprintf('Need to have qc model trained on all training data, not CV folds\n');
            return;
        end 
    elseif safemethod == 2
        % set the various parameters for the defined rule methodology
        mindatadays = safeparamrunarray.mindatadays(sp);
        maxdatagap  = safeparamrunarray.maxdatagap(sp);
        recpctgap   = safeparamrunarray.recpctgap(sp);
        
        fprintf('Running for safe days - manual rules - mindatadays %d, maxdatagap %d, recpctgap %d\n', mindatadays, maxdatagap, recpctgap);
        fprintf('\n');
    else
        fprintf('Unknown safe method\n');
        return;
    end                         

    % set datawinarray, featindex, features, labels, patient split based on run type
    [~, ~, ~, ~, featindex, normfeatures, labels, patsplit] = ...
                setTrainTestArraysForRunType(pmTrCVFeatureIndex, pmTrCVNormFeatures, pmTrCVExABxElLabels, pmTrCVPatientSplit, ...
                                             pmTestFeatureIndex, pmTestNormFeatures, pmTestExABxElLabels, pmTestPatientSplit, ...
                                             pmOtherRunParams.runtype);           

    if pmOtherRunParams.runtype == 1
        datawinarray  = pmDataWinArray(~testidx, :, :);
    elseif pmOtherRunParams.runtype == 2
        datawinarray  = pmDataWinArray(testidx, :, :);
    else
        fprintf('**** Unknown runtype ****\n');
        return;
    end

    if pmOtherRunParams.runtype == 1
        datascope = 'CV';
    elseif pmOtherRunParams.runtype == 2
        datascope = 'Test';
    end

    % set some variabes for convenience
    datawin       = pmFeatureParamsRow.datawinduration;
    normwin       = pmFeatureParamsRow.normwinduration;
    totalwin      = datawin + normwin;
    nexamples     = size(featindex, 1);
    nfolds        = 1;
    fold          = 1;
    nnormfeatures = size(normfeatures, 2);     

    % create features for quality classifier and defined rules function
    [qcfeatures, qcfeatnames, qcmeasures, qcmodfeatparamrow]  = createQCFeaturesFromDataWinArray(datawinarray, pmFeatureParamsRow, nexamples, totalwin, measures, nmeasures);
    fprintf('\n');

    % calculate safe day index
    if safemethod == 0
        % run for all days
        nsafedays = nexamples;
        safedayidx = true(nsafedays, 1);
        daysscope = 'All';
    elseif safemethod == 1
        % use quality classifier to determine safe days
        fprintf('Running quality classifier on new data set\n');
        [safedayidx, nsafedays] = getSafeDaysFromQualClassifier(featindex, qcfeatures, pmQCModelRes.Folds(fold).Model, pmMPModelParamsRow.ModelVer{1}, qcopthres);
        daysscope = 'SafeQC';
    elseif safemethod == 2
        % defined rules to determine safe days - function yet to be implemented
        daysscope = 'SafeDR';
    end
    fprintf('\n');

    % create Safe model res structure to store safe quality scores (likely
    % need to add new fields for the don't know counts etc
    origidx    = featindex.ScenType == 0;
    unionidx = safedayidx & origidx;
    nsafeorigdays = sum(unionidx);
    pmSafeDayRes = createModelDayResStuct(nsafeorigdays, fold, 1);
    pmSafeDayRes.Pred = pmModelRes.pmNDayRes(1).Pred(unionidx, :);
    pmSafeDayRes.DataScope = datascope;
    pmSafeDayRes.DaysScope = daysscope;
    pmSafeDayRes.RunDays = nsafeorigdays;
    pmSafeDayRes.TotDays = sum(origidx);
    pmSafeDayRes.PosLblDays = sum(labels(unionidx));

    fprintf('Calculating quality scores\n');
    
    % calculate P-Score/Elec-PScore only for safe interventions
    [pmSafeDayRes, ampredupd] = calcPredQualityScore(pmSafeDayRes, pmAMPred, featindex(unionidx, :), patsplit);

    % calculate daily PR/ROC metrics only for safe days (and populate
    % predsort and labelsort in modelres struct
    pmSafeDayRes = calcModelQualityScores(pmSafeDayRes, labels(unionidx), nsafeorigdays);

    % convert to episodes
    [epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNew(featindex(origidx, :), ...
                                            labels(origidx), pmModelRes.pmNDayRes(1).Pred(origidx, :), pmOtherRunParams.epilen, safedayidx);

    fprintf('Safe Episodes - All: %d of %d , Stable: %d of %d, Unstable: %d of %d\n', sum(episafeidx), size(episafeidx, 1), ...
                sum(episafeidx(~logical(epilabl))), size(episafeidx(~logical(epilabl)), 1), ...
                sum(episafeidx(logical(epilabl))),  size(episafeidx(logical(epilabl)), 1));

    pmSafeDayRes.RunEpi    = sum(episafeidx);
    pmSafeDayRes.TotEpi    = size(episafeidx, 1);
    pmSafeDayRes.PosLblEpi = sum(episafeidx(logical(epilabl)));


    % calculate EPV at optimal fpropthresh only for safe days
    pmSafeDayRes = calcAvgEpiPred(pmSafeDayRes, epiindex, epilabl, epipred, episafeidx, featindex(unionidx, :), labels(unionidx), ...
                                pmOtherRunParams.fpropthresh);

    fprintf('\n');

    % generate regular and derived quality curves for all op thresholds
    [epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, ~] = calcQualScores(epilabl(episafeidx), epipred(episafeidx));

    printlog = false;
    [epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex(logical(epilabl == 1) & episafeidx, :), featindex(unionidx, :), labels(unionidx), pmSafeDayRes.Pred, epipredsort, printlog);

    maxidxpt = find(epifpr < pmOtherRunParams.fpropthresh, 1, 'last');
    bestidxpt = find(epitpr == epitpr(maxidxpt), 1, 'first');

    printlog = true;
    [~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(epiindex(logical(epilabl == 1) & episafeidx, :), featindex(unionidx, :), labels(unionidx), pmSafeDayRes.Pred, epipredsort(bestidxpt), printlog);
    untrigpmampred = pmAMPred(logical(trigintrarray == -1), :);
    fprintf('\n');
    fprintf('At %.1f%% FPR (pt %d), the Triggered Intervention TPR is %.1f%%, Avg Delay Reduction is %.1f days, and Avg Trigger Delay is %.1f days\n', ...
                100 * epifpr(bestidxpt), bestidxpt, trigintrtpr(bestidxpt), epiavgdelayreduction(bestidxpt), avgtrigdelay(bestidxpt));

    fprintf('\n');
    
    pmSafeDayResTable(sp, :) = updateTrModNewDataResTableRow(pmSafeDayResTable(sp, :), pmFeatureParamsRow, ...
            pcmodelresultsfile, qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureparamsmatfile, ...
            pmSafeDayRes);
        
    % plot regular and derived episodic qual scores

end

% plot various variables vs the QC operating threshold
if all(safeparamrunarray.safemethod == 0 | safeparamrunarray.safemethod == 1)
    plotsdown   = 3;
    plotsacross = 4;
    widthinch   = 12;
    heightinch  = 12;
    
    [f, p] = createFigureAndPanelForPaper('', widthinch, heightinch);
    
    % plot number of safe days vs qcopthresh
    thisplot    = 1;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.RunDays, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'Nbr of Safe Days');
    title(ax, 'Nbr Safe Days');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    ax.YTick = 0:20000:100000;
    yticklabels(ax, {'0', '20,000', '40,000', '60,000', '80,000', '100,000'});
    yrange = roundRangeScaled(min(pmSafeDayResTable.RunDays), max(pmSafeDayResTable.RunDays), 'outer');
    ylim(ax, yrange);
    
    
    % plot % safe days vs qcopthresh
    thisplot = 2;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PctDaysRun, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, '% Safe Days');
    title(ax, '% of Safe Days');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.PctDaysRun), max(pmSafeDayResTable.PctDaysRun), 'outer');
    ylim(ax, yrange);
    
    % plot number of pos label days vs qcopthresh
    thisplot = 3;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PosLblDays, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'Nbr of Pos Label Days');
    title(ax, 'Nbr Pos Label Days');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    ax.YTick = 0:200:1000;
    yticklabels(ax, {'0', '200', '400', '600', '800', '1000'});
    yrange = roundRangeScaled(min(pmSafeDayResTable.PosLblDays), max(pmSafeDayResTable.PosLblDays), 'outer');
    ylim(ax, yrange);
    
    
    % plot % pos label days vs qcopthresh
    thisplot = 4;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PctPosLblDays, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, '% Pos Label Days');
    title(ax, '% Pos Label Days');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.PctPosLblDays), max(pmSafeDayResTable.PctPosLblDays), 'outer');
    ylim(ax, yrange);
   
    % plot number of safe episodes vs qcopthresh
    thisplot    = 5;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.RunEpi, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'Nbr of Safe Episodes');
    title(ax, 'Nbr Safe Episodes');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    ax.YTick = 0:2000:10000;
    yticklabels(ax, {'0', '2,000', '4,000', '6,000', '8,000', '10,000'});
    yrange = roundRangeScaled(min(pmSafeDayResTable.RunEpi), max(pmSafeDayResTable.RunEpi), 'outer');
    ylim(ax, yrange);
    
    % plot % safe episodes vs qcopthresh
    thisplot = 6;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PctEpiRun, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, '% Safe Episodes');
    title(ax, '% of Safe Episodes');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.PctEpiRun), max(pmSafeDayResTable.PctEpiRun), 'outer');
    ylim(ax, yrange);
    
    % plot number of pos label episodes vs qcopthresh
    thisplot = 7;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PosLblEpi, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'Nbr of Pos Label Episodes');
    title(ax, 'Nbr Pos Label Episodes');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.PosLblEpi), max(pmSafeDayResTable.PosLblEpi), 'outer');
    ylim(ax, yrange);
    
    % plot % pos label episodes vs qcopthresh
    thisplot = 8;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PctPosLblEpi, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, '% Pos Label Episodes');
    title(ax, '% Pos Label Episodes');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.PctPosLblEpi), max(pmSafeDayResTable.PctPosLblEpi), 'outer');
    ylim(ax, yrange);
    
    % plot PR AUC vs qcopthresh
    thisplot = 9;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.PRAUC, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'PR AUC');
    title(ax, 'PR AUC');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.PRAUC), max(pmSafeDayResTable.PRAUC), 'outer');
    ylim(ax, yrange);
    
    
    % plot ROC AUC vs qcopthresh
    thisplot = 10;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.ROCAUC, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'ROC AUC');
    title(ax, 'ROC AUC');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.ROCAUC), max(pmSafeDayResTable.ROCAUC), 'outer');
    ylim(ax, yrange);
    
    
    % plot EPV vs qcopthresh
    thisplot = 11;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.AvgEPV, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'EPV');
    title(ax, 'Avg Episodic Predictive Value');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.AvgEPV), max(pmSafeDayResTable.AvgEPV), 'outer');
    ylim(ax, yrange);


    % plot TrigIntrTPR vs qcopthresh
    thisplot = 12;
    ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
    line(ax, pmSafeDayResTable.QCOpThresh, pmSafeDayResTable.TrigIntrTPR, ...
                'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.3010 0.7450 0.9330], ...
                'Marker', 'o', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0 0.4470 0.7410]);
    xlabel(ax, 'Qual Class Op Thresh');
    ylabel(ax, 'TrigIntrTPR');
    title(ax, 'Triggered Intervention TPR');
    ax.TickDir = 'out';
    ax.XTick = 0:0.2:1.0;
    yrange = roundRangeScaled(min(pmSafeDayResTable.TrigIntrTPR), max(pmSafeDayResTable.TrigIntrTPR), 'outer');
    ylim(ax, yrange);

    timenow = datestr(clock(),30);
    plsubfolder = sprintf('Plots/%s', pcbasemodelresultsfile);
    plotname = sprintf('%s Plot %s', safeparamfile, timenow);
    fprintf('Saving plots to file %s\n', outputfilename);
    savePlotInDir(f, plotname, basedir, plsubfolder);
    %savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
    close(f);
    
end
    
% save results to excel
tic
timenow = datestr(clock(),30);
exsubfolder = 'ExcelFiles';
outputfilename = sprintf('%sResults %s.xlsx', safeparamfile, timenow);
fprintf('Saving table to file %s\n', outputfilename);
writetable(pmSafeDayResTable, fullfile(basedir, exsubfolder, outputfilename), 'Sheet', 'DataResults');
toc
fprintf('\n');
