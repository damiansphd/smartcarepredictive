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

%elecongoingtreatfile = sprintf('%sElecOngoingTreat.xlsx', studydisplayname);
%fprintf('Loading elective and ongoing treatment list from file %s\n', elecongoingtreatfile);
%elecongoingtreat = readtable(fullfile(basedir, 'DataFiles', elecongoingtreatfile));
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));

labelidx = min(size(pmModelRes.pmNDayRes, 2), 5);

fprintf('Run Plots For Paper\n');
fprintf('\n');
fprintf('Choose plot to run\n');
fprintf('----------------------\n');
fprintf(' 6: Paper Figure 6 - Example Measures And Prediction\n');
fprintf(' 7: Paper Figure 7 - Quality Scores Results\n');
fprintf(' 8: Paper Figure 8 - Comparison to Current Clinical Practice\n');
fprintf(' 9: Paper Figure 8 - Comparison to Current Clinical Practice - Random classifier\n');
fprintf('10: Paper Figure 6 Appendix - Example All Measures And Prediction\n');
fprintf('11: Old Paper Figure 6 - Example Measures And Prediction for Single Participant\n');

srunfunction = input('Choose function (6-9): ', 's');
runfunction = str2double(srunfunction);

if (isnan(runfunction) || runfunction < 6 || runfunction > 10)
    fprintf('Invalid choice\n');
    runfunction = -1;
    return;
end

[trcvlabels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);

if runfunction == 6
    % plot measures and predictions for a single patient
    [pnbr1, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    [pnbr2, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    fprintf('Plotting results for patient %d and %d\n', pnbr1, pnbr2);
    pnbr = [pnbr1; pnbr2];
    plotMeasuresAndPredictionsForPatientForPaper3(pmPatients(pnbr1,:), pmPatients(pnbr2,:),...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr1 & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr1),:), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr2 & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr2),:), ...
        pmAMPred(pmAMPred.PatientNbr == pnbr1,:), pmAMPred(pmAMPred.PatientNbr == pnbr2,:), ...
        pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, pmOverallStats, ...
        pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr1,:), ...
        pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr2,:), ...
        measures, labelidx, pmFeatureParamsRow, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile, studydisplayname);
elseif runfunction == 7
    % Quality Scores Results
    plotPRAndROCCurvesForPaper(pmModelRes, pmFeatureParamsRow, lbdisplayname, plotsubfolder, basemodelresultsfile);
    
elseif runfunction == 8
    % Comparison to Current Clinical Practice
    epilen = 7;
    temppmAMPred = pmAMPred;
    randmode = false;
    %pmAMPred = pmAMPred(~ismember(pmAMPred.IntrNbr, elecongoingtreat.IntrNbr),:);
    pmAMPred = pmAMPred(~ismember(pmAMPred.ElectiveTreatment, 'Y'),:);
    [epipred, epifpr, epiavgdelayreduction, trigintrtpr, avgtrigdelay, untrigpmampred] = plotModelQualityScoresForPaper2(pmTrCVFeatureIndex, pmModelRes, trcvlabels, pmAMPred, plotsubfolder, basemodelresultsfile, epilen, randmode);
elseif runfunction == 9
    % Comparison to Current Clinical Practice - random classifier mode
    epilen = 7;
    temppmAMPred = pmAMPred;
    randmode = true;
    %pmAMPred = pmAMPred(~ismember(pmAMPred.IntrNbr, elecongoingtreat.IntrNbr),:);
    pmAMPred = pmAMPred(~ismember(pmAMPred.ElectiveTreatment, 'Y'),:);
    [epipred, epifpr, epiavgdelayreduction, trigintrtpr, avgtrigdelay, untrigpmampred] = plotModelQualityScoresForPaper2(pmTrCVFeatureIndex, pmModelRes, trcvlabels, pmAMPred, plotsubfolder, basemodelresultsfile, epilen, randmode);
elseif runfunction == 10
    % plot measures and predictions for a single patient - version with all
    % measures for appendix
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
elseif runfunction == 11
    % plot measures and predictions for a single patient
    [pnbr, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    fprintf('Plotting results for patient %d\n', pnbr);
    plotMeasuresAndPredictionsForPatientForPaper2(pmPatients(pnbr,:), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
        pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
        pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, mvolstats, labelidx, pmFeatureParamsRow, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile, studydisplayname);
end


