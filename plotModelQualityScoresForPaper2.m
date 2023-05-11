function [epipred, epifpr, epiavgdelayreduction, trigintrtpr, avgtrigdelay, untrigpmampred, epilabl, epitpr, epiindex] = plotModelQualityScoresForPaper2(featidx, ...
    pmModelRes, labels, pmAMPred, plotsubfolder, basefilename, epilen, randmode, fpropthresh)

% plotModelQualityScoresForPaper - calculates model quality scores at
% episode level and also how much earlier predictions are vs current
% clinical practice

patients = unique(featidx.PatientNbr);
pmAMPred = pmAMPred(ismember(pmAMPred.PatientNbr, patients),:);

alldayidx = true(size(labels, 1), 1);

[epiindex, epilabl, epipred, episafeidx] = convertResultsToEpisodesNew(featidx, labels, pmModelRes.pmNDayRes(1).Pred, epilen, alldayidx);

if randmode
    epilabl     = epilabl(randperm(size(epilabl, 1)));
    randtext    = 'Random';
else
    randtext    = '';
end

[epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc, epipredsort, ~] = calcQualScores(epilabl(episafeidx), epipred(episafeidx));
%[epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(pmAMPred, featidx, labels, pmModelRes.pmNDayRes(1).Pred, epipredsort);
printlog = false;
[epiavgdelayreduction, trigintrtpr, avgtrigdelay] = calcAvgDelayReduction(epiindex(logical(epilabl == 1) & episafeidx, :), ...
        featidx, labels, pmModelRes.pmNDayRes(1).Pred, epipredsort, printlog);


% use these for label method 5/pmV3stSCfd25ff1pd10nm4nw10sf4sw2sl3rm7bf1nb2rn1vo28as1na4vs1nv4cc1pm10ps1bm1bs1np2df0dm1mvvPM1lm5
%chosenpt10pc = 203;
%chosenpt15pc = 279;
%chosenpt20pc = 352;
%chosenpt33pc = 535;
% use these for label method 6/pmV3stSCfd25ff1pd10nm4nw10sf4sw2sl3rm7bf1nb2rn1vo28as1na4vs1nv4cc1pm10ps1bm1bs1np2df0dm1mvvPM1lm6
%chosenpt20pc = 346;
%chosenpt20pc = 383; %actually 22.5%
%chosenpt20pc  = 326; % actually 22% use for best combination
%chosenpt20pc  = 325; % actually 22% use for best combination ex lung and just co/we
%chosenpt20pc  = 327; % actually 22% use for just we
%chosenpt20pc  = 305; % actually 22% use for just lu

%chosenpt20pc = find(epifpr < fpropthresh, 1, 'last');

% choose the best operating point - first find the max point that meets the
% fpr threshold, then find the first point that has the same tpr as this
% point.
maxidxpt = find(epifpr < fpropthresh, 1, 'last');
bestidxpt = find(epitpr == epitpr(maxidxpt), 1, 'first') + 1; % hardcoded to correct due to not calculating episodic numbers for every pred day

%[~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(pmAMPred, featidx, labels, pmModelRes.pmNDayRes(1).Pred, epipredsort(bestidxpt));
printlog = true;
[~, ~, ~, trigintrarray] = calcAvgDelayReductionForThresh(epiindex(logical(epilabl == 1) & episafeidx, :), featidx, labels, pmModelRes.pmNDayRes(1).Pred, epipredsort(bestidxpt), printlog);

%untrigpmampred = pmAMPred(logical(trigintrarray == -1), :);
%untrigpmampred = pmAMPred(logical(trigintrarray == -1), :);

episafeindex = epiindex(logical(epilabl == 1) & episafeidx, :);
untrigepi = episafeindex(logical(trigintrarray == -1), :);
untrigepi.TreatStart = untrigepi.Todn + 1;
untrigpmampred = innerjoin(pmAMPred, untrigepi, 'LeftKeys', {'PatientNbr', 'IVScaledDateNum'}, 'RightKeys', {'PatientNbr', 'TreatStart'}, 'RightVariables', {});

fprintf('\n');
fprintf('At %.1f%% FPR (pt %d), the Triggered Intervention TPR is %.1f%%, Avg Delay Reduction is %.1f days, and Avg Trigger Delay is %.1f days\n', ...
            100 * epifpr(bestidxpt), bestidxpt, trigintrtpr(bestidxpt), epiavgdelayreduction(bestidxpt), avgtrigdelay(bestidxpt));

% estimate for current clinical delay
%currclindelay = 2;

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


baseplotname1 = sprintf('%s-E%dQSfP%s', basefilename, epilen, randtext);

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
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end

