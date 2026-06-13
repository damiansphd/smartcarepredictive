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
else
    tic
    basedir = setBaseDir();
    
    % load predictive model inputs
    fbasefilename = generateFileNameFromModFeatureParams(pmThisFeatureParams);
    featureinputmatfile = sprintf('%s.mat',fbasefilename);
    fprintf('Loading predictive model input data from file %s\n', featureinputmatfile);
    load(fullfile(basedir, mlsubfolder, featureinputmatfile));

    % load study signal results
    signalfile = sprintf('%ssignalsrerun.mat', pmThisFeatureParams.StudyDisplayName{:});
    fprintf('Loading study signal data from file %s\n', signalfile);
    load(fullfile(basedir, mlsubfolder, signalfile));

    % load patient split file, but then override to put all in the same
    % fold as we are just running for the whole data-set
    psplitfile = sprintf('%spatientsplit.mat', pmThisFeatureParams.StudyDisplayName{:});
    fprintf('Loading patient splits from file %s\n', psplitfile);
    load(fullfile(basedir, mlsubfolder, psplitfile));
    pmPatientSplit.SplitNbr(:) = 1;
    fprintf('\n');

    % combine feature index with signal data
    pmFIWithSignal = outerjoin(pmFeatureIndex, pmSignal, 'LeftKeys', {'PatientNbr', 'CalcDatedn'}, 'RightKeys', {'PatientNbr', 'RelCalcDatedn'}, 'RightVariables', {'PredScore', 'SafetyScore', 'SignalState'}, 'Type', 'left');

    % write pmFeatureIndex with Signal results table to matlab archive
    % file.
    outputfilename = sprintf('%sRunDaysWithSignal.mat', studydisplayname);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, mlsubfolder,outputfilename), 'pmStudyInfo', ...
    'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', 'pmFeatureIndex', ...
    'pmDataWinArray', 'pmExABxElLabels', 'pmRawMeasWinArray', 'pmNormDataWinArray', 'pmFIWithSignal', ...
    'maxdays', 'measures', 'nmeasures');

    % investigate any mismatches - missing signal days could be due to
    % low/no data but odd that safety classifier wouldn't return a result ?
    tmpcounts = groupcounts(pmFeatureIndex, {'PatientNbr'});
    tmpcounts.Properties.VariableNames(2) = {'ActiveStudyDays'};
    tmpcounts.ActiveStudyDays = tmpcounts.ActiveStudyDays + 34; % adjust for fact we only run from 35th day
    
    tmpPatients = outerjoin(pmPatients, tmpcounts, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'ActiveStudyDays'}, 'Type', 'left');
    
    tmpnopred = groupcounts(pmFIWithSignal(isnan(pmFIWithSignal.PredScore), :), {'PatientNbr'});
    tmpnopred.Properties.VariableNames(2) = {'NoSignalDays'};
    
    tmpPatients = outerjoin(tmpPatients, tmpnopred, 'LeftKeys', {'PatientNbr'}, 'RightKeys', {'PatientNbr'}, 'RightVariables', {'NoSignalDays'}, 'Type', 'left');
    tmpPatients.NoSignalDays(isnan(tmpPatients.NoSignalDays)) = 0;

    writetable(tmpPatients, fullfile(basedir, exsubfolder, 'SignalRunDayMismatches.xlsx'));

    % create model results structure and populate pred array to match patients/dates in pmFeatureIndex
    origidx = pmFeatureIndex.ScenType == 0;
    norigex = sum(origidx);
    pmDayRes = createModelDayResStuct(norigex, 1, 1);
    pmDayRes.Pred = pmFIWithSignal.PredScore;
    nopredidx = ~isnan(pmDayRes.Pred);
    combidx = origidx & nopredidx;
    nex = sum(combidx);
    

    % set fixed variables
    epilen = 7;
    fpropthresh = 0.375;

    safedayidx = ~ismember(pmFIWithSignal.SignalState, {'White'});

    [epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNew(pmFeatureIndex, pmExABxElLabels, pmDayRes.Pred, epilen, safedayidx);
    [epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, ~] = calcQualScores(epilabl(episafeidx), epipred(episafeidx));

    printlog = false;
    [epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex(logical(epilabl == 1) & episafeidx, :), ...
        pmFeatureIndex, pmExABxElLabels, pmDayRes.Pred, epipredsort, printlog);

    % choose the best operating point - first find the max point that meets the
    % fpr threshold, then find the first point that has the same tpr as this
    % point.
    maxidxpt = find(epifpr < fpropthresh, 1, 'last');
    bestidxpt = find(epitpr == epitpr(maxidxpt), 1, 'first') + 1; % hardcoded to correct due to not calculating episodic numbers for every pred day

    printlog = true;
    [~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(epiindex(logical(epilabl == 1) & episafeidx, :), pmFeatureIndex, pmExABxElLabels, pmDayRes.Pred, epipredsort(bestidxpt), printlog);

    [pmDayRes] = calcAvgEpiPred(pmDayRes, epiindex, epilabl, epipred, episafeidx, pmFeatureIndex, pmExABxElLabels, fpropthresh);

    episafeintrindex = epiindex(logical(epilabl == 1) & episafeidx, :);
    untrigepi = episafeintrindex(logical(trigintrarray == -1), :);
    untrigepi.TreatStart = untrigepi.Todn + 1;
    untrigpmampred = innerjoin(pmAMPred, untrigepi, 'LeftKeys', {'PatientNbr', 'IVScaledDateNum'}, 'RightKeys', {'PatientNbr', 'TreatStart'}, 'RightVariables', {});

    fprintf('\n');
    fprintf('At %.1f%% FPR (pt %d), the Triggered Intervention TPR is %.1f%%, Avg Delay Reduction is %.1f days, and Avg Trigger Delay is %.1f days\n', ...
            100 * epifpr(bestidxpt), bestidxpt, trigintrtpr(bestidxpt), epiavgdelayreduction(bestidxpt), avgtrigdelay(bestidxpt));

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
    plotwidth  = 1/2;
    
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
    
    
    baseplotname1 = sprintf('%s-E%dQSfP%.3f', fbasefilename, epilen, fpropthresh);
    
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
            displaytext = 'Triggered Interventions';
            annotation(sp(i), 'textbox',  ...
                            'String', displaytext, ...
                            'Interpreter', 'tex', ...
                            'Units', 'normalized', ...
                            'Position', [0, 0, plotwidth, 1], ...
                            'HorizontalAlignment', 'center', ...
                            'VerticalAlignment', 'middle', ...
                            'LineStyle', 'none', ...
                            'FontSize', titlefontsize, ...
                            'FontWeight', 'bold');
            displaytext = {'Early Warning'};
            annotation(sp(i), 'textbox',  ...
                            'String', displaytext, ...
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
            
            area(ax, 100 * epifpr, trigintrtpr, ...
                'FaceColor', colarray(1,:), 'LineStyle', '-', 'LineWidth', pllinewidth);
            line(ax, [0, 100 * epifpr(bestidxpt)], [trigintrtpr(bestidxpt), trigintrtpr(bestidxpt)], ...
                'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
            line(ax, [100 * epifpr(bestidxpt), 100 * epifpr(bestidxpt)], [0, trigintrtpr(bestidxpt)], ...
                'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);
            
            hold on;
            scatter(ax, 100 * epifpr(bestidxpt), trigintrtpr(bestidxpt), 'Marker', 'o', ...
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
            roctext = sprintf('AUC = %.1f%%', auc);
            annotation(sp(i), 'textbox',  ...
                            'String', roctext, ...
                            'Interpreter', 'tex', ...
                            'Units', 'normalized', ...
                            'Position', [0.5, 0.3 0.38, 0.1], ...
                            'HorizontalAlignment', 'center', ...
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

end

