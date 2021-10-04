clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

mlsubfolder = 'MatlabSavedVariables';
dfsubfolder = 'DataFiles';

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

fprintf('Select Outer (Quality) Classifier model results file\n');
typetext = 'QCResults';
[baseqcresfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcresfile = sprintf('%s.mat', baseqcresfile);
baseqcresfile = strrep(baseqcresfile, typetext, '');

tic
fprintf('Loading quality classifier results data for %s\n', qcresfile);
load(fullfile(basedir, mlsubfolder, qcresfile), ...
        'pmQCModelRes', 'pmQCFeatNames', ...
        'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
        'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
        'measures', 'nmeasures', 'pmQSConstr');
toc
fprintf('\n');

% choose the operating threshold for the quality classifier
[qcopthres, validresponse] = selectFromArrayByIndex('Operating Threshold', [pmQCModelRes.PredOp; 0.6; 0.7; 0.8; 0.9; 0.95]);
if validresponse == 0
    return;
end

fprintf('Select Inner (Predictive) Classifier model results file\n');
[basepcresfile] = selectModelResultsFile(fv1, lb1, rm1);
pcresfile = sprintf('%s.mat', basepcresfile);
basepcresfile = strrep(basepcresfile, ' ModelResults', '');

tic
fprintf('Loading trained Inner (Predictive) classifier and run parameters for %s\n', pcresfile);        
load(fullfile(basedir, mlsubfolder, pcresfile), ...
    'pmTestFeatureIndex', 'pmTestNormFeatures', 'pmTestExABxElLabels', 'pmTestPatientSplit', ...
    'pmTrCVFeatureIndex', 'pmTrCVNormFeatures', 'pmTrCVExABxElLabels', 'pmTrCVPatientSplit', ...
    'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');

[trainfeatidx, trainfeatures, trainlabels, trainpatsplit, testfeatidx, testfeatures, testlabels, testpatsplit] = ...
            setTrainTestArraysForRunType(pmTrCVFeatureIndex, pmTrCVNormFeatures, pmTrCVExABxElLabels, pmTrCVPatientSplit, ...
                                         pmTestFeatureIndex, pmTestNormFeatures, pmTestExABxElLabels, pmTestPatientSplit, ...
                                         pmOtherRunParams.runtype);

% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
if pmFeatureParamsRow.augmethod > 1
    findaugtext = sprintf('au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('au1');
    featureparamsfile = strrep(featureparamsfile, findaugtext, replaceaugtext);
end
featureparamsfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading Inner (Predictive) model input data for %s\n', featureparamsfile);
load(fullfile(basedir, mlsubfolder, featureparamsfile), 'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmPatients', 'pmAMPred', 'pmAntibiotics', 'pmRawDatacube', 'npatients', 'measures', 'nmeasures', 'maxdays', ...
    'pmOverallStats', 'pmPatientMeasStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

npcexamples = size(pmFeatureIndex, 1);

plotsubfolder = sprintf('Plots/%s', basepcresfile);
mkdir(fullfile(basedir, plotsubfolder));

fprintf('Creating interpolated cube\n');
[pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures);
[pmInterpDatacube] = handleMissingFeatures(pmPatients, pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures);

tic
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, mlsubfolder, psplitfile));
toc
fprintf('\n');

if nqcfolds ~= 1
    fprintf('Need to choose an Outer (Quality) classifier model with only one fold\n');
    return
end

qcmodel    = pmQCModelRes.Folds(1).Model;
qcmodelver = pmMPModelParamsRow.ModelVer{1};
qclossfunc = 'hinge'; % hardcoded for now - until add this to mp other run parameters

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

[baseuxfile, validresponse] = selectUXExampleFile();
if validresponse == 0
    return;
end
uxfile = strcat(baseuxfile, '.xlsx');

uxtable  = readtable(fullfile(basedir, dfsubfolder, uxfile));
nuxexs = size(uxtable,1);

% populate run parameters
dwdur      = pmFeatureParamsRow.datawinduration;
normwin    = pmFeatureParamsRow.normwinduration;
totalwin   = dwdur + normwin;
smfn       = pmFeatureParamsRow.smfunction;
smwin      = pmFeatureParamsRow.smwindow;
smln       = pmFeatureParamsRow.smlength;
perioddays = 20;

if ismember(pmFeatureParamsRow.StudyDisplayName, {'BR', 'CL'})
    mfev1idx = measures.Index(ismember(measures.DisplayName, {'FEV1', 'LungFunction'}));
else
    mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));
