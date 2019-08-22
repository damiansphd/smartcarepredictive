clear; close all; clc;

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
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), 'pmModelRes', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmTrCVFeatureIndex', 'pmTrCVNormFeatures', ...
    'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels', 'pmTrCVExABLabels', 'pmTrCVExABxElLabels','pmTrCVPatientSplit');

% added for backward compatibility
if exist('pmTrCVExABxElLabels', 'var') ~= 1
    pmTrCVExABxElLabels = [];
end

featureparamsfile = generateFileNameFromFullFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile));
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));

labelidx = min(size(pmModelRes.pmNDayRes, 2), 5);

fprintf('Run Plots For Paper\n');
fprintf('\n');
fprintf('Choose plot to run\n');
fprintf('----------------------\n');
fprintf('6: Paper Figure 6 - Example Measures And Prediction\n');
fprintf('7: Paper Figure 7 - Quality Scores Results\n');
fprintf('8: Paper Figure 8 - Comparison to Current Clinical Practice\n');

srunfunction = input('Choose function (6=8): ', 's');
runfunction = str2double(srunfunction);

if (isnan(runfunction) || runfunction < 6 || runfunction > 8)
    fprintf('Invalid choice\n');
    runfunction = -1;
    return;
end

[trcvlabels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);

if runfunction == 6
    % plot measures and predictions for a single patient
    [pnbr, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    fprintf('Plotting results for patient %d\n', pnbr);
    plotMeasuresAndPredictionsForPatientForPaper(pmPatients(pnbr,:), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
        pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
        pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, mvolstats, labelidx, pmFeatureParamsRow, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile, studydisplayname);
elseif runfunction == 7
    % Quality Scores Results
    plotPRAndROCCurvesForPaper(pmModelRes, pmFeatureParamsRow, lbdisplayname, plotsubfolder, basemodelresultsfile);
    
elseif runfunction == 8
    % Comparison to Current Clinical Practice
    epilen = 7;
    plotModelQualityScoresForPaper(pmTrCVFeatureIndex, pmModelRes, pmTrCVExABLabels, pmAMPred, plotsubfolder, basemodelresultsfile, epilen);
end


