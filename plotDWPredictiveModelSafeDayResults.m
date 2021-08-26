clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

basedir = setBaseDir();

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

% need to choose methodology for data completeness to determine safe 
% days and load additional input data needed
[safemethod, validresponse] = selectSafeDayMethodology();
if validresponse == 0
    return;
end
fprintf('\n');

if safemethod == 1
    % using quality classifier to determine safe days
    fprintf('Choose the trained quality classifier version to run\n');
    typetext = 'QCResults';
    [qcbasemodelresultsfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
    qcmodelresultsfile = sprintf('%s.mat', qcbasemodelresultsfile);
    qcbasemodelresultsfile = strrep(qcbasemodelresultsfile, typetext, '');
    fprintf('\n');
    % load trained quality classifier
    tic
    fprintf('Loading quality classifier results data for %s\n', qcmodelresultsfile);
    load(fullfile(basedir, subfolder, qcmodelresultsfile), ...
            'pmQCModelRes', 'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
            'pmQSConstr');
    toc
    fprintf('\n');
    if pmMPOtherRunParams.runtype ~= 2
        fprintf('Need to have qc model trained on all training data, not CV folds\n');
        return;
    end
    % choose the operating threshold for the quality classifier
    [qcopthres, validresponse] = selectFromArrayByIndex('Operating Threshold', [pmQCModelRes.PredOp; 0.6; 0.7; 0.8; 0.9; 0.95]);
    if validresponse == 0
        return;
    end
elseif safemethod == 2
    % set the various parameters for the defined rule methodology
    [mindatadays, validresponse] = selectFromArrayByIndex('Minimum number of days with measurements', (1:pmFeatureParamsRow.datawinduration)');
    if validresponse == 0
        return;
    end
    [maxdatagap, validresponse] = selectFromArrayByIndex('Maximum contiguous gap in measurements', (1:10)');
    if validresponse == 0
        return;
    end
    [recpctgap, validresponse] = selectFromArrayByIndex('Recent percentage of data window for gap check', (10:10:100)');
    if validresponse == 0
        return;
    end
else
    fprintf('Unknown safe method\n');
    return;
end                         

% load trained predictive classifier and features/labels
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', pcmodelresultsfile);
load(fullfile(basedir, subfolder, pcmodelresultsfile), ...
            'pmTestFeatureIndex', 'pmTestNormFeatures', 'pmTestExABxElLabels', 'pmTestPatientSplit', ...
            'pmTrCVFeatureIndex', 'pmTrCVNormFeatures', 'pmTrCVExABxElLabels', 'pmTrCVPatientSplit', ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

% load the predictive model inputs
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'measures', 'nmeasures', 'pmModFeatParamsRow', ...
        'pmNormFeatures', 'pmNormFeatNames');

psplitfile = sprintf('%spatientsplit.mat', pmThisFeatureParams.StudyDisplayName{fs});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');


        
trainlabels   = pmTrCVExABxElLabels;
testlabels    = pmTestExABxElLabels;
[trainfeatidx, trainfeatures, trainlabels, trainpatsplit, testfeatidx, testfeatures, testlabels, testpatsplit] = ...
            setTrainTestArraysForRunType(pmTrCVFeatureIndex, pmTrCVNormFeatures, trainlabels, pmTrCVPatientSplit, ...
                                         pmTestFeatureIndex, pmTestNormFeatures, testlabels, pmTestPatientSplit, ...
                                         pmOtherRunParams.runtype);           
        

                                     
                                     
% function to plot episodic qs                           
qcfeatures
safedayidx = getSafeDaysFromQualClassifier(pmQCModelRes, qcopthresh, 
epilen = 7;
temppmAMPred = pmAMPred;
randmode = true;
%pmAMPred = pmAMPred(~ismember(pmAMPred.IntrNbr, elecongoingtreat.IntrNbr),:);
pmAMPred = pmAMPred(~ismember(pmAMPred.ElectiveTreatment, 'Y'),:);
[epipred, epifpr, epiavgdelayreduction, trigintrtpr, avgtrigdelay, untrigpmampred, epilabl, epitpr, epipredsort, epilablsort] = plotModelQualityScoresForPaper2(testfeatidx, ...
    pmModelRes, testlabels, pmAMPred, plotsubfolder, basemodelresultsfile, epilen, randmode, pmOtherRunParams.fpropthresh);

