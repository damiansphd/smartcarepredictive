clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

[msfile, isvalid] = selectMissingnessFile();
if ~isvalid
    return;
end

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

[basemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, ' ModelResults', '');

tic
subfolder = 'DataFiles';
pmMSScenarios   = readtable(fullfile(basedir, subfolder, sprintf('%s.xlsx', msfile)));
nmsscenarios    = size(pmMSScenarios, 1);
if ~any(ismember(pmMSScenarios.Properties.VariableNames, {'Percentage'}))
    pmMSScenarios.Percentage(:) = 0.0;
end
if ~any(ismember(pmMSScenarios.Properties.VariableNames, {'Frequency'}))
    pmMSScenarios.Frequency(:) = 0.0;
end
if ~any(ismember(pmMSScenarios.Properties.VariableNames, {'Duration'}))
    pmMSScenarios.Duration(:) = 0.0;
end

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
            'pmTestFeatureIndex', 'pmTestNormFeatures', ...
            'pmTestIVLabels', 'pmTestExLabels', 'pmTestABLabels', 'pmTestExLBLabels', 'pmTestExABLabels', 'pmTestExABxElLabels', ...
            'pmTestPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

if pmOtherRunParams.runtype ~= 2
    fprintf('Missingness Analysis only runs on held-out test results\n');
    return;
end

featureparamsfile = generateFileNameFromFullFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile), 'pmPatients', 'pmAntibiotics', 'pmAMPred', ...
            'pmRawDatacube', 'pmInterpDatacube', 'pmInterpVolcube', 'mvolstats', ...
            'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
            'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
            'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures');
        
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

pmMSScenarios.MMaskText(:) = {''};
pmMSScenarios = pmMSScenarios(:, {'PatientNbr', 'Study', 'ID', 'ScaledDateNumFrom', 'ScaledDateNumTo', ...
    'ScenarioType', 'MMask', 'MMaskText', 'Frequency', 'Duration', 'Percentage'});
for i = 1:nmsscenarios
    [remidx] = convertMeasureCombToMask(pmMSScenarios.MMask(i), measures, nmeasures);
    if sum(remidx) == 0
        pmMSScenarios.MMaskText(i) = {'None'};
    elseif sum(remidx) == nmeasures
        pmMSScenarios.MMaskText(i) = {'All'};
    elseif sum(remidx) > 0
        pmMSScenarios.MMaskText(i) = {strcat(measures.ShortName{remidx})};
    end
end


plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
if ~exist(fullfile(basedir, plotsubfolder), 'dir')
    mkdir(fullfile(basedir, plotsubfolder));
end

nbssamples = pmOtherRunParams.nbssamples(1); 
epilen     = pmOtherRunParams.epilen(1);  
lossfunc   = pmOtherRunParams.lossfunc(1); 

lrval  = pmHyperParamQS.HyperParamQS.LearnRate(1);
ntrval = pmHyperParamQS.HyperParamQS.NumTrees(1);
mlsval = pmHyperParamQS.HyperParamQS.MinLeafSize(1);
mnsval = pmHyperParamQS.HyperParamQS.MaxNumSplit(1);
fvsval = pmHyperParamQS.HyperParamQS.FracVarsToSample(1);

labelidx = min(size(pmModelRes.pmNDayRes, 2), 5);

[labels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, pmTestExABLabels, pmTestExABxElLabels);
%testlabels = labels(:);

fold     = 1;
foldhpcomb = 1;

model    = pmModelRes.pmNDayRes.Folds(fold).Model;
msTestQS = createMSQSTable(nmsscenarios);

plotsacross = 1;
plotsdown = 10;
page = 1;
npages = ceil(nmsscenarios / plotsdown);
baseoutputfilename = sprintf('%s-%spm%srm%dvo%dpm%dmv%slm%d', ...
                    msfile, pmFeatureParamsRow.StudyDisplayName{1}, pmFeatureParamsRow.FeatVer{1}, ...
                    pmFeatureParamsRow.rawmeasfeat, pmFeatureParamsRow.volfeat, pmFeatureParamsRow.pmeanfeat, ...
                    pmModelParamsRow.ModelVer{1}, pmModelParamsRow.labelmethod);