end

widthinch = 12;
heightinch = 9;
safecol     = [1.0, 1.0, 1.0];
notsafecol  = [0.83, 0.83, 0.83];
unstablecol = [1.0, 0.0, 0.0];
stablecol   = [0.0, 1.0, 0.0];
transparency = 0.6;
        
% set subplot axes position array for desired layout for plots
mplotsdown   = 6;
mplotsacross = 2;
mplotwidth   = 1;
mplotpos = reshape((1:mplotsacross * mplotwidth * mplotsdown), mplotsacross * mplotwidth, mplotsdown)';
mplotpos = [mplotpos(:, 1:mplotwidth); mplotpos(:, mplotwidth + 1:mplotsacross * mplotwidth)];

totplotsdown   = mplotsdown;
totplotsacross = mplotsacross;

for ux = 1:nuxexs

    uxtablerow = uxtable(ux, :);
    
    uxstudy  = uxtablerow.Study{1};
    uxscenario = uxtablerow.Description{1};
    
    if ~ismember(uxstudy, pmFeatureParamsRow.StudyDisplayName)
        fprintf('**** Predictive classifier study is not the same as the study of the example - skipping ****\n');
    end
    
    % set relevant variables for this example
    pnbr       = pmPatients.PatientNbr(ismember(pmPatients.Study, uxstudy) & pmPatients.ID == uxtablerow.PatientID);
    patientrow = pmPatients(pnbr, :);
    pmaxdays   = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;
    fromdn     = uxtablerow.FromRelDn;
    todn       = uxtablerow.ToRelDn;
    ndays      = todn - fromdn + 1;
    
    pmeasstats = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr, :);
    
    % get ab treatments in the example date range
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= fromdn & pmAntibiotics.RelStartdn <= todn, :);
    pivabsdates = pabs(ismember(pabs.Route, 'IV'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    poralabsdates = pabs(ismember(pabs.Route, 'Oral'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    
    % get exacerbations starts in the example date range
    pexstsdates = pmAMPred(pmAMPred.PatientNbr == pnbr & ...
        ((pmAMPred.RelUB1 >= fromdn & pmAMPred.RelLB1 <= todn) | ...
         (pmAMPred.RelUB2 >= fromdn & pmAMPred.RelLB2 <= todn)), ...
        {'IVStartDate', 'IVDateNum', 'Offset', 'Ex_Start', ...
        'LowerBound1', 'UpperBound1', 'LowerBound2', 'UpperBound2', ...
        'Pred', 'RelLB1', 'RelUB1', 'RelLB2', 'RelUB2'});

    % need to create array of predictions and labels in real days (rather
    % than just the days we predict for)
    pfidx = (testfeatidx.PatientNbr == pnbr & testfeatidx.ScenType == 0 );
    pfeatindex = testfeatidx(pfidx,:);
    ppred  = pmModelRes.pmNDayRes(1).Pred(pfidx);
    plabel = testlabels(pfidx);

    ppreddata = nan(1, pmaxdays);
    plabeldata = nan(1, pmaxdays);
    for d = 1:size(ppred,1)
        ppreddata(pfeatindex.CalcDatedn(d))  = ppred(d);
        plabeldata(pfeatindex.CalcDatedn(d)) = plabel(d);
    end
    pbinpreddata = ppreddata >= pmModelRes.pmNDayRes(1).EpiPredOp;

    npages    = ceil(ndays / perioddays);
    for page = 1:npages
        
        dfrom = (page - 1) * perioddays + fromdn;
        dto   = (page * perioddays) + fromdn - 1;
        lastrund = max(pmFeatureIndex.CalcDatedn(pmFeatureIndex.PatientNbr == pnbr & ...
            pmFeatureIndex.ScenType == 0 & pmFeatureIndex.CalcDatedn >= dfrom & pmFeatureIndex.CalcDatedn <= todn));
        if dto > lastrund
            dto = lastrund;
        end
        
        % create quality classifier inputs and predictions
        qfidx = (pmFeatureIndex.PatientNbr == pnbr & pmFeatureIndex.ScenType == 0 & ...
            pmFeatureIndex.CalcDatedn >= dfrom & pmFeatureIndex.CalcDatedn <= dto);
        datawinarray   = pmDataWinArray(qfidx, :, :);
        pnex = size(datawinarray, 1); 
        [qcfeatures, ~, qcmeasures, qcmodfeatparamrow] = createQCFeaturesFromDataWinArray(datawinarray, pmModFeatParamsRow, pnex, totalwin, measures, nmeasures);
        qcres = createQCModelResStruct(pnex, 1);
        qcres = predictPredModel(qcres, qcmodel, qcfeatures, zeros(pnex, 1), qcmodelver, qclossfunc);
        qcres.Loss = 0; % Loss calculation does not make sense for new data as we don't have labels to compare to

        % create index of safe days
        safeidx    = qcres.Pred >= qcopthres;
        nsafedays  = sum(safeidx);
        fprintf('There are %d safe days out of a total of %d days (%.1f%%)\n', nsafedays, pnex, 100 * nsafedays / pnex);
        
    
        plotname = sprintf('%s-UXVizP%d(%s%d)D%d-%d', ...
            basepcresfile, pnbr, patientrow.Study{1}, patientrow.ID, dfrom, dto);
        plottitle = sprintf('%s-P%d(%s%d)D%d-%d', ...
            uxscenario, pnbr, patientrow.Study{1}, patientrow.ID, dfrom, dto);
        fprintf('Page %d: From %d - To %d\n', page, dfrom, dto);
        %[f,p] = createFigureAndPanel(plotname, 'Portrait', 'A4');
        [f, p] = createFigureAndPanelForPaper(plottitle, widthinch, heightinch);
        
        days  = (dfrom:dto);
        xl    = [(dfrom - 0.5) (dfrom + 0.5 + perioddays - 1)];
        thisplot = 0;
        
        for m = 1:nmeasures
            
            if measures.RawMeas(m) == 1
                
                midx       = measures.Index(m);
                mrawdata   = pmRawDatacube(pnbr, dfrom:dto, midx);
                mdata      = pmInterpDatacube(pnbr, dfrom:dto, midx);
                interppts  = mdata;
                interppts(~isnan(mrawdata)) = nan;
                [combinedmask, plottext, left_color, lint_color, right_color, rint_color] = setDWPlotColorsAndText(measures(midx, :));
        
                % raw measures - capture overall min/max range based on all study data
                ovyl = [min(pmInterpDatacube(pnbr, dfrom:dto, midx)) * 0.95, max(pmInterpDatacube(pnbr, dfrom:dto, midx)) * 1.05];

                % set minimum y display range to be mean +/- 1 stddev (using patient/
                % measure level stats where they exist, otherwise overall study level
                % stats
                if size(pmeasstats.Mean(pmeasstats.MeasureIndex == midx), 1) == 0
                    defyl = [(pmOverallStats.Mean(pmOverallStats.MeasureIndex == midx) - pmOverallStats.StdDev(pmOverallStats.MeasureIndex == midx)), ...
                        (pmOverallStats.Mean(pmOverallStats.MeasureIndex == midx) + pmOverallStats.StdDev(pmOverallStats.MeasureIndex == midx))];
                else
                    defyl = [(pmeasstats.Mean(pmeasstats.MeasureIndex == midx) - pmeasstats.StdDev(pmeasstats.MeasureIndex == midx)) ...
                        (pmeasstats.Mean(pmeasstats.MeasureIndex == midx) + pmeasstats.StdDev(pmeasstats.MeasureIndex == midx))];
                end

                yl = [min(ovyl(1), defyl(1)), max(ovyl(2), defyl(2))];
                
                thisplot = thisplot + 1;
                ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
                
                if ~all(isnan(mdata))
                    [~, yl] = plotMeasurementData(ax, days, mdata, xl, yl, plottext, combinedmask, left_color, ':', 1.0, 'none', 1.0, 'blue', 'green');
                    [~, yl] = plotMeasurementData(ax, days, applySmoothMethodToInterpRow(mdata, smfn, smwin, smln, midx, mfev1idx), xl, yl, plottext, combinedmask, left_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
                    [~, yl] = plotMeasurementData(ax, days, interppts, xl, yl, plottext, combinedmask, left_color, 'none', 1.0, 'o', 1.0, lint_color, lint_color);
                end
                [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
                ylim(ax, yl);
                xlim(ax, xl);
     
                
            end
        end
        % with 5 measures used, need to skip one plot position on the lhs
        % **** Note - if a different number of measures used in the model,
        % then will need to adjust the plot layout etc
        thisplot = thisplot + 1;
        
        % plot predictive classifier results
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        yl = [0 1];
        
        plottitle = sprintf('Predictive Classifier');
        [~, yl] = plotMeasurementData(ax, days, plabeldata(dfrom:dto), xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotMeasurementData(ax, days, ppreddata(dfrom:dto), xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotHorizontalLine(ax, pmModelRes.pmNDayRes(1).EpiPredOp, xl, yl, [0.83, 0.83, 0.83], ':', 1.0);
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        ylim(ax, yl);
        xlim(ax, xl);
        
        
        % add in red/green plot here
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        ax.YAxis.Visible = 'off';
        yl = [0 1];
        yupper = 0.7;
        ylower = 0.3;
        
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        for i = dfrom:dto
            if pbinpreddata(i)
                pccol = unstablecol;
            else
                pccol = stablecol;
            end
            xlower = i - 0.35;
            xupper = i + 0.35;
            hold on;
            fill(ax, [xlower xupper xupper xlower], ...
                     [ylower ylower yupper yupper], ...
                     pccol, 'FaceAlpha', transparency, 'EdgeColor', 'black');
            hold off;
        end
        title(ax, 'Breathe Score','FontSize', 6);
        xlabel('Days', 'FontSize', 6);
        ax.FontSize = 6;
        ylim(ax, yl);
        xlim(ax, xl);

        % plot quality classifier results
        
        % 1) percentage of missing data points.
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        yl = [0 100];
        
        qcmiss = 100 * sum(qcfeatures, 2) / size(qcfeatures, 2);
        plottitle = sprintf('Percentage Missingness in Data Window');
        [~, yl] = plotMeasurementData(ax, days, qcmiss, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        ylim(ax, yl);
        xlim(ax, xl);
        
        % 2) qual classifier prediction + qcopthres
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        yl = [0 1];
        
        plottitle = sprintf('Quality Classifier');
        [~, yl] = plotMeasurementData(ax, days, qcres.Pred, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotHorizontalLine(ax, qcopthres, xl, yl, [0.83, 0.83, 0.83], ':', 1.0);
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        ylim(ax, yl);
        xlim(ax, xl);
        
        % 3) safe/not safe
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        ax.YAxis.Visible = 'off';
        yl = [0 1];
        yupper = 0.7;
        ylower = 0.3;
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        for i = 1:size(safeidx, 1)
            if safeidx(i)
                pccol = safecol;
            else
                pccol = notsafecol;
            end
            xlower = dfrom - 1 + i - 0.35;
            xupper = dfrom - 1 + i + 0.35;
            hold on;
            fill(ax, [xlower xupper xupper xlower], ...
                     [ylower ylower yupper yupper], ...
                     pccol, 'FaceAlpha', transparency, 'EdgeColor', 'black');
            hold off;
        end
        title(ax, 'Safe/Not-Safe','FontSize', 6);
        xlabel('Days', 'FontSize', 6);
        ax.FontSize = 6;
        ylim(ax, yl);
        xlim(ax, xl);

        % now plot UX display
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        ax.YAxis.Visible = 'off';
        yl = [0 1];
        yupper = 0.7;
        ylower = 0.3;
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        for i = dfrom:dto
            if ~safeidx(i - dfrom + 1)
                pccol = notsafecol;
            else
                if pbinpreddata(i)
                    pccol = unstablecol;
                else
                    pccol = stablecol;
                end
            end
            xlower = i - 0.35;
            xupper = i + 0.35;
            hold on;
            fill(ax, [xlower xupper xupper xlower], ...
                     [ylower ylower yupper yupper], ...
                     pccol, 'FaceAlpha', transparency, 'EdgeColor', 'black');
            hold off;
        end
        title(ax, 'Breathe App UX','FontSize', 6);
        xlabel('Days', 'FontSize', 6);
        ax.FontSize = 6;
        ylim(ax, yl);
        xlim(ax, xl);

        savePlotInDir(f, plotname, basedir, plotsubfolder);
        close(f);
        
    end
    
end







