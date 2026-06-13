clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

basedir = setBaseDir();
dfsubfolder = 'DataFiles';
exsubfolder = 'ExcelFiles';
mlsubfolder = 'MatlabSavedVariables';
plsubfolder = 'Plots';
redval     = 1.0;
amberval   = 0.5;
greenval   = 0.0;
notsafeval = -1.0;

[predtype, ptsuffix, validresponse] = selectPredMode();
if ~validresponse
    return
end

[trigtype, ttsuffix, validresponse] = selectTriggerMode();
if ~validresponse
    return
end
if predtype == 1 % actual predictions
    if trigtype == 1
        trigthresh = 0.0220;
    elseif trigtype == 2
        trigthresh = 0.0128;
    end
    
else % 3-colour scale
    if trigtype == 1
        trigthresh = redval;
    elseif trigtype == 2
        trigthresh = amberval;
    end
end

[cohortfiltmode, cohortmatch, cohortsuffix, validresponse] = selectCohort();
if ~validresponse
    return
end

[scenmode, scenthresh, scensuffix, validresponse] = selectStudyScenario();
if ~validresponse
    return
end

[fv1name, validresponse] = selectFeatVer();
if ~validresponse
    return
end

[basefeatureparamfile, ~, ~, validresponse] = selectModelFeatureParameters(fv1name);
if ~validresponse
    return
end

featureparamfile     = strcat(basefeatureparamfile, '.xlsx');
pmThisFeatureParams  = readtable(fullfile(basedir, dfsubfolder, featureparamfile));
nfeatureparamsets = size(pmThisFeatureParams,1);

if nfeatureparamsets > 1
    fprintf('This script only works for a single feature parameter set\n');
    return
end

tic
basedir = setBaseDir();

% load predictive model inputs
fbasefilename = generateFileNameFromModFeatureParams(pmThisFeatureParams);
featureinputmatfile = sprintf('%s.mat',fbasefilename);
fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
load(fullfile(basedir, mlsubfolder, featureinputmatfile), 'pmStudyInfo', ...
    'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', 'pmFeatureIndex', ...
    'pmDataWinArray', 'pmExABxElLabels', 'pmRawMeasWinArray', 'pmNormDataWinArray', ...
    'maxdays', 'measures', 'nmeasures');

% load study signal results
signalfile = sprintf('%ssignalsrerun.mat', pmThisFeatureParams.StudyDisplayName{:});
fprintf('Loading study signal data from file %s\n', signalfile);
load(fullfile(basedir, mlsubfolder, signalfile), 'pmSignal');

% load patient data compleness data
datacompfile = sprintf('%spatientscenarios.xlsx', pmThisFeatureParams.StudyDisplayName{:});
fprintf('Loading patient data completeness scenarios from file %s\n', datacompfile);
scentable = readtable(fullfile(basedir, dfsubfolder, datacompfile));
scentable = sortrows(scentable, 'PatientID', 'ascend');

fprintf('\n');

studydisplayname = pmStudyInfo.Study{1};

% combine feature index with signal data
pmFIWithSignal = outerjoin(pmFeatureIndex, pmSignal, 'LeftKeys', {'PatientNbr', 'CalcDatedn'}, 'RightKeys', {'PatientNbr', 'RelCalcDatedn'}, 'RightVariables', {'PredScore', 'SafetyScore', 'SignalState'}, 'Type', 'left');

% set numeric equivalent of signal colour
pmFIWithSignal.Pred(:) = notsafeval;
pmFIWithSignal.Pred(ismember(pmFIWithSignal.SignalState, {'Red'}))   = redval;
pmFIWithSignal.Pred(ismember(pmFIWithSignal.SignalState, {'Amber'})) = amberval;
pmFIWithSignal.Pred(ismember(pmFIWithSignal.SignalState, {'Green'})) = greenval;

% add labels to table for ease of processing later
pmFIWithSignal.Label = pmExABxElLabels;

% write pmFeatureIndex with Signal results table to matlab archive
% file.
outputfilename = sprintf('%sRunDaysWithSignal.mat', studydisplayname);
fprintf('Saving output variables to file %s\n', outputfilename);
%save(fullfile(basedir, mlsubfolder,outputfilename), 'pmStudyInfo', ...
%'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', 'pmFeatureIndex', ...
%'pmDataWinArray', 'pmExABxElLabels', 'pmRawMeasWinArray', 'pmNormDataWinArray', 'pmFIWithSignal', ...
%'maxdays', 'measures', 'nmeasures');
save(fullfile(basedir, mlsubfolder,outputfilename), 'pmStudyInfo', ...
'pmPatients', 'pmAMPred', 'pmFIWithSignal', 'maxdays', 'measures', 'nmeasures');

