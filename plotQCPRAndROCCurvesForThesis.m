function plotQCPRAndROCCurvesForThesis(pmQCModelRes, plotsubfolder, basefilename)

% plotQCPRAndROCCurvesForThesis - plots PR and ROC curves for the quality classifier model
% results 
% Updated format for thesis

titlefontsize = 14;
labelfontsize = 12;
axisfontsize = 10;
unitfontsize = 10;
textboxfontsize = 8;

widthinch = 4.5;
heightinch = 4;


pllinewidth = 2.5;
axlinewidth = 1.5;
ptsize = 36;

fontname    = 'Arial';
colarray = [188, 188, 229; ...
            196, 159, 132; ...
            190, 229, 176];
             
colarray = colarray ./ 255;


[~, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);
fprintf('Inflexion point (yellow) is at index point %d with FPR %.3f%% TPR %.3f%% Precision %.3f%% Recall %.3f%% with operating threshold %.20f\n', ...
    rocthreshidx, 100 * pmQCModelRes.FPR(rocthreshidx), 100 * pmQCModelRes.TPR(rocthreshidx), ...
    100 * pmQCModelRes.Precision(rocthreshidx), 100 * pmQCModelRes.Recall(rocthreshidx), pmQCModelRes.PredSort(rocthreshidx));

fprintf('Min Cost point (green) of %.5f is at index point %d with FPR %.3f%% TPR %.3f%% Precision %.3f%% Recall %.3f%% with operating threshold %.20f\n', ...
    pmQCModelRes.QCCostOp, pmQCModelRes.IdxOp, pmQCModelRes.FPROp, pmQCModelRes.TPROp, ...
    pmQCModelRes.PrecisionOp, pmQCModelRes.RecallOp, pmQCModelRes.PredSort(pmQCModelRes.IdxOp));




xl = [0 1];
yl = [0 1];

% 1) PR Curve Plot
name = '';
baseplotname1 = sprintf('%s-Thesis-PR', basefilename);

randomprec = sum(pmQCModelRes.LabelSort) / size(pmQCModelRes.LabelSort, 1);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
ax = subplot(1, 1, 1, 'Parent', p);

hold on;
area(ax, pmQCModelRes.Recall, pmQCModelRes.Precision, ...
    'FaceColor', colarray(1,:), 'LineStyle', '-', 'LineWidth', pllinewidth);

line(ax, [0, 1], [randomprec, randomprec], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);

%scatter(ax, pmQCModelRes.Recall(rocthreshidx), pmQCModelRes.Precision(rocthreshidx),  ...
%        24, 'filled', 'o', ...
%        'MarkerFaceColor', 'yellow', ...
%        'MarkerEdgeColor', 'black');

scatter(ax, pmQCModelRes.RecallOp/100, pmQCModelRes.PrecisionOp/100,  ...
        ptsize, 'filled', 'o', ...
        'MarkerFaceColor', 'green', ...
        'MarkerEdgeColor', 'black');

ax.FontSize   = axisfontsize;
ax.FontWeight = 'bold';
ax.FontName   = fontname;
ax.TickDir    = 'out';   
ax.LineWidth  = axlinewidth;
ax.Title.String = 'PR Curve';
ax.Title.FontSize = titlefontsize;
ax.Title.FontWeight = 'bold';
ax.XTick  = [0, 0.2, 0.4, 0.6, 0.8, 1];
ax.YTick  = [0, 0.2, 0.4, 0.6, 0.8, 1];
  
xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'Recall');
ylabel(ax, 'Precision');

prtext = sprintf('AUC = %.1f%%\nRecall Op Thresh = %.1f%%\nPrecision Op Thresh = %.1f%%', pmQCModelRes.PRAUC, pmQCModelRes.RecallOp, pmQCModelRes.PrecisionOp);
annotation(p,   'textbox',  ...
                'String', prtext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.45, 0.2, 0.4, 0.12], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', textboxfontsize, ...
                'FontWeight', 'bold');
hold off;

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

% 2) ROC Curve

name = '';
baseplotname1 = sprintf('%s-Thesis-ROC', basefilename);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
ax = subplot(1, 1, 1, 'Parent', p);

