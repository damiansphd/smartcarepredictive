clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

[msfile, isvalid] = selectOverallMissingnessFile();
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
            'pmTrCVFeatureIndex', 'pmTrCVNormFeatures', ...
            'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels', 'pmTrCVExABLabels', 'pmTrCVExABxElLabels', ...
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

if pmOtherRunParams.runtype ~= 1
    fprintf('Missingness Analysis only runs on TrCV results\n');
    return;
end

featureparamsfile = generateFileNameFromFullFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile), 'pmPatients', 'pmAntibiotics', 'pmAMPred', ...
            'pmRawDatacube', 'pmInterpDatacube', 'pmInterpVolcube', 'mvolstats', ...
            'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', 'pmMuIndex', 'pmSigmaIndex', ...
            'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
            'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures', 'npatients');
        
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

pmMSScenarios.MMaskText(:) = {''};
pmMSScenarios = pmMSScenarios(:, {'ScenarioType', 'MMask', 'MMaskText', 'Frequency', 'Duration', 'Percentage'});
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
fprintf('\n');

nfolds = max(pmTrCVPatientSplit.SplitNbr);

btmode     = pmOtherRunParams.btmode(1); 
nbssamples = pmOtherRunParams.nbssamples(1); 
epilen     = pmOtherRunParams.epilen(1);  
lossfunc   = pmOtherRunParams.lossfunc(1); 

lrval  = pmHyperParamQS.HyperParamQS.LearnRate(1);
ntrval = pmHyperParamQS.HyperParamQS.NumTrees(1);
mlsval = pmHyperParamQS.HyperParamQS.MinLeafSize(1);
mnsval = pmHyperParamQS.HyperParamQS.MaxNumSplit(1);
fvsval = pmHyperParamQS.HyperParamQS.FracVarsToSample(1);

labelidx = min(size(pmModelRes.pmNDayRes, 2), 5);

ovmsTrCVQS = createOvMSQSTable(nmsscenarios);

baseoutputfilename = sprintf('%s-%spm%srm%dvo%dpm%dmv%slm%d', ...
                    msfile, pmFeatureParamsRow.StudyDisplayName{1}, pmFeatureParamsRow.FeatVer{1}, ...
                    pmFeatureParamsRow.rawmeasfeat, pmFeatureParamsRow.volfeat, pmFeatureParamsRow.pmeanfeat, ...
                    pmModelParamsRow.ModelVer{1}, pmModelParamsRow.labelmethod);

for i = 1:nmsscenarios
    tic
    % make a temporary copy of the raw data cube
    tmpRawDatacube = pmRawDatacube;
    
    fprintf('%dof%d: Running missingness scenario type %d for measures mask %d:%s Freq %d Duration %d Percent %d%%\n', ...
        i, nmsscenarios, pmMSScenarios.ScenarioType(i), pmMSScenarios.MMask(i), pmMSScenarios.MMaskText{i}, pmMSScenarios.Frequency(i), ...
        pmMSScenarios.Duration(i), pmMSScenarios.Percentage(i));
    
    if pmMSScenarios.ScenarioType(i) > 0
        
        % for all other missingness scenarios, recreate from raw data, apply 
        % missingness, then re-interpolate, smooth and create features and labels
        [pmFeatureIndex, pmNormFeatures, pmIVLabels, pmExLabels, pmABLabels, pmExLBLabels, ...
            pmExABLabels, pmExABxElLabels, tmpRawDatacube, pmMSDatacube, pmMucube, pmSigmacube, ...
            pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, muntilepoints, sigmantilepoints, ...
            pmInterpDatacube, pmInterpVolcube, mvolstats] ...
            = createOvMSScenarionew(pmAMPred, pmAntibiotics, pmPatients, pmPatientMeasStats, tmpRawDatacube, ...
                pmOverallStats, pmMSScenarios(i, :), pmFeatureParamsRow, pmModelParamsRow, measures, nmeasures, npatients, maxdays);
    
        % split Test vs TrCV data
        [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ...
         pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
         pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels,...
         pmTrCVPatientSplit, nfolds] ...
         = splitTestFeatures(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmNormFeatures, pmIVLabels, pmExLabels, ...
                             pmABLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels, pmPatientSplit, nsplits);  
                         
    end
    
    % set labels for label method
    [trcvlabels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);
    
    % set the dates for the relevant scenario date segment
    featdur    = pmFeatureParamsRow.featureduration;
    normwind   = pmFeatureParamsRow.normwindow;
    
    ntrcvexamples = size(pmTrCVNormFeatures, 1);
    pmOvMSRes = createModelDayResStuct(ntrcvexamples, nfolds, nbssamples);
    
    % calculate model quality scores for missingness scenario
    [hyperparamQS, ~, foldhpCVQS, ~] = createHpQSTables(1, nfolds);

    for fold = 1:nfolds
        
        foldhpcomb = fold;
        fprintf('Fold %d: ', fold);
        model = pmModelRes.pmNDayRes.Folds(fold).Model;
        [~, ~, ~, ~, ~, pmCVFeatureIndex, ~, ~, pmCVNormFeatures, cvlabels, cvidx] ...
            = splitTrCVFeatures(pmTrCVFeatureIndex, pmMuIndex, pmSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);
                                    
        fprintf('CV: ');
        [foldhpCVQS, pmCVRes, ~] = calcPredAndQS(model, foldhpCVQS, pmCVFeatureIndex, ...
                                            pmCVNormFeatures, cvlabels, fold, foldhpcomb, pmAMPred, ...
                                            pmPatientSplit, pmModelParamsRow.ModelVer(1), epilen, lossfunc, ...
                                            lrval, ntrval, mlsval, mnsval, fvsval);
                                                    
        % also store results on overall model results structure
        pmOvMSRes.Pred(cvidx) = pmCVRes.Pred; 
        pmOvMSRes.Loss(fold)  = pmCVRes.Loss;
                                                    
    end
    
    fprintf('Overall:\n');
    fprintf('CV: ');
    fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
    [pmOvMSRes, pmAMPredUpd] = calcAllQualScores(pmOvMSRes, trcvlabels, ntrcvexamples, pmAMPred, pmTrCVFeatureIndex, pmPatientSplit, epilen);

    fprintf('\n');
    
    ovmsTrCVQS(i, :) = setOvMSQSrow(ovmsTrCVQS(i, :), pmOvMSRes, i, pmMSScenarios(i,:));
    
    %if btmode == 1
    %   [pmOvMSRes] = calcBSQualScores(pmOvMSRes, mslabels, nbssamples, ntrcvexamples);    
    %end

    % store various MS input tables and results to allow comparing of results etc.
    assignin('base', sprintf('pmOvMSRes_%d', i),          pmOvMSRes);
    assignin('base', sprintf('pmTrCVFeatureIndex_%d', i), pmTrCVFeatureIndex);
    assignin('base', sprintf('pmTrCVNormFeatures_%d', i), pmTrCVNormFeatures);
    assignin('base', sprintf('labels_%d', i),             trcvlabels);
    assignin('base', sprintf('pmRawDatacube_%d', i),      tmpRawDatacube);
    assignin('base', sprintf('pmMSDatacube_%d', i),       pmMSDatacube);
    assignin('base', sprintf('pmInterpDatacube_%d', i),   pmInterpDatacube);
    assignin('base', sprintf('pmInterpVolcube_%d', i),    pmInterpVolcube);
    assignin('base', sprintf('pmMucube_%d', i),           pmMucube);
    assignin('base', sprintf('pmMuNormcube_%d', i),       pmMuNormcube);
    
    toc
    fprintf('\n');
