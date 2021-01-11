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
typetext = 'QCResults';
[basemodelresultsfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, typetext, '');

% load trained quality classifier
tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading quality classifier results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
        'pmQCModelRes', 'pmQCFeatNames', ...
        'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
        'labels', 'qcsplitidx', 'nexamples', ...
        'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
        'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
        'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'measures', 'nmeasures', 'qsmeasure', 'qsthreshold', 'fpthreshold');

toc
fprintf('\n');

tpidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), pmQCModelRes.PredOp, fpthreshold / 100, 'TP');

% rng(2);
% test = find(tpidx);
% test(randperm(size(test,1), 10));

% populate run parameters
dwdur     = pmFeatureParamsRow.datawinduration;
mpdur     = 7; % add this as a selection choice
mpstartex = 27366; % 0 = no missingness start, otherwise TP chosen at random
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
        [mvsetindex, mvsetmp3D] = setInitialMP(mpstartex, pmMissPattArray, nrawmeas, mpdur, dwdur, iteration);
    else
        [mvsetindex, mvsetmp3D] = createAllMovesSet(currmp3D, nrawmeas, mpdur, iteration);
        fprintf('Iteration %d: Added %d possible moves\n', iteration, size(mvsetindex, 1));
    end
    
    for i = 1:size(mvsetindex, 1)
        fprintf('.');
        [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
            calcCyclicPredsForMP(pmQCModelRes, pmMPModelParamsRow.ModelVer, ...
                    pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
                    mvsetindex(i, :), mvsetmp3D(i, :, :), mpdur, dwdur, nrawmeas, cyclicdur, iscyclic);
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
        idx = find(pmQCDRIndex.Iteration == iteration & pmQCDRIndex.SelPred == maxiterpred, 1, 'last'); % need to add logic if more than one matches
        
        iteration                = iteration + 1;
        currindexrow             = pmQCDRIndex(idx, :);
        currindexrow.Iteration   = iteration;
        currindexrow.MoveType    = 0;
        currindexrow.MoveDesc{1} = setMoveDescForType(currindexrow.MoveType);

        currmp3D     = pmQCDRMissPatt(idx, :, :);

        [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
            addQCDRRows(pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
                currindexrow, currmp3D, pmQCDRDataWin(idx, :, :), pmQCDRFeatures(idx, :), pmQCDRCyclicPred(idx, :));
            
        fprintf('best move: %d %s | Measure %d | Index %d | Pred %.4f\n', pmQCDRIndex.MoveType(idx, :), ...
            pmQCDRIndex.MoveDesc{idx, :}, pmQCDRIndex.Measure(idx, :), pmQCDRIndex.MPIndex(idx, :), pmQCDRIndex.SelPred(idx, :));
    end

    fprintf('\n');
end