hold on;
area(ax, pmQCModelRes.FPR, pmQCModelRes.TPR, ...
    'FaceColor', colarray(2,:), 'LineStyle', '-', 'LineWidth', pllinewidth);

line(ax, [0, 1], [0, 1], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);

%scatter(ax, pmQCModelRes.FPR(rocthreshidx), pmQCModelRes.TPR(rocthreshidx),  ...
%        24, 'filled', 'o', ...
%        'MarkerFaceColor', 'yellow', ...
%        'MarkerEdgeColor', 'black');

scatter(ax, pmQCModelRes.FPROp/100, pmQCModelRes.TPROp/100,  ...
        ptsize, 'filled', 'o', ...
        'MarkerFaceColor', 'green', ...
        'MarkerEdgeColor', 'black');

ax.FontSize   = axisfontsize;
ax.FontWeight = 'bold';
ax.FontName   = fontname;
ax.TickDir    = 'out';   
ax.LineWidth  = axlinewidth;
ax.Title.String = 'ROC Curve';
ax.Title.FontSize = titlefontsize;
ax.Title.FontWeight = 'bold';
ax.XTick  = [0, 0.2, 0.4, 0.6, 0.8, 1];
ax.YTick  = [0, 0.2, 0.4, 0.6, 0.8, 1];

xlim(ax, xl);
ylim(ax, yl);

xlabel(ax, 'FPR');
ylabel(ax, 'TPR');

roctext = sprintf('AUC = %.1f%%\nFPR Op Thresh = %.1f%%\nTPR Op Thresh = %.1f%%', pmQCModelRes.ROCAUC, pmQCModelRes.FPROp, pmQCModelRes.TPROp);
annotation(p, 'textbox',  ...
                'String', roctext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.48, 0.2, 0.37, 0.12], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', textboxfontsize, ...
                'FontWeight', 'bold');
hold off;

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

% 3) QC Cost Curve

name = '';
baseplotname1 = sprintf('%s-Thesis-Cost', basefilename);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
ax = subplot(1, 1, 1, 'Parent', p);

hold on;
area(ax, pmQCModelRes.PredSort, pmQCModelRes.QCCostArray, ...
    'FaceColor', colarray(3,:), 'LineStyle', '-', 'LineWidth', pllinewidth);

line(ax, [pmQCModelRes.PredSort(pmQCModelRes.IdxOp), pmQCModelRes.PredSort(pmQCModelRes.IdxOp)], [0, max(pmQCModelRes.QCCostArray)], ...
    'Color', 'red', 'LineStyle', '-', 'LineWidth', axlinewidth);

%scatter(ax, pmQCModelRes.PredSort(rocthreshidx), pmQCModelRes.QCCostArray(rocthreshidx),  ...
%        24, 'filled', 'o', ...
%        'MarkerFaceColor', 'yellow', ...
%        'MarkerEdgeColor', 'black');

scatter(ax, pmQCModelRes.PredSort(pmQCModelRes.IdxOp), pmQCModelRes.QCCostOp,  ...
        ptsize, 'filled', 'o', ...
        'MarkerFaceColor', 'green', ...
        'MarkerEdgeColor', 'black');

ax.FontSize   = axisfontsize;
ax.FontWeight = 'bold';
ax.FontName   = fontname;
ax.TickDir    = 'out';   
ax.LineWidth  = axlinewidth;
ax.Title.String = 'Cost Function';
ax.Title.FontSize = titlefontsize;
ax.Title.FontWeight = 'bold';
   
xlim(ax, [0 1]);
ylim(ax, [0 max(pmQCModelRes.QCCostArray)]);

xlabel(ax, 'Operating Threshold');
ylabel(ax, 'Cost');

xlim(ax, xl);
ylim(ax, [0 1.5]);

qccosttext = sprintf('Min Cost = %.5f\nOp Thresh = %.2f', pmQCModelRes.QCCostOp, pmQCModelRes.PredSort(pmQCModelRes.IdxOp));
annotation(p, 'textbox',  ...
                'String', qccosttext, ...
                'Interpreter', 'tex', ...
                'Units', 'normalized', ...
                'Position', [0.42, 0.45 0.3, 0.1], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', 'white', ...
                'LineStyle', '-', ...
                'FontSize', textboxfontsize, ...
                'FontWeight', 'bold');
hold off;

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end

