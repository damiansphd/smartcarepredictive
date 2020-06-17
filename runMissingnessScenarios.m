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
[basemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, ' ModelResults', '');

tic
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
            'pmRawDatacube', 'pmInterpDatacube', 'pmInterpVolcube', ...
            'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
            'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
            'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures');
        
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));

toc
fprintf('\n');

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
testlabels = labels(:);

subfolder = 'DataFiles';
scenariofile     = sprintf('%smissingnessexamples.xlsx', pmFeatureParamsRow.StudyDisplayName{1});
pmMSScenarios   = readtable(fullfile(basedir, subfolder, scenariofile));
nmsscenarios    = size(pmMSScenarios, 1);

fold     = 1;
foldhpcomb = 1;

model    = pmModelRes.pmNDayRes.Folds(fold).Model;
msTestQS = createMSQSTable(nmsscenarios);
msTestStruct = struct('Scenario'      , []);

for i = 1:nmsscenarios
        
    if pmMSScenarios.ScenarioType(i) == 0
        % base case using actual features from original model run for
        % the missingness scenario
        featdur    = pmFeatureParamsRow.featureduration;
        normwind   = pmFeatureParamsRow.normwindow;
        fromdn     = pmMSScenarios.ScaledDateNumFrom(i) - featdur - normwind + 1;
        todn       = pmMSScenarios.ScaledDateNumTo(i);

        msidx = pmTestFeatureIndex.PatientNbr == pmMSScenarios.PatientNbr(i) & ...
                pmTestFeatureIndex.CalcDatedn >= pmMSScenarios.ScaledDateNumFrom(i) & ...
                pmTestFeatureIndex.CalcDatedn <= pmMSScenarios.ScaledDateNumTo(i);

        pmMSFeatureIndex   = pmTestFeatureIndex(msidx, :);
        pmMSNormFeatures   = pmTestNormFeatures(msidx, :);
        nmsexamples        = size(pmMSNormFeatures, 1);
        mslabels           = labels(msidx);
       
        pmMSPatients       = pmPatients(pmPatients.PatientNbr == pmMSScenarios.PatientNbr(i), :);
        pmMSAMPred         = pmAMPred(pmAMPred.PatientNbr == pmMSScenarios.PatientNbr(i), :);
        pmMSAntibiotics    = pmAntibiotics(pmAntibiotics.PatientNbr == pmMSScenarios.PatientNbr(i), :);
        pmMSPatientSplit   = pmPatientSplit(pmPatientSplit.PatientNbr == pmMSScenarios.PatientNbr(i), :);
        
        pmMSRawDatacube    = pmRawDatacube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        pmMSInterpDatacube = pmInterpDatacube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        pmMSInterpVolcube  = pmInterpVolcube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        pmMSMucube         = pmMucube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        pmMSSigmacube      = pmSigmacube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        pmMSMuNormcube     = pmMuNormcube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        pmMSSigmaNormcube  = pmSigmaNormcube(pmMSScenarios.PatientNbr(i), fromdn:todn, :);
        
    else 
        [pmMSFeatureIndex, pmMSNormFeatures, mslabels, pmMSAMPred, pmMSAntibiotics, pmMSPatients, ...
            pmMSPatientSplit, pmMSRawDatacube, pmMSInterpDatacube, pmMSInterpVolcube, ...
            pmMSMucube, pmMSSigmacube, pmMSMuNormcube, pmMSSigmaNormcube] ...
            = createMSScenario(pmAMPred, pmAntibiotics, pmPatients, pmPatientSplit, pmPatientMeasStats, pmRawDatacube, ...
                    pmOverallStats, pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
                    pmMSScenarios(i, :), pmFeatureParamsRow, pmModelParamsRow, measures, nmeasures);
    end
    
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
    
    % store various MS input tables and results to allow comparing of results etc.
    
    assignin('base', sprintf('pmMSRes_%d', i),            pmMSRes);
    assignin('base', sprintf('pmMSFeatureIndex_%d', i),   pmMSFeatureIndex);
    assignin('base', sprintf('pmMSNormFeatures_%d', i),   pmMSNormFeatures);
    assignin('base', sprintf('mslabels_%d', i),           mslabels);
    assignin('base', sprintf('pmMSPatients_%d', i),       pmMSPatients);
    assignin('base', sprintf('pmMSAMPred_%d', i),         pmMSAMPred);
    assignin('base', sprintf('pmMSAntibiotics_%d', i),    pmMSAntibiotics);
    assignin('base', sprintf('pmMSPatientSplit_%d', i),   pmMSPatientSplit);
    assignin('base', sprintf('pmMSRawDatacube_%d', i),    pmMSRawDatacube);
    assignin('base', sprintf('pmMSInterpDatacube_%d', i), pmMSInterpDatacube);
    assignin('base', sprintf('pmMSInterpVolcube_%d', i),  pmMSInterpVolcube);
    assignin('base', sprintf('pmMSMucube_%d', i),         pmMSMucube);
    assignin('base', sprintf('pmMSMuNormcube_%d', i),     pmMSMuNormcube);
    
end








