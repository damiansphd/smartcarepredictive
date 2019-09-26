function plotModelQualityScoresForPaper(pmTrCVFeatureIndex, pmModelRes, pmTrCVExABLabels, pmAMPred, plotsubfolder, basefilename, epilen)

% plotModelQualityScoresForPaper - calculates model quality scores at
% episode level and also how much earlier predictions are vs current
% clinical practice

[epiindex, epilabl, epipred] = convertResultsToEpisodes(pmTrCVFeatureIndex, pmTrCVExABLabels, pmModelRes.pmNDayRes(1).Pred, epilen);

[epiprecision, epirecall, epitpr, epifpr, epiprauc, epirocauc] = calcQualScores(epilabl, epipred);
[epiavgdelayreduction] = calcAvgDelayReduction(pmAMPred, pmTrCVFeatureIndex, pmTrCVExABLabels, pmModelRes.pmNDayRes(1).Pred, epipred);

% estimate for current clinical delay
currclindelay = 2;

titlefontsize = 14;
labelfontsize = 12;
axisfontsize = 10;
unitfontsize = 10;
smallfontsize = 8;

widthinch = 5.5;
heightinch = 3;
name = '';
singlehght = 1/4.5;
halfhght = singlehght * 0.5;
doublehght = singlehght * 2;
twoandhalfhght = singlehght * 2.5;
triplehght = singlehght * 3;


ntitles = 1;
nplots = 2;
plotwidth  = 1/nplots;

typearray = [1, 4, 5];

typehght = [singlehght, singlehght, triplehght, triplehght, triplehght];

baseplotname1 = sprintf('%s - EpiLen %d Quality Scores for Paper 2', basefilename, epilen);

n = 1;
randomprec = sum(epilabl) / size(epilabl, 1);
xl = [0 1];
yl = [0 1];

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
        displaytext = 'Episode ROC Curve';
        annotation(sp(i), 'textbox',  ...
                        'String', displaytext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0, 0, plotwidth, 1], ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'LineStyle', 'none', ...
                        'FontSize', labelfontsize, ...
                        'FontWeight', 'bold');
        displaytext = {'Early Warning Time'};
        annotation(sp(i), 'textbox',  ...
                        'String', displaytext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [plotwidth, 0, plotwidth, 1], ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'LineStyle', 'none', ...
                        'FontSize', labelfontsize, ...
                        'FontWeight', 'bold'); 
    elseif type == 4
        % ROC Curve plot
        currhght = currhght - typehght(type);
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [0, currhght, plotwidth, typehght(type)]);
                    
        ax = subplot(1, 1, 1, 'Parent', sp(i));
        
        area(ax, epifpr, epitpr, ...
            'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);
        line(ax, [0, 1], [0, 1], ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);
        
        ax.FontSize = axisfontsize; 
        ax.TickDir = 'out';      
        xlim(ax, xl);
        ylim(ax, yl);
        
        xlabel(ax, 'False Positive Rate');
        ylabel(ax, 'True Positive Rate');
        
        roctext = sprintf('AUC = %.2f%%', epirocauc);
        annotation(sp(i), 'textbox',  ...
                        'String', roctext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0.5, 0.3 0.38, 0.1], ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'BackgroundColor', 'white', ...
                        'LineStyle', '-', ...
                        'FontSize', axisfontsize);
    elseif type == 5
        % Reduction in treatment delay plot
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [plotwidth, currhght, plotwidth, typehght(type)]);
                    
        ax = subplot(1, 1, 1, 'Parent', sp(i));
        
        area(ax, epifpr, epiavgdelayreduction, ...
            'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);
        hold on;
        
        chosenpt = 279; % other options are 217 or 347 
        scatter(ax, epifpr(chosenpt), epiavgdelayreduction(chosenpt), 'Marker', 'o', ...
            'MarkerFaceColor', 'green', 'MarkerEdgeColor', 'green', 'SizeData', 18);
        
        chosenpt = 352;
        scatter(ax, epifpr(chosenpt), epiavgdelayreduction(chosenpt), 'Marker', 'o', ...
            'MarkerFaceColor', 'green', 'MarkerEdgeColor', 'green', 'SizeData', 18);
        
        ax.FontSize = axisfontsize; 
        ax.TickDir = 'out';      
        xlim(ax, xl);
        %ylim(ax, yl);
        
        xlabel(ax, 'False Positive Rate');
        ylabel(ax, 'Early Warning Time');
        
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

