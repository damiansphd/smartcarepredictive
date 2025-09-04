clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

basedir = setBaseDir();
subfolder = 'ExcelFiles';
plotsdown   = 1; 
plotsacross = 1;
thisplot = 1;
widthinch = 8;
heightinch = 6;
fontname = 'Arial';
axisfontsize = 12;
labelfontsize = 14;
pllinewidth = 2.5;

%247, 150,  70; ...

[~, studydisplayname, ~] = selectStudy();

if (studydisplayname == 'SC')
    inputfile = 'BSQ-ScenY1.4-Fig4E-pmV5stSCdw25nw10au1nm4sf4sw2sl3ip1mc-10mi1rm3_28ms1vo3_28pm3_28-pmmp_vPM1_lm6_rg0-pmhp_dummy-rt1-bt1.xlsx';
    
    colarray = [250, 191, 143; ...
                250, 191, 143; ...
                255, 139,  40; ...
                196, 215, 155; ...
                196, 215, 155; ...
                196, 215, 155; ...
                 48, 200,  48; ...
                149, 179, 215; ...
                 24,  60, 250; ...
                 79, 129, 189; ...
                 79, 129, 189; ...
                 79, 129, 189; ...
                 79, 129, 189];
             
    colarray = colarray ./ 255;
elseif (studydisplayname == 'BR')
    inputfile = 'BSQ-BRv6-Fig4E-pmmfpV6stBRdw25nw10au1rd1nm4sf4sw2sl3ip1mc-10mi1rm4_23ms1vo4_23pm4_23-pmmp_vPM1_lm6_rg0-pmhp_dummy-rt1-bt2.xlsx';

    colarray = [250, 191, 143; ...
                250, 191, 143; ...
                255, 139,  40; ...
                196, 215, 155; ...
                196, 215, 155; ...
                196, 215, 155; ...
                 48, 200,  48; ...
                149, 179, 215; ...
                 24,  60, 250; ...
                 79, 129, 189; ...
                 79, 129, 189; ...
                 79, 129, 189; ...
                 79, 129, 189];

    colarray = colarray ./ 255;
end

pmBSAllQSTable = readtable(fullfile(basedir, subfolder, inputfile));

plottitle = sprintf('%s-PMThesisMeasComb', studydisplayname);
[f, p] = createFigureAndPanelForPaper('', widthinch, heightinch);
ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);

hold on;
for i = 1:size(pmBSAllQSTable, 1)
    xlabeltext(i) = ' ';
    b = bar(ax, i, pmBSAllQSTable.AvgEPV(i));
    b.FaceColor = colarray(i, :);
    b.EdgeColor = [0, 0, 0]; % black outer line for bars
    b.LineWidth = pllinewidth;
end
ax.FontSize   = axisfontsize;
ax.FontName   = fontname;
ax.FontWeight = 'bold';
ax.LineWidth  = pllinewidth;
xticks(ax, 1:size(pmBSAllQSTable, 1));
ax.XTickLabel = xlabeltext;
ylabel(ax, 'Episodic prediction value (EPV)', 'FontSize', labelfontsize);
xlim(ax, [0.4, size(pmBSAllQSTable, 1) + 0.6]);

% save plot
plotsubfolder = sprintf('Plots');
savePlotInDir(f, plottitle, basedir, plotsubfolder);
savePlotInDirAsSVG(f, plottitle, plotsubfolder);
close(f);

