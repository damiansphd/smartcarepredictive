function plotQCPRAndROCCurves(pmQCModelRes, plotsubfolder, basefilename)

% plotQCPRAndROCCurves - plots PR and ROC curves for the quality classifier model
% results 

axisfontsize = 10;
widthinch = 8.25;
heightinch = 3;
name = '';

[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);

baseplotname1 = sprintf('%s-PRROC', basefilename);

randomprec = sum(pmQCModelRes.LabelSort) / size(pmQCModelRes.LabelSort, 1);
xl = [0 1];
yl = [0 1];

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

ax = subplot(1, 2, 1, 'Parent', p);

area(ax, pmQCModelRes.Recall, pmQCModelRes.Precision, ...
    'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);

line(ax, [0, 1], [randomprec, randomprec], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);
ax.FontSize = axisfontsize; 
ax.TickDir = 'out';     
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'Recall');
ylabel(ax, 'Precision');

prtext = sprintf('AUC = %.2f%%', pmQCModelRes.PRAUC);
annotation(p,   'textbox',  ...
                'String', prtext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.2, 0.2, 0.15, 0.1], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', axisfontsize);

ax = subplot(1, 2, 2, 'Parent', p);

hold on;
area(ax, pmQCModelRes.FPR, pmQCModelRes.TPR, ...
    'FaceColor', 'blue', 'LineStyle', '-', 'LineWidth', 1.5);

line(ax, [0, 1], [0, 1], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', 1.0);

scatter(ax, pmQCModelRes.FPR(rocthreshidx), pmQCModelRes.TPR(rocthreshidx),  ...
        24, 'filled', 'o', ...
        'MarkerFaceColor', 'green', ...
        'MarkerEdgeColor', 'black');

ax.FontSize = axisfontsize; 
ax.TickDir = 'out';      
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'FPR');
ylabel(ax, 'TPR');

roctext = sprintf('AUC = %.2f%%', pmQCModelRes.ROCAUC);
annotation(p, 'textbox',  ...
                'String', roctext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.7, 0.2 0.15, 0.1], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', axisfontsize);
hold off;

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end

