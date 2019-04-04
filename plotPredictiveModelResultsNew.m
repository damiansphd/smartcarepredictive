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

featureparamsfile = generateFileNameFromFullFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile));
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));

labelidx = min(size(pmModelRes.pmNDayRes, 2), 5);

[plottype, validresponse] = selectPlotType;
if ~validresponse
    return;
end

if (plottype == 2 || plottype == 4)
    if (pmModelParamsRow.labelmethod == 5 || pmModelParamsRow.labelmethod == 6)
        selectdays = 1;
    else
        selectdays = setFocusDays();
    end
end

[trcvlabels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);

if plottype == 1
    % plot weights
    fprintf('Plotting Model Weights\n');
    plotModelWeights(pmModelRes, pmTrCVNormFeatures, measures, nmeasures, pmTrCVPatientSplit, ...
        pmFeatureParamsRow, pmModelParamsRow, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 2
    % plot weights for days 2, 5, 8
    fprintf('Plotting Model Weights for selected prediction days\n');
    plotSelectModelWeights(pmModelRes, measures, nmeasures, ...
        pmFeatureParamsRow, pmModelParamsRow, selectdays, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 3    
    % plot PR and ROC Curves
    fprintf('Plotting PR and ROC Curves\n');
    plotPRAndROCCurves(pmModelRes, pmFeatureParamsRow, lbdisplayname, plotsubfolder, basemodelresultsfile);
elseif plottype == 4    
    % plot PR and ROC Curves for days 2, 5, 8
    fprintf('Plotting PR and ROC Curves for selected prediction days\n');
    plotSelectPRAndROCCurves(pmModelRes, selectdays, lbdisplayname, plotsubfolder, basemodelresultsfile);      
elseif plottype == 5
    % plot measures and predictions for all non-test set patients
    ntrcvpatients = size(pmTrCVPatientSplit,1);
    for p = 1:ntrcvpatients
        pnbr = pmTrCVPatientSplit.PatientNbr(p);
        fprintf('Plotting results for patient %d\n', pnbr);
        plotMeasuresAndPredictionsForPatient(pmPatients(pnbr,:), ...
            pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
            pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
            pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
            pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
            pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
            measures, nmeasures, mvolstats, labelidx, pmFeatureParamsRow, lbdisplayname, ...
            plotsubfolder, basemodelresultsfile);
    end
elseif plottype == 6
    % plot measures and predictions for a single patient
    [pnbr, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    fprintf('Plotting results for patient %d\n', pnbr);
    plotMeasuresAndPredictionsForPatient(pmPatients(pnbr,:), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
        pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
        pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, mvolstats, labelidx, pmFeatureParamsRow, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 7
    % plot volatility measures for all patients
    ntrcvpatients = size(pmTrCVPatientSplit,1);
    for p = 1:ntrcvpatients
        pnbr = pmTrCVPatientSplit.PatientNbr(p);
        fprintf('Plotting volatility measures for patient %d\n', pnbr);
        plotVolatilityMeasuresForPatient(pmPatients(pnbr,:), ...
            pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
            pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
            pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
            pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
            measures, nmeasures, mvolstats, plotsubfolder, basemodelresultsfile);
    end
elseif plottype == 8
    % plot volatility measures for a single patient
    [pnbr, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    fprintf('Plotting volatility measures for patient %d\n', pnbr);
    plotVolatilityMeasuresForPatient(pmPatients(pnbr,:), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= 1 & pmAntibiotics.RelStartdn <= pmPatients.RelLastMeasdn(pnbr),:), ...
        pmAMPred(pmAMPred.PatientNbr == pnbr,:), ...
        pmRawDatacube(pnbr, :, :), pmInterpDatacube(pnbr, :, :), pmInterpVolcube(pnbr, :, :), ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, mvolstats, plotsubfolder, basemodelresultsfile);
elseif plottype == 9
    % visualise the best and worst results
    [pmAMPredTest] = plotBestAndWorstPred(pmPatients, pmAntibiotics, ...
        pmAMPred(ismember(pmAMPred.PatientNbr, pmTrCVPatientSplit.PatientNbr),:), ...
        pmRawDatacube, pmInterpDatacube, pmTrCVPatientSplit, ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats, ...
        measures, nmeasures, labelidx, pmFeatureParamsRow, ...
        lbdisplayname, plotsubfolder, basemodelresultsfile);
elseif plottype == 10
    % analyse the model prediction components
    [pnbr, validresponse] = selectPatientNbr(pmTrCVPatientSplit.PatientNbr);
    if ~validresponse
        return;
    end
    [calcdatedn, validresponse] = selectCalcDate(min(pmTrCVFeatureIndex.CalcDatedn(pmTrCVFeatureIndex.PatientNbr == pnbr)), ...
                                                 max(pmTrCVFeatureIndex.CalcDatedn(pmTrCVFeatureIndex.PatientNbr == pnbr)));
    if ~validresponse
        return;
    end
    analyseModelPrediction(pmPatients(pnbr,:), calcdatedn, ...
        pmTrCVFeatureIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, pmModelRes, ...
        measures, nmeasures, labelidx, pmFeatureParamsRow, lbdisplayname, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 11
    plotExByMonth(pmAMPred, pmTrCVFeatureIndex, trcvlabels, pmTrCVPatientSplit, ...
        pmModelRes, basemodelresultsfile, plotsubfolder, lbdisplayname);
elseif plottype == 12
    modelcalibration = calcModelCalibrationByFold(pmTrCVFeatureIndex, pmTrCVPatientSplit, trcvlabels(:, labelidx), ...
        pmModelRes.pmNDayRes(labelidx), basemodelresultsfile, plotsubfolder, lbdisplayname, labelidx);
end


