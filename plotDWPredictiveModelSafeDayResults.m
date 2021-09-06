clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

subfolder = 'MatlabSavedVariables';

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
fprintf('Loading predictive model results data for %s\n', pcmodelresultsfile);
load(fullfile(basedir, subfolder, pcmodelresultsfile), ...
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
load(fullfile(basedir, subfolder, featureparamsmatfile), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', 'pmAMPred', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'measures', 'nmeasures', 'pmModFeatParamsRow', ...
        'pmNormFeatures', 'pmNormFeatNames');
toc
fprintf('\n');

%psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
%fprintf('Loading patient splits from file %s\n', psplitfile);
%load(fullfile(basedir, subfolder, psplitfile));
%toc
%fprintf('\n');
        
%trainlabels   = pmTrCVExABxElLabels;
%testlabels    = pmTestExABxElLabels;
%[trainfeatidx, trainfeatures, trainlabels, trainpatsplit, testfeatidx, testfeatures, testlabels, testpatsplit] = ...
%            setTrainTestArraysForRunType(pmTrCVFeatureIndex, pmTrCVNormFeatures, trainlabels, pmTrCVPatientSplit, ...
%                                         pmTestFeatureIndex, pmTestNormFeatures, testlabels, pmTestPatientSplit, ...
%                                         pmOtherRunParams.runtype);           
         

    

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
if safemethod == 1
    % use quality classifier to determine safe days
    fprintf('Running quality classifier on new data set\n');
    [safedayidx, nsafedays] = getSafeDaysFromQualClassifier(featindex, qcfeatures, pmQCModelRes.Folds(fold).Model, pmMPModelParamsRow.ModelVer{1}, qcopthres);
    daysscope = 'SafeQC';
elseif safemethod == 2
    % defined rules to determine safe days - function yet to be implemented
    daysscope = 'SafeDR';
end

% 1) run the safe day calculation for all operating thresholds, plot
% results on a graph

% 2) create Safe model res structure to store safe quality scores (likely
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

% 3) calculate P-Score/Elec-PScore only for safe interventions
[pmSafeDayRes, ampredupd] = calcPredQualityScore(pmSafeDayRes, pmAMPred, featindex(unionidx, :), patsplit);

% 4) calculate daily PR/ROC metrics only for safe days (and populate
% predsort and labelsort in modelres struct
pmSafeDayRes = calcModelQualityScores(pmSafeDayRes, labels(unionidx), nsafeorigdays);

% 5) convert to episodes
[epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNew(featindex(origidx, :), ...
                                        labels(origidx), pmModelRes.pmNDayRes(1).Pred(origidx, :), pmOtherRunParams.epilen, safedayidx);
                                    
fprintf('Safe Episodes - All: %d of %d , Stable: %d of %d, Unstable: %d of %d\n', sum(episafeidx), size(episafeidx, 1), ...
            sum(episafeidx(~logical(epilabl))), size(episafeidx(~logical(epilabl)), 1), ...
            sum(episafeidx(logical(epilabl))),  size(episafeidx(logical(epilabl)), 1));

pmSafeDayRes.RunEpi    = sum(episafeidx);
pmSafeDayRes.TotEpi    = size(episafeidx, 1);
pmSafeDayRes.PosLblEpi = sum(episafeidx(logical(epilabl)));


% 6) calculate derived episodic qs at optimal fpropthresh only for safe days
pmSafeDayRes = calcAvgEpiPred(pmSafeDayRes, epiindex, epilabl, epipred, episafeidx, featindex(unionidx, :), labels(unionidx), ...
                            pmOtherRunParams.fpropthresh);
                        
fprintf('\n');

% 7) generate regular and derived quality curves for all op thresholds
[epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, ~] = calcQualScores(epilabl(episafeidx), epipred(episafeidx));

[epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex(logical(epilabl == 1) & episafeidx, :), featindex(unionidx, :), labels(unionidx), pmSafeDayRes.Pred, epipredsort);

maxidxpt = find(epifpr < pmOtherRunParams.fpropthresh, 1, 'last');
bestidxpt = find(epitpr == epitpr(maxidxpt), 1, 'first');

[~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(epiindex(logical(epilabl == 1) & episafeidx, :), featindex(unionidx, :), labels(unionidx), pmSafeDayRes.Pred, epipredsort(bestidxpt));
untrigpmampred = pmAMPred(logical(trigintrarray == -1), :);
fprintf('\n');
fprintf('At %.1f%% FPR (pt %d), the Triggered Intervention TPR is %.1f%%, Avg Delay Reduction is %.1f days, and Avg Trigger Delay is %.1f days\n', ...
            100 * epifpr(bestidxpt), bestidxpt, trigintrtpr(bestidxpt), epiavgdelayreduction(bestidxpt), avgtrigdelay(bestidxpt));

% 7) plot regular and derived episodic qual scores


% 8) save results to excel