end

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';

fprintf('Saving missingness results to file %s\n', sprintf('%s.mat', baseoutputfilename));
save(fullfile(basedir, subfolder, sprintf('%s.mat', baseoutputfilename)), ...
     'ovmsTrCVQS', 'pmOvMSRes', 'pmMSScenarios', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

subfolder = 'ExcelFiles';
fprintf('Writing missingness results to file %s\n', sprintf('%s.xlsx', baseoutputfilename));
writetable(ovmsTrCVQS, fullfile(basedir, subfolder, sprintf('%s.xlsx', baseoutputfilename)), 'Sheet', 'OvMS_QS');
 
toc
fprintf('\n');

if ismember(studydisplayname, 'SC')
    colours = [ 150, 150, 150; ...
                150, 150, 150; ...
                250, 191, 143; ...
                196, 215, 155; ...
                196, 215, 155; ...
                196, 215, 155; ...
                250, 191, 143; ...
                247, 150,  70; ...
                155, 187,  89; ...
                 79, 129, 189];
end
colours = colours ./ 255;

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
if ~exist(fullfile(basedir, plotsubfolder), 'dir')
    mkdir(fullfile(basedir, plotsubfolder));
end

[msfile, isvalid] = selectOverallMissingnessFile();

baseoutputfilename = sprintf('%s-%spm%srm%dvo%dpm%dmv%slm%d', ...
                    msfile, pmFeatureParamsRow.StudyDisplayName{1}, pmFeatureParamsRow.FeatVer{1}, ...
                    pmFeatureParamsRow.rawmeasfeat, pmFeatureParamsRow.volfeat, pmFeatureParamsRow.pmeanfeat, ...
                    pmModelParamsRow.ModelVer{1}, pmModelParamsRow.labelmethod);

load(fullfile(basedir, subfolder, sprintf('%s.mat'), baseoutputfilename));

plotsacross = 2;
plotsdown = 4;
fontname = 'Arial';
plotname = sprintf('%s-QS', baseoutputfilename);
qsarray = {'AvgEPV'; 'PRAUC'; 'ROCAUC'; 'PosAcc'};
nqs = size (qsarray, 1);

[f1, p1] = createFigureAndPanel(plotname, 'Portrait', 'A4');

for i = 1:nqs
    ax = subplot(plotsdown, plotsacross, i, 'Parent', p1);
    
    hold on;
    for n = 1:nmsscenarios
        b = bar(ax, ovmsTrCVQS.ScenarioNbr(n), table2array(ovmsTrCVQS(n, qsarray{i})));
        xlabeltext(n) = ovmsTrCVQS.MMaskText(n);
        b.FaceColor = colours(n,:);
    end
    ax.FontSize = 6;
    ax.FontName = fontname;
    xticks(ax, 1:nmsscenarios);
    ax.XTickLabel = xlabeltext;
    xtickangle(ax, 45);
    xlabel(ax, 'Scenario', 'FontSize', 8);
    ylabel(ax, qsarray{i}, 'FontSize', 8);
    xlim(ax, [0.4, nmsscenarios + 0.6]);
    title(ax, qsarray{i}, 'FontSize', 12);
    
end

if exist('f1', 'var')
    savePlotInDir(f1, plotname, basedir, plotsubfolder);
    close(f1);
end