% investigate any mismatches - missing signal days could be due to
% low/no data but odd that safety classifier wouldn't return a result ?
%tmpcounts = groupcounts(pmFeatureIndex, {'PatientNbr'});
%tmpcounts.Properties.VariableNames(2) = {'ActiveStudyDays'};
%tmpcounts.ActiveStudyDays = tmpcounts.ActiveStudyDays + 34; % adjust for fact we only run from 35th day

%tmpPatients = outerjoin(pmPatients, tmpcounts, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'ActiveStudyDays'}, 'Type', 'left');

%tmpnopred = groupcounts(pmFIWithSignal(isnan(pmFIWithSignal.PredScore), :), {'PatientNbr'});
%tmpnopred.Properties.VariableNames(2) = {'NoSignalDays'};

%tmpPatients = outerjoin(tmpPatients, tmpnopred, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'NoSignalDays'}, 'Type', 'left');
%tmpPatients.NoSignalDays(isnan(tmpPatients.NoSignalDays)) = 0;

%writetable(tmpPatients, fullfile(basedir, exsubfolder, 'SignalRunDayMismatches.xlsx'));


% filter data based on cohort and scenario chosen
chidx = ismember(scentable.Cohort, cohortmatch);
scencol = scentable(:, scenmode);
scencol.Properties.VariableNames{1} = 'Scen';
scenidx = ismember(scencol.Scen, {'Yes'});
combidx = chidx & scenidx;
idlist = scentable.PatientID(combidx);
[pmFIWithSignal, pmAMPred, pmPatients] = filterMQSInputData(pmFIWithSignal, pmAMPred, pmPatients, idlist);


% create model results structure and populate pred array to match patients/dates in pmFeatureIndex
%origidx = pmFeatureIndex.ScenType == 0;
%norigex = sum(origidx);
%pmDayRes = createModelDayResStuct(norigex, 1, 1);
%pmDayRes.Pred = pmFIWithSignal.PredScore;
%pmDayRes.Pred = pmFIWithSignal.Pred;
%nopredidx = ~isnan(pmFIWithSignal.Pred);
%combidx = origidx & nopredidx;
%nex = sum(combidx);

% set fixed variables
epilen = 7;
%fpropthresh = 0.30;

safedayidx = ~ismember(pmFIWithSignal.SignalState, {'White'});