plotname = sprintf('%s P%dof%d', baseoutputfilename, page, npages);
[f1, p1] = createFigureAndPanel(plotname, 'Portrait', 'A4');
thisplot = 1;

for i = 1:nmsscenarios
        
    pmMSPatient           = pmPatients(        pmPatients.PatientNbr         == pmMSScenarios.PatientNbr(i), :);
    pmMSAMPred            = pmAMPred(          pmAMPred.PatientNbr           == pmMSScenarios.PatientNbr(i), :);
    pmMSAntibiotics       = pmAntibiotics(     pmAntibiotics.PatientNbr      == pmMSScenarios.PatientNbr(i), :);
    pmMSPatientSplit      = pmPatientSplit(    pmPatientSplit.PatientNbr     == pmMSScenarios.PatientNbr(i), :);
    pmMSPatientMeasStats  = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pmMSScenarios.PatientNbr(i), :);
    
    pmMSRawDatacube       = pmRawDatacube(      pmMSScenarios.PatientNbr(i), :, :);
    pmMSMucube            = pmMucube(           pmMSScenarios.PatientNbr(i), :, :);
    pmMSSigmacube         = pmSigmacube(        pmMSScenarios.PatientNbr(i), :, :);
    pmMSMuNormcube        = pmMuNormcube(       pmMSScenarios.PatientNbr(i), :, :);
    pmMSSigmaNormcube     = pmSigmaNormcube(    pmMSScenarios.PatientNbr(i), :, :);
    pmMSBuckMuNormcube    = pmBuckMuNormcube(   pmMSScenarios.PatientNbr(i), :, :, :);
    pmMSBuckSigmaNormcube = pmBuckSigmaNormcube(pmMSScenarios.PatientNbr(i), :, :, :);
    
    if pmMSScenarios.ScenarioType(i) == 0
        
        % re-use actual data from the model run
        pmMSInterpDatacube = pmInterpDatacube(pmMSScenarios.PatientNbr(i), :, :);
        pmMSInterpVolcube  = pmInterpVolcube(pmMSScenarios.PatientNbr(i), :, :);
        msmvolstats        = mvolstats;
        
        pidx               = pmTestFeatureIndex.PatientNbr == pmMSScenarios.PatientNbr(i);
        pmMSFeatureIndex   = pmTestFeatureIndex(pidx, :);
        pmMSNormFeatures   = pmTestNormFeatures(pidx, :);
        mslabels           = labels(pidx);
        
        
    else
        % recreate from raw data, apply missingness, then re-interpolate,
        % smooth and create features and labels
        
        % reset patient nbr
        pmMSPatient.PatientNbr(:)          = 1;
        pmMSAMPred.PatientNbr(:)           = 1;
        pmMSAntibiotics.PatientNbr(:)      = 1;
        pmMSPatientSplit.PatientNbr(:)     = 1;
        pmMSPatientMeasStats.PatientNbr(:) = 1;
        
        msnpatients    = 1;
        msmaxdays = pmMSPatient.RelLastMeasdn;
        
        % apply missingness and then recreate cubes, features, labels
        [pmMSFeatureIndex, pmMSNormFeatures, mslabels, pmMSRawDatacube, pmMSDatacube, pmMSInterpDatacube, pmMSInterpVolcube, msmvolstats] ...
            = createMSScenarionew(pmMSAMPred, pmMSAntibiotics, pmMSPatient, pmMSPatientMeasStats, ...
                pmMSRawDatacube, pmOverallStats, pmMSMucube, pmMSSigmacube, pmMSMuNormcube, pmMSSigmaNormcube, ...
                pmMSBuckMuNormcube, pmMSBuckSigmaNormcube, ...
                pmMSScenarios(i, :), pmFeatureParamsRow, pmModelParamsRow, measures, nmeasures, msnpatients, msmaxdays);
         
    end  
        
    % set the dates for the relevant scenario date segment
    featdur    = pmFeatureParamsRow.featureduration;
    normwind   = pmFeatureParamsRow.normwindow;
    fromdn     = pmMSScenarios.ScaledDateNumFrom(i) - featdur - normwind + 1;
    todn       = pmMSScenarios.ScaledDateNumTo(i);
    
    % reset patient dates & extract relevant segment of data
    pmMSPatient.RelLastMeasdn = todn - fromdn + 1;
    pmMSPatient.LastMeasdn    = pmMSPatient.FirstMeasdn   + todn        - 1;
    pmMSPatient.FirstMeasdn   = pmMSPatient.FirstMeasdn   + fromdn      - 1;
    pmMSPatient.LastMeasDate  = pmMSPatient.FirstMeasDate + days(todn   - 1);
    pmMSPatient.FirstMeasDate = pmMSPatient.FirstMeasDate + days(fromdn - 1);

    pmMSAMPred.IVScaledDateNum     = pmMSAMPred.IVScaledDateNum     - fromdn + 1;
    pmMSAMPred.IVScaledStopDateNum = pmMSAMPred.IVScaledStopDateNum - fromdn + 1;
    pmMSAMPred.Pred                = pmMSAMPred.Pred                - fromdn + 1;
    pmMSAMPred.RelLB1              = pmMSAMPred.RelLB1              - fromdn + 1;
    pmMSAMPred.RelUB1              = pmMSAMPred.RelUB1              - fromdn + 1;
    if pmMSAMPred.RelLB2 ~= -1
        pmMSAMPred.RelLB2          = pmMSAMPred.RelLB2              - fromdn + 1;
        pmMSAMPred.RelUB2          = pmMSAMPred.RelUB2              - fromdn + 1;
    end
    
    pmMSAntibiotics.RelStartdn = pmMSAntibiotics.RelStartdn - fromdn + 1;
    pmMSAntibiotics.RelStopdn  = pmMSAntibiotics.RelStopdn  - fromdn + 1;
    
    msidx      = pmMSFeatureIndex.CalcDatedn >= pmMSScenarios.ScaledDateNumFrom(i) & ...
                 pmMSFeatureIndex.CalcDatedn <= pmMSScenarios.ScaledDateNumTo(i);

    pmMSFeatureIndex   = pmMSFeatureIndex(msidx, :);
    pmMSFeatureIndex.CalcDatedn = pmMSFeatureIndex.CalcDatedn - fromdn + 1;
    
    pmMSNormFeatures   = pmMSNormFeatures(msidx, :);
    mslabels           = mslabels(msidx);
       
    pmMSRawDatacube       = pmMSRawDatacube(      1, fromdn:todn, :);
    pmMSDatacube          = pmMSDatacube(         1, fromdn:todn, :);
    pmMSInterpDatacube    = pmMSInterpDatacube(   1, fromdn:todn, :);
    pmMSInterpVolcube     = pmMSInterpVolcube(    1, fromdn:todn, :);
    pmMSMucube            = pmMSMucube(           1, fromdn:todn, :);
    pmMSSigmacube         = pmMSSigmacube(        1, fromdn:todn, :);
    pmMSMuNormcube        = pmMSMuNormcube(       1, fromdn:todn, :);
    pmMSSigmaNormcube     = pmMSSigmaNormcube(    1, fromdn:todn, :);
    pmMSBuckMuNormcube    = pmMSBuckMuNormcube(   1, fromdn:todn, :, :);
    pmMSBuckSigmaNormcube = pmMSBuckSigmaNormcube(1, fromdn:todn, :, :);
    
    % calculate model quality scores for missingness scenario
    [~, ~, ~, foldhpTestQS] = createHpQSTables(1, 1);

    fprintf('Test: ');
    [foldhpTestQS, pmMSRes, pmAMPredUpd] = calcPredAndQS(model, foldhpTestQS, pmMSFeatureIndex, ...
                                                        pmMSNormFeatures, mslabels, fold, foldhpcomb, pmMSAMPred, ...
                                                        pmMSPatientSplit, pmModelParamsRow.ModelVer(1), epilen, lossfunc, ...
                                                        lrval, ntrval, mlsval, mnsval, fvsval);

    msTestQS(i, :) = convertFoldHPToMSTable(msTestQS(i, :), foldhpTestQS, i, pmMSScenarios(i,:));
    
    if sum(mslabels) > 0
        msTestQS.MaxTPred(i) = 100 *  max(pmMSRes.Pred(mslabels));
        msTestQS.AvgTPred(i) = 100 * mean(pmMSRes.Pred(mslabels));
    end
    if sum(~mslabels) > 0
        msTestQS.MinFPred(i) = 100 *  min(pmMSRes.Pred(~mslabels));
        msTestQS.AvgFPred(i) = 100 * mean(pmMSRes.Pred(~mslabels));
    end
    
    fprintf('\n');
    
    % store various MS input tables and results to allow comparing of results etc.
    assignin('base', sprintf('pmMSRes_%d', i),            pmMSRes);
    assignin('base', sprintf('pmMSFeatureIndex_%d', i),   pmMSFeatureIndex);
    assignin('base', sprintf('pmMSNormFeatures_%d', i),   pmMSNormFeatures);
    assignin('base', sprintf('mslabels_%d', i),           mslabels);
    assignin('base', sprintf('pmMSPatients_%d', i),       pmMSPatient);
    assignin('base', sprintf('pmMSAMPred_%d', i),         pmMSAMPred);
    assignin('base', sprintf('pmMSAntibiotics_%d', i),    pmMSAntibiotics);
    assignin('base', sprintf('pmMSPatientSplit_%d', i),   pmMSPatientSplit);
    assignin('base', sprintf('pmMSRawDatacube_%d', i),    pmMSRawDatacube);
    assignin('base', sprintf('pmMSDatacube_%d', i),       pmMSDatacube);
    assignin('base', sprintf('pmMSInterpDatacube_%d', i), pmMSInterpDatacube);
    assignin('base', sprintf('pmMSInterpVolcube_%d', i),  pmMSInterpVolcube);
    assignin('base', sprintf('pmMSMucube_%d', i),         pmMSMucube);
    assignin('base', sprintf('pmMSMuNormcube_%d', i),     pmMSMuNormcube);
    
    
    % add plot of prediction + measures
    basefilename = sprintf('%sP%d(ID%d)D%d-%dty%dms%d%sfr%ddu%d', ...
                    baseoutputfilename, ... 
                    pmMSScenarios.PatientNbr(i), pmMSScenarios.ID(i), pmMSScenarios.ScaledDateNumFrom(i), ...
                    pmMSScenarios.ScaledDateNumTo(i), pmMSScenarios.ScenarioType(i), pmMSScenarios.MMask(i), ...
                    pmMSScenarios.MMaskText{i}, pmMSScenarios.Frequency(i), pmMSScenarios.Duration(i));
    
    if pmMSScenarios.ScenarioType(i) == 0
        tmpModelRes.pmNDayRes = pmMSRes;
        plotMeasuresAndPredictionsForPatient(pmMSPatient, ...
            pmMSAntibiotics(pmMSAntibiotics.RelStopdn >= pmMSPatient.RelFirstMeasdn & pmMSAntibiotics.RelStartdn <= pmMSPatient.RelLastMeasdn,:), ...
            pmMSAMPred, ...
            pmMSRawDatacube(1, :, :), pmMSInterpDatacube(1, :, :), pmMSInterpVolcube(1, :, :), ...
            pmMSFeatureIndex, mslabels, tmpModelRes, ...
            pmOverallStats, pmMSPatientMeasStats, ...
            measures, nmeasures, msmvolstats, labelidx, pmFeatureParamsRow, lbdisplayname, ...
            plotsubfolder, basefilename);
    end
    
    % add prediction plot to missingness summary plot
    xdays = (1:pmMSPatient.RelLastMeasdn);
    xl = [1 pmMSPatient.RelLastMeasdn];
    pivabsdates = pmMSAntibiotics(ismember(pmMSAntibiotics.Route, 'IV'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    for ab = 1:size(pivabsdates,1)
        if pivabsdates.Startdn(ab) < pmMSPatient.FirstMeasdn
            pivabsdates.Startdn(ab)    = pmMSPatient.FirstMeasdn;
            pivabsdates.RelStartdn(ab) = 1;
        end
        if pivabsdates.Stopdn(ab) > pmMSPatient.LastMeasdn
            pivabsdates.Stopdn(ab)    = pmMSPatient.LastMeasdn;
            pivabsdates.RelStopdn(ab) = pmMSPatient.RelLastMeasdn;
        end
    end

    poralabsdates = pmMSAntibiotics(ismember(pmMSAntibiotics.Route, 'Oral'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    for ab = 1:size(poralabsdates,1)
        if poralabsdates.Startdn(ab) < pmMSPatient.FirstMeasdn
            poralabsdates.Startdn(ab)    = pmMSPatient.FirstMeasdn;
            poralabsdates.RelStartdn(ab) = 1;
        end
        if poralabsdates.Stopdn(ab) > pmMSPatient.LastMeasdn
            poralabsdates.Stopdn(ab)    = pmMSPatient.LastMeasdn;
            poralabsdates.RelStopdn(ab) = pmMSPatient.RelLastMeasdn;
        end
    end

    pexstsdates = pmMSAMPred(:, {'IVStartDate', 'IVDateNum', 'Offset', 'Ex_Start', ...
    'LowerBound1', 'UpperBound1', 'LowerBound2', 'UpperBound2', ...
    'Pred', 'RelLB1', 'RelUB1', 'RelLB2', 'RelUB2'});

    ppreddata = nan(1, pmMSPatient.RelLastMeasdn);
    plabeldata = nan(1, pmMSPatient.RelLastMeasdn);
    for d = 1:size(pmMSRes.Pred,1)
        ppreddata(pmMSFeatureIndex.CalcDatedn(d))  = pmMSRes.Pred(d);
        plabeldata(pmMSFeatureIndex.CalcDatedn(d)) = mslabels(d);
    end
    
    ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p1);
    xlim(xl);
    yl = [0 1];
    ylim(yl);
    plottitle = basefilename;
    [xl, yl] = plotMeasurementData(ax1, xdays, plabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1, xdays, ppreddata, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

    for ab = 1:size(poralabsdates, 1)
        hold on;
        plotFillArea(ax1, poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
        hold off;
    end
    for ab = 1:size(pivabsdates, 1)
        hold on;
        plotFillArea(ax1, pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    for ex = 1:size(pexstsdates, 1)
        hold on;
        [xl, yl] = plotVerticalLine(ax1, pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
        plotFillArea(ax1, pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        if pexstsdates.RelLB2(ex) ~= -1
            plotFillArea(ax1, pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        end
    end
    
    thisplot = thisplot + 1;
    if thisplot > plotsdown
        savePlotInDir(f1, plotname, basedir, plotsubfolder);
        close(f1);
        clear('f1');
        page = page + 1;
        thisplot = 1;
        if page <= npages
            plotname = sprintf('%s P%dof%d', baseoutputfilename, page, npages);
            [f1, p1] = createFigureAndPanel(plotname, 'Portrait', 'A4');
        end
    end
        
end

if exist('f1', 'var')
    savePlotInDir(f1, plotname, basedir, plotsubfolder);
    close(f1);
end
    
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';

fprintf('Saving missingness results to file %s\n', sprintf('%s.mat', baseoutputfilename));
save(fullfile(basedir, subfolder, sprintf('%s.mat', baseoutputfilename)), ...
     'msTestQS', 'pmMSScenarios', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

subfolder = 'ExcelFiles';
fprintf('Writing missingness results to file %s\n', sprintf('%s.xlsx', baseoutputfilename));
writetable(msTestQS, fullfile(basedir, subfolder, sprintf('%s.xlsx', baseoutputfilename)), 'Sheet', 'MS_QS');
 
toc
fprintf('\n');





