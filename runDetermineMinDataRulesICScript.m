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

fprintf('Select Outer (Quality) Classifier model results file\n');
typetext = 'QCResults';
[baseqcresfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcresfile = sprintf('%s.mat', baseqcresfile);
baseqcresfile = strrep(baseqcresfile, typetext, '');

fprintf('Select Inner (Predictive) Classifier model results file\n');
[basepcresfile] = selectModelResultsFile(fv1, lb1, rm1);
pcresfile = sprintf('%s.mat', basepcresfile);

% load trained quality classifier
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading quality classifier results data for %s\n', qcresfile);
load(fullfile(basedir, subfolder, qcresfile), ...
        'pmMissPattArray', 'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
        'pmQSConstr');
%        'qsmeasure', 'qsthreshold', 'fpthreshold');
toc
fprintf('\n');

% backward compatibility issue since I changed the quality classifier
% to handle more than one QS constraint - it's hard to easily fit multiple
% qs scores into the single SelPred column for the pmQCDRIndex table - so
% for now just use AvgEPV constraint as this is 99.9% the same as both
% constraints.
pmQSConstr = pmQSConstr(ismember(pmQSConstr.qsmeasure, {'AvgEPV'}), :);

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading trained Inner (Predictive) classifier and run parameters for %s\n', pcresfile);
load(fullfile(basedir, subfolder, pcresfile), ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');

pmModelByFold = pmModelRes.pmNDayRes.Folds;
clear('pmModelRes');

% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
if pmFeatureParamsRow.augmethod > 1
    findaugtext = sprintf('au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('au1');
    featureparamsfile = strrep(featureparamsfile, findaugtext, replaceaugtext);
end
featureparamsfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading Inner (Predictive) model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsfile), 'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

tic
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

if nqcfolds ~= 1
    fprintf('Need to choose an Outer (Quality) classifier model with only one fold\n');
    return
end

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

% populate run parameters
dwdur     = pmFeatureParamsRow.datawinduration;
normwin = pmFeatureParamsRow.normwinduration;
totalwin = dwdur + normwin;
npcexamples = size(pmFeatureIndex, 1);

% choose min data rule type
[mindatarule, validresponse] = selectMinDataRuleType();
if validresponse == 0
    return;
end

% choose missingness pattern duration
[mpdur, validresponse] = selectMissPatDuration();
if validresponse == 0
    return;
end

% 0 = no missingness start, otherwise TP chosen at random
mpstartex = 0;
%mpstartex = 27366; % Linear Model, Pred Op Thresh
%mpstartex = 40000; % Linear Model, 0.95 Thresh
%mpstartex = 28536; % Non-Linear Model, 0.95 Thresh

if mpdur < dwdur
    iscyclic  = 'Y';
    cyclicdur = mpdur;
else
    iscyclic  = 'N';
    cyclicdur = 1;
end
nrawmeas     = sum(measures.RawMeas);
qcdrmeasures = measures(logical(measures.RawMeas), :);
qcdrmeasures.Index(:) = 1:nrawmeas;

[pmQCDRIndex]    = createQCDRTables(0);
pmQCDRMissPatt   = [];
pmQCDRDataWin    = [];
pmQCDRFeatures   = [];
pmQCDRCyclicPred = [];

iteration = 0;
somegoodmoves = true;

while somegoodmoves
    
    if iteration == 0
        if mpstartex == 0
            fprintf('Iteration %d: Setting up initial pattern with no missingness\n', iteration);
        else
            fprintf('Iteration %d: Setting up initial pattern from example %d (TP)\n', iteration, mpstartex);
        end
        % nb only works for mpstartex == 0 at the moment - otherwise need
        % to load in QC Model and results
        [mvsetindex, mvsetmp3D] = setInitialMP(mpstartex, [], nrawmeas, mpdur, dwdur, iteration);
        printMissPattFcn(mvsetindex, mvsetmp3D, qcdrmeasures, nrawmeas, mpdur);
    else
        [mvsetindex, mvsetmp3D] = createAllMovesSet(currmp3D, qcdrmeasures, nrawmeas, mpdur, iteration, mindatarule);
        fprintf('Iteration %d: Added %d possible moves\n', iteration, size(mvsetindex, 1));
    end
    
    for i = 1:size(mvsetindex, 1)
 
        fprintf('Move %d of %d: %d %s | Measure %d (%s) | Index %d\n', i, size(mvsetindex, 1), mvsetindex.MoveType(i), ...
             mvsetindex.MoveDesc{i}, mvsetindex.Measure(i), mvsetindex.ShortName{i}, mvsetindex.MPRelIndex(i));
        
        [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
            calcPCCyclicPredsForMP(pmModelByFold, pmFeatureIndex, pmDataWinArray, pmExABxElLabels, ...
                pmAMPred, pmPatientSplit, nsplits, pmOverallStats, ...
                measures, nmeasures, nrawmeas, npcexamples, pcfolds, pmBaselineQS, ...
                pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
                mvsetindex(i, :), mvsetmp3D(i, :, :), mpdur, dwdur, totalwin, cyclicdur, iscyclic, pmQSConstr, ...
                pmFeatureParamsRow, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, pmModFeatParamsRow);
    end
    fprintf('\n');
    
    % choose best move (out of the moves for this iteration that were accepted)
    % and set that as row with move type 0 for next iteration
    if iteration == 0
        maxiterpred = max(pmQCDRIndex.SelPred(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.MoveType == 0 & pmQCDRIndex.MoveAccepted));
        fprintf('%d of %d acceptable moves - ', sum(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.MoveType == 0 & pmQCDRIndex.MoveAccepted), size(mvsetindex, 1));
    else
        maxiterpred = max(pmQCDRIndex.SelPred(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.MoveType ~= 0 & pmQCDRIndex.MoveAccepted));
        fprintf('%d of %d acceptable moves - ', sum(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.MoveType ~= 0 & pmQCDRIndex.MoveAccepted), size(mvsetindex, 1));
    end
    
    if size(maxiterpred, 1) == 0
        % no acceptable moves from this iteration, so revert back to
        % baseline for this iteration (ie best result from last iteration)
        somegoodmoves = false;
        idx = find(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.MoveType == 0, 1, 'last');
        fprintf('finished\n');
        
    else
        % add best move from this iteration as the baseline for the next
        % iteration
        %idx = find(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.SelPred == maxiterpred, 1, 'last'); % need to add logic if more than one matches
        idx = find(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.SelPred == maxiterpred, 1, 'first'); % need to add logic if more than one matches
        
        iteration                = iteration + 1;
        currindexrow             = pmQCDRIndex(idx, :);
        currindexrow.Iteration   = iteration;
        currindexrow.MoveType    = 0;
        currindexrow.MoveDesc{1} = setMoveDescForType(currindexrow.MoveType);

        currmp3D     = pmQCDRMissPatt(idx, :, :);

        [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
            addQCDRRows(pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
                currindexrow, currmp3D, pmQCDRDataWin(idx, :, :), pmQCDRFeatures(idx, :), pmQCDRCyclicPred(idx, :));
        
        fprintf('best move: %d %s | Measure %d (%s) | Index %d | Pred %.4f\n', pmQCDRIndex.MoveType(idx), ...
            pmQCDRIndex.MoveDesc{idx}, pmQCDRIndex.Measure(idx), pmQCDRIndex.ShortName{idx}, ...
            pmQCDRIndex.MPRelIndex(idx), pmQCDRIndex.SelPred(idx));
    end

    fprintf('\n');
end

printMissPattFcn(pmQCDRIndex(idx, :), pmQCDRMissPatt(idx, :, :), qcdrmeasures, nrawmeas, mpdur);

pmQCDRIndex(pmQCDRIndex.MoveType == 0, {'Iteration', 'MoveType', 'MoveDesc', 'Measure', 'ShortName', 'MPRelIndex', 'SelPred', 'MoveAccepted'})


tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%smd%dex%dot%.2fdr%dQCDRResultsICNew.mat', baseqcresfile, mpdur, mpstartex, pmQSConstr.fpthresh(1), mindatarule);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', 'mindatarule',...
    'pmQSConstr', ...
    'pmMissPattArray', 'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmModelByFold', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams', ...
    'normwin', 'totalwin', 'npcexamples', ...
    'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'pmPatientSplit', 'nsplits', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');



