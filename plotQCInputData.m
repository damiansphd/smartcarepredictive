function plotQCInputData(pmMissPattQSPct, pmQSThresh, plotsubfolder, basefilename)

% plotQCInputData - plots various visualisations of the Quality Classifier
% input data (somewhat hardcoded choices for expedience)

widthinch = 8.5;
heightinch = 11;
plotsacross = 2;
plotsdown   = 3;
name = '';

axisfontsize = 10;
labelfontsize = 12;
markersize = 10;
transparency = 0.2;
mcol = 'blue';


baseplotname1 = sprintf('%s-QSDataViz', basefilename);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

ax = subplot(plotsdown, plotsacross, 1, 'Parent', p);
hold on;    
scatter(ax, pmMissPattQSPct.AvgEPV, pmMissPattQSPct.TrigDelay, ...
    markersize, 'filled', ...
    'MarkerEdgeColor', mcol, ...
    'MarkerFaceColor', mcol, ...
    'Marker', 'o', ...
    'MarkerEdgeAlpha', transparency, ...
    'MarkerFaceAlpha', transparency);   
ax.FontSize = axisfontsize; 
ax.TickDir = 'out';     
xlabel(ax, 'AvgEPV');
ylabel(ax, 'Trigger Delay');
title(ax, 'Correlation plot', 'FontSize', labelfontsize);

ax = subplot(plotsdown, plotsacross, 2, 'Parent', p);
hold on;    
scatter(ax, pmMissPattQSPct.AvgEPV, pmMissPattQSPct.EarlyWarn, ...
    markersize, 'filled', ...
    'MarkerEdgeColor', mcol, ...
    'MarkerFaceColor', mcol, ...
    'Marker', 'o', ...
    'MarkerEdgeAlpha', transparency, ...
    'MarkerFaceAlpha', transparency);   
ax.FontSize = axisfontsize; 
ax.TickDir = 'out';     
xlabel(ax, 'AvgEPV');
ylabel(ax, 'Early Warning');
title(ax, 'Correlation plot', 'FontSize', labelfontsize);

ax = subplot(plotsdown, plotsacross, 3, 'Parent', p);
hold on;    
scatter(ax, pmMissPattQSPct.AvgEPV, pmMissPattQSPct.TrigIntrTPR, ...
    markersize, 'filled', ...
    'MarkerEdgeColor', mcol, ...
    'MarkerFaceColor', mcol, ...
    'Marker', 'o', ...
    'MarkerEdgeAlpha', transparency, ...
    'MarkerFaceAlpha', transparency);   
ax.FontSize = axisfontsize; 
ax.TickDir = 'out';     
xlabel(ax, 'AvgEPV');
ylabel(ax, 'Pct Triggered Interventions');
title(ax, 'Correlation plot', 'FontSize', labelfontsize);


basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
close(f);

end

