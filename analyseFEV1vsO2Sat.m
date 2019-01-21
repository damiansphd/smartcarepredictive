clear; close all; clc;

% load predictive model inputs for chosen study

[~, studydisplayname, ~] = selectStudy();

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat', studydisplayname);

fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));

plotsubfolder = sprintf('Plots/%sFEV1vsO2Sat', studydisplayname);
mkdir(fullfile(basedir, plotsubfolder));

% plot FEV1 vs O2 Sat
% plot each data point minus robust max for each patient
% color code points into 1) upper 50% robust max of FEV1 2) lower 50%

mfev1idx  = measures.Index(ismember(measures.DisplayName, 'LungFunction'));
mo2satidx = measures.Index(ismember(measures.DisplayName, 'O2Saturation'));

fev1max  = pmPatientMeasStats(pmPatientMeasStats.MeasureIndex == mfev1idx, {'PatientNbr', 'Max'});
o2satmax = pmPatientMeasStats(pmPatientMeasStats.MeasureIndex == mo2satidx,{'PatientNbr', 'Max'});

ntiles = 2;
quintilegradients = sortrows(fev1max, {'Max'}, 'ascend');
quintilegradients.NTile(:) = 0;
quintilegradients.Gradient(:) = 0.0;

for i = 1:npatients
    quintilegradients.NTile(i) = ceil((i * ntiles)/ npatients);
end

midpoint = ceil(npatients/2);
lpatients = quintilegradients.PatientNbr(1:midpoint);
upatients = quintilegradients.PatientNbr(midpoint + 1:npatients);

quintilegradients = sortrows(quintilegradients, {'PatientNbr'}, 'ascend');

ldatapoints = sum(pmPatients.RelLastMeasdn(lpatients));
udatapoints = sum(pmPatients.RelLastMeasdn(upatients));
lfev1data  = zeros(ldatapoints, 1);
lo2satdata = zeros(ldatapoints, 1);
ufev1data  = zeros(udatapoints, 1);
uo2satdata = zeros(udatapoints, 1);

ulastpoint = 0;
llastpoint = 0;

plotsacross = 1;
plotsdown   = 1;
xl = [-80, 0];
yl = [-25, 0];

for n = 1:npatients
    
    pnbr  = pmPatients.PatientNbr(n);
    pfmdn = pmPatients.RelFirstMeasdn(n);
    plmdn = pmPatients.RelLastMeasdn(n);
    pntile = quintilegradients.NTile(quintilegradients.PatientNbr == pnbr);
    
    pfev1max   = fev1max.Max(fev1max.PatientNbr == pnbr);
    po2satmax  = o2satmax.Max(o2satmax.PatientNbr == pnbr);
    
    pfev1data  = pmRawDatacube(pnbr, pfmdn:plmdn, mfev1idx) - pfev1max;
    po2satdata = pmRawDatacube(pnbr, pfmdn:plmdn, mo2satidx) - po2satmax;
    
    if ismember(pnbr, lpatients)
        lfev1data((llastpoint + 1):(llastpoint + plmdn)) = pfev1data;
        lo2satdata((llastpoint + 1):(llastpoint + plmdn)) = po2satdata - 0.15;
        llastpoint = llastpoint + plmdn;
        dcolor = 'red';
    else
        ufev1data((ulastpoint + 1):(ulastpoint + plmdn)) = pfev1data;
        uo2satdata((ulastpoint + 1):(ulastpoint + plmdn)) = po2satdata;
        ulastpoint = ulastpoint + plmdn;
        dcolor = 'blue';
    end
    
    baseplotname = sprintf('%s - FEV1 vs O2Sat - Patient %d, Quintile %d', studydisplayname, n, pntile);
    [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
    ax1 = subplot(plotsdown, plotsacross, 1, 'Parent', p);
    hold on;
    quintilegradients.Gradient(n) = plotFEV1vsO2Sat(ax1, pfev1data, po2satdata, dcolor, xl, yl);
    
    legend(ax1, {'FEV1 data', sprintf('Regression Line - Grad %.2f', quintilegradients.Gradient(n))}, ...
        'Location', 'best', 'FontSize', 6);
    hold off;

    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
    
end

% plot FEV1 50:50 split results and observe any correlations
baseplotname = sprintf('%s - FEV1 vs O2Sat', studydisplayname);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
ax1 = subplot(plotsdown, plotsacross, 1, 'Parent', p);
hold on;
ugrad = plotFEV1vsO2Sat(ax1, ufev1data, uo2satdata, 'blue', xl, yl);
lgrad = plotFEV1vsO2Sat(ax1, lfev1data, lo2satdata, 'red', xl, yl);
legend(ax1, {'U50% FEV1 data', sprintf('U50%% Regression Line - Grad %.2f', ugrad), 'L50% FEV1 Data', sprintf('L50%% Regression Line - Grad %.2f', lgrad)}, ...
    'Location', 'best', 'FontSize', 6);
hold off;
basedir = setBaseDir();
savePlotInDir(f, baseplotname, basedir, plotsubfolder);
close(f);

% plot correlation lines colored by quintile
plotsacross = 2;
plotsdown   = 3;
ax1 = gobjects(5,1);
qcolor = [{'red'}; {'magenta'}; {'green'}; {'blue'}; {'black'}];
baseplotname = sprintf('%s - FEV1 vs O2Sat - Regression Lines by Quintile', studydisplayname);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
hold on;
quintilegradients = sortrows(quintilegradients, {'NTile', 'PatientNbr'}, 'ascend');
for n = 1:ntiles
    qgrad = quintilegradients(quintilegradients.NTile == n, :);
    nqlines = size(qgrad,1);
    ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent', p);
    yreg = zeros(nqlines, 2);
    hold on;
    for i = 1:nqlines
        yreg(i,1) = xl(1) * qgrad.Gradient(i);
        plot(ax1(n), xl, yreg(i,:), 'Color', qcolor{qgrad.NTile(i)}, 'Linestyle', ':');
        xlim(ax1(n), xl);
        ylim(ax1(n), yl);
    end
    yregavg = [xl(1) * mean(qgrad.Gradient), 0];
    plot(ax1(n), xl, yregavg, 'Color', qcolor{qgrad.NTile(i)}, 'Linestyle', '-', 'LineWidth', 1);
    hold off;
    title(ax1(n), sprintf('Quintile %d (Avg Max Fev1 %.0f%%): Avg Gradient %.2f', n, mean(qgrad.Max), mean(qgrad.Gradient)), 'FontSize', 6);
end
basedir = setBaseDir();
savePlotInDir(f, baseplotname, basedir, plotsubfolder);
close(f);

    