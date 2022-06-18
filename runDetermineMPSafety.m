clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

mlsubfolder = 'MatlabSavedVariables';
dfsubfolder = 'DataFiles';

% select which models to run the safety check for
[mpmodmode, runqc, runpc, validresponse] = selectMPModMode();
if validresponse == 0
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

% need the qual classifier in both modes - for pc mode, need baseline
% scores
typetext = 'QCResults';
[baseqcresfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcresfile = sprintf('%s.mat', baseqcresfile);
baseqcresfile = strrep(baseqcresfile, typetext, '');

if runqc
    % load trained quality classifier
    tic
    fprintf('Loading quality classifier results data for %s\n', qcresfile);
    load(fullfile(basedir, mlsubfolder, qcresfile), ...
            'pmQCModelRes', 'pmQCFeatNames', ...
            'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
            'pmFeatureParamsRow', ...
            'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
            'measures', 'nmeasures', 'pmQSConstr');
    toc
    fprintf('\n');

    % choose the operating threshold for the quality classifier
    [qcopthres, validresponse] = selectFromArrayByIndex('Operating Threshold', [pmQCModelRes.PredOp; 0.6; 0.7; 0.8; 0.9; 0.95]);
    if validresponse == 0
        return;
    end
end

if runpc
    fprintf('Select Inner (Predictive) Classifier model results file\n');
    [basepcresfile] = selectModelResultsFile(fv1, lb1, rm1);
    pcresfile = sprintf('%s.mat', basepcresfile);
    
    tic
    fprintf('Loading trained Inner (Predictive) classifier and run parameters for %s\n', pcresfile);
    load(fullfile(basedir, mlsubfolder, pcresfile), ...
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
    load(fullfile(basedir, mlsubfolder, featureparamsfile), 'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
    toc
    fprintf('\n');
    
    npcexamples = size(pmFeatureIndex, 1);
    qcopthres = 0;

    tic
    psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
    fprintf('Loading patient splits from file %s\n', psplitfile);
    load(fullfile(basedir, mlsubfolder, psplitfile));
    toc
    fprintf('\n');
    
    % load baseline info (if not already loaded above)
    if ~runqc
        tic
        fprintf('Loading quality classifier results data for %s\n', qcresfile);
        load(fullfile(basedir, mlsubfolder, qcresfile), ...
                'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
                'pmQSConstr');
        toc
        fprintf('\n');
    end
    
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
    
end

if nqcfolds ~= 1
        fprintf('Need to choose an Outer (Quality) classifier model with only one fold\n');
        return
end

% populate run parameters
dwdur = pmFeatureParamsRow.datawinduration;
normwin = pmFeatureParamsRow.normwinduration;
totalwin = dwdur + normwin;


mindatarule = 2; % this script applies the 1D missingness pattern to all measures equally
nrawmeas     = sum(measures.RawMeas);
mpmeasures = measures(logical(measures.RawMeas), :);
mpmeasures.Index(:) = 1:nrawmeas;


% backward compatibility issue since I changed the quality classifier
% to handle more than one QS constraint - it's hard to easily fit multiple
% qs scores into the single SelPred column for the pmQCDRIndex table - so
% for now just use AvgEPV constraint as this is 99.9% the same as both
% constraints.
pmQSConstr = pmQSConstr(ismember(pmQSConstr.qsmeasure, {'AvgEPV'}), :);

[basempfile, validresponse] = select1DMPExcelFile();
if validresponse == 0
    return;
end
mpfile = strcat(basempfile, '.xlsx');

if runqc
    [mpqcIndex]    = createQCDRTables(0);
    mpqcMissPatt   = [];
    mpqcDataWin    = [];
    mpqcFeatures   = [];
    mpqcCyclicPred = [];
end

if runpc
    [mppcIndex]    = createQCDRTables(0);
    mppcMissPatt   = [];
    mppcDataWin    = [];
    mppcFeatures   = [];
    mppcCyclicPred = [];
end


mptable  = readtable(fullfile(basedir, dfsubfolder, mpfile));
nmps = size(mptable,1);

for mp = 1:nmps

    mptablerow = mptable(mp, :);
    
    %for m = 1:nrawmeas
    %    [mpindexrow, mp3D, mpdur, iscyclic, cyclicdur] = setMPOneMeasFromExcel(mptablerow, mpmeasures, m, nrawmeas, dwdur);
    %    printMissPattFcn(mpindexrow, mp3D, mpmeasures, nrawmeas, mpdur);
    %    
    %    if runqc
    %        [mpqcIndex, mpqcMissPatt, mpqcDataWin, mpqcFeatures, mpqcCyclicPred] = ...
    %            calcCyclicPredsForMP(pmQCModelRes, pmMPModelParamsRow.ModelVer, ...
    %                    mpqcIndex, mpqcMissPatt, mpqcDataWin, mpqcFeatures, mpqcCyclicPred, ...
    %                    mpindexrow, mp3D, mpdur, dwdur, nrawmeas, cyclicdur, iscyclic, qcopthres);
    %    end
    %
    %    if runpc
    %          [mppcIndex, mppcMissPatt, mppcDataWin, mppcFeatures, mppcCyclicPred] = ...
    %            calcPCCyclicPredsForMP(pmModelByFold, pmFeatureIndex, pmDataWinArray, pmExABxElLabels, ...
    %                pmAMPred, pmPatientSplit, nsplits, pmOverallStats, ...
    %                measures, nmeasures, nrawmeas, npcexamples, pcfolds, pmBaselineQS, ...
    %                mppcIndex, mppcMissPatt, mppcDataWin, mppcFeatures, mppcCyclicPred, ...
    %                mpindexrow, mp3D, mpdur, dwdur, totalwin, cyclicdur, iscyclic, pmQSConstr, ...
    %                pmFeatureParamsRow, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, pmModFeatParamsRow);
    %    end
    %end 
    
    [mpindexrow, mp3D, mpdur, iscyclic, cyclicdur] = setMPAllMeasFromExcel(mptablerow, nrawmeas, dwdur);
    printMissPattFcn(mpindexrow, mp3D, mpmeasures, nrawmeas, mpdur);
    
    if runqc
        [mpqcIndex, mpqcMissPatt, mpqcDataWin, mpqcFeatures, mpqcCyclicPred] = ...
            calcCyclicPredsForMP(pmQCModelRes, pmMPModelParamsRow.ModelVer, ...
                    mpqcIndex, mpqcMissPatt, mpqcDataWin, mpqcFeatures, mpqcCyclicPred, ...
                    mpindexrow, mp3D, mpdur, dwdur, nrawmeas, cyclicdur, iscyclic, qcopthres);
    end
    
    if runpc
          [mppcIndex, mppcMissPatt, mppcDataWin, mppcFeatures, mppcCyclicPred] = ...
            calcPCCyclicPredsForMP(pmModelByFold, pmFeatureIndex, pmDataWinArray, pmExABxElLabels, ...
                pmAMPred, pmPatientSplit, nsplits, pmOverallStats, ...
                measures, nmeasures, nrawmeas, npcexamples, pcfolds, pmBaselineQS, ...
                mppcIndex, mppcMissPatt, mppcDataWin, mppcFeatures, mppcCyclicPred, ...
                mpindexrow, mp3D, mpdur, dwdur, totalwin, cyclicdur, iscyclic, pmQSConstr, ...
                pmFeatureParamsRow, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, pmModFeatParamsRow);
    end
    
end



% save results to excel
tic
basedir = setBaseDir();
exsubfolder = 'ExcelFiles';
outputfilename = sprintf('%s%srm%dMPSafety.xlsx', basempfile, baseqcresfile, mpmodmode);
fprintf('Saving model output variables to file %s\n', outputfilename);
if runqc
    mpqcIndex.Properties.VariableNames({'MoveDesc'}) = {'Pattern'};
    mpqcIndex.Properties.VariableNames({'MoveAccepted'}) = {'Safe'};
    writetable(mpqcIndex(:, {'Pattern', 'ShortName', 'SelPred', 'Safe'}), fullfile(basedir, exsubfolder, outputfilename), 'Sheet', sprintf('QCot%.2f', qcopthres));
end
if runpc
    mppcIndex.Properties.VariableNames({'MoveDesc'}) = {'Pattern'};
    mppcIndex.Properties.VariableNames({'MoveAccepted'}) = {'Safe'}; 
    writetable(mppcIndex(:, {'Pattern', 'ShortName', 'SelPred', 'Safe'}), fullfile(basedir, exsubfolder, outputfilename), 'Sheet', sprintf('PC%.2f', pmQSConstr.fpthresh(1)));
end
toc
fprintf('\n');








