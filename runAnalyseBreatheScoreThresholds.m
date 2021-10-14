% test the numbers of days that will be undefined/green/amber/red for
% different percentage thresholds (+/- bands from the operating threshold)

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

% create results table

                                     
                                     
% replace with array of values for each and loop over permutations and
% populate a table with the results.
[amberlowpct, validresponse] = selectThreshPercentage('Lower band for amber (relative to op thresh)', 0, 50);
if validresponse == 0
    return;
end
[amberhighpct, validresponse] = selectThreshPercentage('Higher bandfor amber (relative to op thresh)', 0, 100);
if validresponse == 0
    return;
end

fidx      = (testfeatidx.ScenType == 0 );
featindex = testfeatidx(fidx,:);
preds      = pmModelRes.pmNDayRes(1).Pred(fidx);
labels     = testlabels(fidx);

pcopthres = pmModelRes.pmNDayRes(1).EpiPredOp;

nex = sum(fidx);

bintrue = sum(preds >= pcopthres);
bintruepct = 100 * bintrue / nex;

stabdays = sum(preds < (pcopthres * (1 - (amberlowpct / 100))));
stabpct  = 100 * stabdays / nex;

preds < pcopthres;
    psclpreddata(ppreddata >= (pmModelRes.pmNDayRes(1).EpiPredOp * amberlowpct)   & ppreddata < (pmModelRes.pmNDayRes(1).EpiPredOp * amberhighpct)) = amberval;
    psclpreddata(ppreddata >= (pmModelRes.pmNDayRes(1).EpiPredOp * amberhighpct))                                                                   = unstableval;