if predtype == 1 % use actual predictions
    [epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNewAceCF(pmFIWithSignal, pmFIWithSignal.Label, pmFIWithSignal.PredScore, epilen, safedayidx);
    
    %[epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, ~] = calcQualScores(epilabl(episafeidx), epipred(episafeidx));
    [epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, epilabelsort] = calcQualScores(epiindex.Label(episafeidx), epipred(episafeidx));
    
    printlog = false;
    [epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex(logical(epilabl == 1) & episafeidx, :), ...
    pmFIWithSignal, pmFIWithSignal.Label, pmFIWithSignal.PredScore, epipredsort, printlog);

    % choose the best operating point - first find the max point that meets the
    % fpr threshold, then find the first point that has the same tpr as this
    % point.
    %maxidxpt = find(epifpr < fpropthresh, 1, 'last');
    %bestidxpt = find(epitpr == epitpr(maxidxpt), 1, 'first') + 1; % hardcoded to correct due to not calculating episodic numbers for every pred day
    
    % for ACE-CF, determine the best operating point based on the trigger mode
    % selected (Red only or Red + Amber)
    bestidxpt = find(epipredsort >= trigthresh, 1, 'last');

    printlog = true;
    [~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(epiindex(logical(epilabl == 1) & episafeidx, :), pmFIWithSignal, pmFIWithSignal.Label, pmFIWithSignal.PredScore, epipredsort(bestidxpt), printlog);

else % use 3-colour scale

    [epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNewAceCF(pmFIWithSignal, pmFIWithSignal.Label, pmFIWithSignal.Pred, epilen, safedayidx);
    
    %[epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, ~] = calcQualScores(epilabl(episafeidx), epipred(episafeidx));
    [epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, epilabelsort] = calcQualScores(epiindex.Label(episafeidx), epiindex.Pred(episafeidx));
    
    printlog = false;
    [epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex(logical(epilabl == 1) & episafeidx, :), ...
    pmFIWithSignal, pmFIWithSignal.Label, pmFIWithSignal.Pred, epipredsort, printlog);

    % choose the best operating point - first find the max point that meets the
    % fpr threshold, then find the first point that has the same tpr as this
    % point.
    %maxidxpt = find(epifpr < fpropthresh, 1, 'last');
    %bestidxpt = find(epitpr == epitpr(maxidxpt), 1, 'first') + 1; % hardcoded to correct due to not calculating episodic numbers for every pred day
    
    % for ACE-CF, determine the best operating point based on the trigger mode
    % selected (Red only or Red + Amber)
    bestidxpt = find(epipredsort >= trigthresh, 1, 'last');

    printlog = true;
    [~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(epiindex(logical(epilabl == 1) & episafeidx, :), pmFIWithSignal, pmFIWithSignal.Label, pmFIWithSignal.Pred, epipredsort(bestidxpt), printlog);
end

%[pmDayRes] = calcAvgEpiPred(pmDayRes, epiindex, epilabl, epipred, episafeidx, pmFIWithSignal, pmFIWithSignal.Label, fpropthresh);

nsafeintr = sum(epilabl(episafeidx)==1);
fprintf('\n');
fprintf('%d safe interventions: At %.1f%% FPR (pt %d), the Triggered Intervention TPR is %.1f%%, Avg Delay Reduction is %.1f days, and Avg Trigger Delay is %.1f days\n', ...
    nsafeintr, 100 * epifpr(bestidxpt), bestidxpt, trigintrtpr(bestidxpt), epiavgdelayreduction(bestidxpt), avgtrigdelay(bestidxpt));

% analyse triggered/untriggered interventions

episafeintrindex = epiindex(logical(epilabl == 1) & episafeidx, :);
episafeintrindex.TreatStart = episafeintrindex.Todn + 1;
episafeintrindex.IsPred = episafeintrindex.Pred;

safepmampred = innerjoin(pmAMPred, episafeintrindex, 'LeftKeys', {'PatientNbr', 'IVScaledDateNum'}, 'RightKeys', {'PatientNbr', 'TreatStart'}, 'RightVariables', {'Length', 'IsPred', 'SafeDays'});
safepmampred = innerjoin(safepmampred, pmPatients, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'Cohort', 'StudyNumber', 'StudyNumber2', 'StudyEmail', 'RelFirstMeasdn', 'RelLastMeasdn'});
safepmampred.PatientID = safepmampred.ID;
safepmampred.Description(:) = {''};
for n = 1:nsafeintr
    safepmampred.Description{n} = sprintf('%s/%d/%s/%s/%s', safepmampred.Hospital{n}, safepmampred.PatientID(n), safepmampred.StudyNumber{n}, safepmampred.StudyNumber2{n}, safepmampred.Cohort{n});
end
preperiod = 40;
postperiod = 15;
safepmampred.FromRelDn = max (1, safepmampred.Pred - preperiod);
safepmampred.ToRelDn   = min(safepmampred.RelLastMeasdn, safepmampred.IVScaledStopDateNum + postperiod);
safepmampred.Period    = safepmampred.ToRelDn - safepmampred.FromRelDn + 1;

safepmampred.ExStartDate = safepmampred.IVStartDate - days(safepmampred.IVScaledDateNum - safepmampred.Pred);

trigpmampred = safepmampred(safepmampred.IsPred == 1, :);
untrigpmampred = safepmampred(safepmampred.IsPred ~= 1, :);

signalsafepmampred  = safepmampred(ismember(safepmampred.Cohort, {'Signal'}), :);
breathesafepmampred = safepmampred(ismember(safepmampred.Cohort, {'Breathe Only'}), :);

fprintf('Average exacerbation length for Signal       (n = %d) cohort is %.2f +/- %.2f days\n', size(signalsafepmampred, 1),  mean(signalsafepmampred.Length),  0.5 * std(signalsafepmampred.Length));
fprintf('Average exacerbation length for Breathe Only (n = %d) cohort is %.2f +/- %.2f days\n', size(breathesafepmampred, 1), mean(breathesafepmampred.Length), 0.5 * std(breathesafepmampred.Length));

writetable(untrigpmampred(:, {'PatientNbr', 'Study', 'ID', 'Hospital', 'StudyNumber', 'StudyNumber2', 'StudyEmail', 'Cohort', 'IVStartDate', 'IVStopDate', 'Route', 'ExStartDate'}), fullfile(basedir, exsubfolder, 'AC-UntrigSafeExacerbations.xlsx'));
writetable(untrigpmampred(:, {'Description', 'Study', 'Hospital', 'PatientNbr', 'PatientID', 'StudyNumber', 'StudyNumber2', 'StudyEmail', 'Cohort', 'FromRelDn', 'ToRelDn', 'Period'}), fullfile(basedir, dfsubfolder, 'UXViz-AC-UntrigSafeExacerbations.xlsx'));


titlefontsize = 14;
labelfontsize = 12;
axisfontsize = 10;
unitfontsize = 10;
smallfontsize = 8;

widthinch = 8.25;
heightinch = 4.5;
name = '';
singlehght = 1/3.5;
halfhght = singlehght * 0.5;
doublehght = singlehght * 2;
twoandhalfhght = singlehght * 2.5;
triplehght = (singlehght * 3) - 0.05;
%plotwidth  = 1/2;

pllinewidth = 2.5;
axlinewidth = 1.5;

fontname    = 'Arial';

colarray = [188, 188, 229; ...
        196, 159, 132];
         
colarray = colarray ./ 255;

ntitles = 1;
%nplots = 3;
nplots = 2;
plotwidth  = 1/nplots;

%typearray = [1, 4, 5, 6];
typearray = [1, 4, 5];


%typehght = [singlehght, singlehght, triplehght, triplehght, triplehght, triplehght];
typehght = [halfhght, halfhght, triplehght, triplehght, triplehght, triplehght];


baseplotname1 = sprintf('%s-E%d%s%s%s%s', fbasefilename, epilen, scensuffix, cohortsuffix, ttsuffix, ptsuffix);

%n = 1;
%randomprec = sum(epilabl) / size(epilabl, 1);
xl = [0 100];
yl = [0 100];

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

currhght = 1.0;
currplot = 1;
for i = 1:(ntitles + nplots)
type = typearray(i);
    if type == 1 || type == 2
        % title for three plots
        currhght = currhght - typehght(type);
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [0, currhght, 1, typehght(type)]);
        displaytext1 = sprintf('Triggered Interventions (n = %d)', nsafeintr);
        annotation(sp(i), 'textbox',  ...
                        'String', displaytext1, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0, 0, plotwidth, 1], ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'LineStyle', 'none', ...
                        'FontSize', titlefontsize, ...
                        'FontWeight', 'bold');
        displaytext2 = sprintf('Early Warning (n = %d)', nsafeintr);
        annotation(sp(i), 'textbox',  ...
                        'String', displaytext2, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [plotwidth, 0, plotwidth, 1], ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'LineStyle', 'none', ...
                        'FontSize', titlefontsize, ...
                        'FontWeight', 'bold');
        %displaytext = {'Trigger Delay'};
        %annotation(sp(i), 'textbox',  ...
        %                'String', displaytext, ...
        %                'Interpreter', 'tex', ...
        %                'Units', 'normalized', ...
        %                'Position', [(2 * plotwidth), 0, plotwidth, 1], ...
        %                'HorizontalAlignment', 'center', ...
        %                'VerticalAlignment', 'middle', ...
        %                'LineStyle', 'none', ...
        %                'FontSize', titlefontsize, ...
        %                'FontWeight', 'bold'); 
    elseif type == 4
        % Triggered Interventions ROC Curve
        currhght = currhght - typehght(type);
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [0, currhght, plotwidth, typehght(type)]);
                    
        ax = subplot(1, 1, 1, 'Parent', sp(i));
        
        %area(ax, 100 * epifpr, trigintrtpr, ...
        %    'FaceColor', colarray(1,:), 'LineStyle', '-', 'LineWidth', pllinewidth);
        %line(ax, [0, 100 * epifpr(bestidxpt)], [trigintrtpr(bestidxpt), trigintrtpr(bestidxpt)], ...
        %    'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
        %line(ax, [100 * epifpr(bestidxpt), 100 * epifpr(bestidxpt)], [0, trigintrtpr(bestidxpt)], ...
        %    'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
        
        area(ax, 100 * epifpr, 100 * epitpr, ...
            'FaceColor', colarray(1,:), 'LineStyle', '-', 'LineWidth', pllinewidth);
        line(ax, [0, 100 * epifpr(bestidxpt)], [100 * epitpr(bestidxpt), 100 * epitpr(bestidxpt)], ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
        line(ax, [100 * epifpr(bestidxpt), 100 * epifpr(bestidxpt)], [0, 100 * epitpr(bestidxpt)], ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);

        hold on;
        scatter(ax, 100 * epifpr(bestidxpt), 100 * epitpr(bestidxpt), 'Marker', 'o', ...
            'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'red', 'SizeData', 24);
        hold off;
        
        ax.FontSize = axisfontsize; 
        ax.FontWeight = 'bold';
        ax.FontName   = fontname;
        ax.TickDir    = 'out';   
        ax.LineWidth  = axlinewidth;
        ax.XTick  = [0, 50, 100];
        ax.YTick  = [0, 50, 100];
        xlim(ax, xl);
        ylim(ax, yl);
        
        xlabel(ax, 'Episodic False Positive Rate (%)');
        ylabel(ax, 'Episodic True Positive Rate (%)');
        
        auc = trapz(epifpr, trigintrtpr);
        roctext = sprintf('AUC  = %4.1f%%\nETPR = %4.1f%%\nEFPR = %4.1f%%', auc, 100 * epitpr(bestidxpt), 100 * epifpr(bestidxpt));
        annotation(sp(i), 'textbox',  ...
                        'String', roctext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0.5, 0.2 0.38, 0.3], ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment', 'middle', ...
                        'BackgroundColor', colarray(1,:), ...
                        'LineStyle', 'none', ...
                        'FontWeight', 'bold', ...
                        'FontSize', axisfontsize);
    elseif type == 5
        % Reduction in treatment delay plot
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [plotwidth, currhght, plotwidth, typehght(type)]);
                    
        ax = subplot(1, 1, 1, 'Parent', sp(i));
        
        area(ax, 100 * epifpr, epiavgdelayreduction, ...
            'FaceColor', colarray(2,:), 'LineStyle', '-', 'LineWidth', pllinewidth);
        line(ax, [0, 100 * epifpr(bestidxpt)], [epiavgdelayreduction(bestidxpt), epiavgdelayreduction(bestidxpt)], ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
        line(ax, [100 * epifpr(bestidxpt), 100 * epifpr(bestidxpt)], [0, epiavgdelayreduction(bestidxpt)], ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
        hold on;
        
        scatter(ax, 100 * epifpr(bestidxpt), epiavgdelayreduction(bestidxpt), 'Marker', 'o', ...
            'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'red', 'SizeData', 24);
        
        ax.TickDir = 'out';
        ax.FontSize = axisfontsize; 
        ax.FontWeight = 'bold';
        ax.FontName   = fontname;
        ax.TickDir    = 'out';   
        ax.LineWidth  = axlinewidth;
        ax.XTick  = [0, 50, 100];
        ax.YTick  = [0, 6, 12, 18];
        xlim(ax, xl);
        %ylim(ax, yl);
        
        xlabel(ax, 'Episodic False Positive Rate (%)');
        ylabel(ax, 'Early Warning (days)');
        
        earlywarntext = sprintf('Early Warning = %3.1f days\nEFPR = %4.1f%%', epiavgdelayreduction(bestidxpt), 100 * epifpr(bestidxpt));
        annotation(sp(i), 'textbox',  ...
                        'String', earlywarntext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0.4, 0.25 0.38, 0.2], ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment', 'middle', ...
                        'BackgroundColor', colarray(2,:), ...
                        'LineStyle', 'none', ...
                        'FontWeight', 'bold', ...
                        'FontSize', axisfontsize);
    elseif type == 6
        % Percent of max time saved
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [(2 * plotwidth), currhght, plotwidth, typehght(type)]);
                    
        ax = subplot(1, 1, 1, 'Parent', sp(i));
        
        area(ax, 100 * epifpr, avgtrigdelay, ...
            'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);
        line(ax, [0, 100 * epifpr(bestidxpt)], [avgtrigdelay(bestidxpt), avgtrigdelay(bestidxpt)], ...
            'Color', 'g', 'LineStyle', '-', 'LineWidth', 1.0);
        line(ax, [100 * epifpr(bestidxpt), 100 * epifpr(bestidxpt)], [0, avgtrigdelay(bestidxpt)], ...
            'Color', 'g', 'LineStyle', '-', 'LineWidth', 1.0);
        hold on;
        
        scatter(ax, 100 * epifpr(bestidxpt), avgtrigdelay(bestidxpt), 'Marker', 'o', ...
            'MarkerFaceColor', 'green', 'MarkerEdgeColor', 'green', 'SizeData', 18);
        
        ax.FontSize = axisfontsize; 
        ax.TickDir = 'out';      
        xlim(ax, xl);
        %ylim(ax, yl);
        
        xlabel(ax, 'False Positive Rate (%)');
        ylabel(ax, 'Delay (days)');
        
        %annotation(sp(i), 'doublearrow',[epifpr(chosenpt), currclindelay ],[epifpr(chosenpt) epiavgdelayreduction(chosenpt)], 'Color', 'red' )
        %line(ax, [0, 1], [currclindelay, currclindelay], ...
        %    'Color', 'g', 'LineStyle', '-', 'LineWidth', 1.0);
        %arrow([epifpr(chosenpt), currclindelay], [epifpr(chosenpt) epiavgdelayreduction(chosenpt)-0.2], ...
        %    'Length', 5, 'Ends', 'both', 'FaceColor', 'w', 'LineWidth', 1.0, 'EdgeColor', 'w');
        
        %delayredtext = {sprintf('Alert %.1f days earlier with', epiavgdelayreduction(chosenpt) - currclindelay); ...
        %                sprintf('false positive rate of %.0f%%', epifpr(chosenpt) * 100)};
        %annotation(sp(i), 'textbox',  ...
        %                'String', delayredtext, ...
        %                'Interpreter', 'tex', ...
        %                'Units', 'normalized', ...
        %                'Position', [0.31, 0.35, 0.52, 0.2], ...
        %                'HorizontalAlignment', 'left', ...
        %                'VerticalAlignment', 'middle', ...
        %                'BackgroundColor', 'white', ...
        %                'LineStyle', '-', ...
        %                'FontSize', smallfontsize);
       
    end
end
    
basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plsubfolder);
savePlotInDirAsSVG(f, baseplotname1, plsubfolder);
close(f);


%epiindex(episafeidx & epilabl & ismember(epiindex.PatientNbr, pmPatients.PatientNbr(ismember(pmPatients.Cohort, {'Breathe Only'}))),:);
%groupcounts(epiindex(episafeidx & epilabl & ismember(epiindex.PatientNbr, pmPatients.PatientNbr(ismember(pmPatients.Cohort, {'Signal'}))),:), {'SignalState'});
%disp(epiindex(episafeidx & ~epilabl & ismember(epiindex.PatientNbr, pmPatients.PatientNbr(ismember(pmPatients.Cohort, {'Breathe Only'}))) & ismember(epiindex.SignalState, {'Red'}), :))

% create UX Input file for high red ration patients.

tempred = groupcounts(pmFIWithSignal(ismember(pmFIWithSignal.SignalState, {'Red'}), :), {'PatientNbr'});
tempred.RedCount = tempred.GroupCount;

tempsafe = groupcounts(pmFIWithSignal(~ismember(pmFIWithSignal.SignalState, {'White'}), :), {'PatientNbr'});
tempsafe.SafeCount = tempsafe.GroupCount;

temppat = innerjoin(pmPatients, tempsafe, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'SafeCount'});
temppat = innerjoin(temppat, tempred, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'RedCount'});
temppat(isnan(temppat.SafeCount) , :) = [];

temppat.RedPct = 100 * temppat.RedCount ./ temppat.SafeCount;

temppat.PatientID = temppat.ID;
temppat.Description(:) = {''};
for n = 1:size(temppat, 1)
    temppat.Description{n} = sprintf('%s/%d/%s/%s/%s', temppat.Hospital{n}, temppat.PatientID(n), temppat.StudyNumber{n}, temppat.StudyNumber2{n}, temppat.Cohort{n});
end
temppat.FromRelDn = temppat.RelFirstMeasdn;
temppat.ToRelDn   = temppat.RelLastMeasdn;
temppat.Period    = temppat.ToRelDn - temppat.FromRelDn + 1;

writetable(temppat(temppat.RedPct > 20, {'Description', 'Study', 'Hospital', 'PatientNbr', 'PatientID', 'StudyNumber', 'StudyNumber2', 'StudyEmail', 'Cohort', 'FromRelDn', 'ToRelDn', 'Period'}), fullfile(basedir, dfsubfolder, 'UXViz-AC-HighRedPats.xlsx'));
