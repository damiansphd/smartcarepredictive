clear; close all; clc;

% choose study
[~, studydisplayname, ~] = selectStudy();

% choose plottype and number of data splits
fprintf('\n');
fprintf('Plots to run\n');
fprintf('-------------------\n');
fprintf('1: Patient by Patient\n');
fprintf('2: Upper vs Lower 50%%\n');
fprintf('3: Ntiles\n');
fprintf('\n');
runtype = input('Choose plots to run for: ');

if runtype > 3
    fprintf('Invalid choice\n');
    return;
end
if isequal(runtype,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

ntiles = input('Choose number of ntiles (2-5): ');
if runtype > 5 || runtype < 2
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');
if ntiles == 2
    ntiletext = 'Half';
elseif ntiles == 3
    ntiletext = 'Third';
elseif ntiles == 4
    ntiletext = 'Quartile';
elseif ntiles == 5
    ntiletext = 'Quintile';
else
    ntiletext = 'Unknwn Division';
end

% load predictive model inputs for chosen study
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

patientgradients = sortrows(fev1max, {'Max'}, 'ascend');
patientgradients.NTile(:) = 0;
patientgradients.Gradient(:) = 0.0;
for i = 1:npatients
    patientgradients.NTile(i) = ceil((i * ntiles)/ npatients);
end

plotsacross = 1;
plotsdown   = 1;
xl = [-80, 0];
yl = [-25, 0];

if runtype == 1 || runtype == 2
    
    midpoint = ceil(npatients/2);
    lpatients = patientgradients.PatientNbr(1:midpoint);
    upatients = patientgradients.PatientNbr(midpoint + 1:npatients);

    ldatapoints = sum(pmPatients.RelLastMeasdn(lpatients));
    udatapoints = sum(pmPatients.RelLastMeasdn(upatients));
    lfev1data  = zeros(ldatapoints, 1);
    lo2satdata = zeros(ldatapoints, 1);
    ufev1data  = zeros(udatapoints, 1);
    uo2satdata = zeros(udatapoints, 1);

    ulastpoint = 0;
    llastpoint = 0;
    
    for n = 1:npatients
        pnbr  = pmPatients.PatientNbr(n);
        pfmdn = pmPatients.RelFirstMeasdn(n);
        plmdn = pmPatients.RelLastMeasdn(n);
        pntile = patientgradients.NTile(patientgradients.PatientNbr == pnbr);
    
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
    
        if runtype == 1
            baseplotname = sprintf('%s - FEV1 vs O2Sat - Patient %d, %s %d', studydisplayname, n, ntiletext, pntile);
            [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
            ax1 = subplot(plotsdown, plotsacross, 1, 'Parent', p);
            hold on;
            patientgradients.Gradient(n) = plotFEV1vsO2Sat(ax1, pfev1data, po2satdata, dcolor, xl, yl, 'FEV1 vs O2 Saturation');
    
            legend(ax1, {'FEV1 data', sprintf('Regression Line - Grad %.2f', patientgradients.Gradient(n))}, ...
                'Location', 'best', 'FontSize', 6);
            hold off;

            basedir = setBaseDir();
            savePlotInDir(f, baseplotname, basedir, plotsubfolder);
            close(f);
        end
    end
    
    % plot FEV1 50:50 split results and observe any correlations
    baseplotname = sprintf('%s - FEV1 vs O2Sat', studydisplayname);
    [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
    ax1 = subplot(plotsdown, plotsacross, 1, 'Parent', p);
    hold on;
    ugrad = plotFEV1vsO2Sat(ax1, ufev1data, uo2satdata, 'blue', xl, yl, 'FEV1 vs O2 Saturation');
    lgrad = plotFEV1vsO2Sat(ax1, lfev1data, lo2satdata, 'red', xl, yl, 'FEV1 vs O2 Saturation');
    legend(ax1, {'U50% FEV1 data', sprintf('U50%% Regression Line - Grad %.2f', ugrad), 'L50% FEV1 Data', sprintf('L50%% Regression Line - Grad %.2f', lgrad)}, ...
        'Location', 'best', 'FontSize', 6);
    hold off;
    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);

elseif runtype == 3
    
    % plot data and regression lines for each ntile
    plotsacross = 2;
    plotsdown   = ceil(ntiles/plotsacross);
    if plotsdown == 1
        plotsdown = 2;
    end
    qcolor = [{'red'}; {'magenta'}; {'green'}; {'blue'}; {'black'}];
    baseplotname = sprintf('%s - FEV1 vs O2Sat - by %s', studydisplayname, ntiletext);
    [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
    ax1 = gobjects(ntiles,1);
    hold on;
    patientgradients = sortrows(patientgradients, {'PatientNbr'}, 'ascend');
    %patientgradients = sortrows(patientgradients, {'NTile', 'PatientNbr'}, 'ascend');
    for i = 1:ntiles
        fev1data  = zeros(npatients * maxdays, 1);
        o2satdata  = zeros(npatients * maxdays, 1);
        lastpoint = 0;
        for n = 1:npatients
            pnbr  = patientgradients.PatientNbr(n);
            pntile = patientgradients.NTile(n);
            pfev1max   = fev1max.Max(fev1max.PatientNbr == pnbr);
            po2satmax  = o2satmax.Max(o2satmax.PatientNbr == pnbr);
            if pntile == i
                %pfmdn = pmPatients.RelFirstMeasdn(n);
                %plmdn = pmPatients.RelLastMeasdn(n);
                pfev1data  = pmRawDatacube(pnbr, :, mfev1idx) - pfev1max;
                po2satdata = pmRawDatacube(pnbr, :, mo2satidx) - po2satmax;
    
                fev1data((lastpoint + 1):(lastpoint + maxdays))  = pfev1data;
                o2satdata((lastpoint + 1):(lastpoint + maxdays)) = po2satdata;
                lastpoint = lastpoint + maxdays;
            end
            
        end
        minfev1 = min(fev1max.Max(patientgradients.NTile==i));
        maxfev1 = max(fev1max.Max(patientgradients.NTile==i));
        plottitle = sprintf('FEV1 (%.0f-%.0f%%) vs O2 Sat ', minfev1, maxfev1);
        % plot FEV1 50:50 split results and observe any correlations
        ax1(i) = subplot(plotsdown, plotsacross, i, 'Parent', p);
        hold on;
        grad = plotFEV1vsO2Sat(ax1(i), fev1data, o2satdata, qcolor{i}, xl, yl, plottitle);
        legend(ax1(i), {'FEV1 data', sprintf('Regression Line - Grad %.2f', grad)}, ...
        'Location', 'best', 'FontSize', 6);
        hold off;
        
    end
    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
    
end
    
%    for n = 1:ntiles
%        qgrad = patientgradients(patientgradients.NTile == n, :);
%        nqlines = size(qgrad,1);
%        ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent', p);
%        yreg = zeros(nqlines, 2);
%        hold on;
%        for i = 1:nqlines
%            yreg(i,1) = xl(1) * qgrad.Gradient(i);
%            plot(ax1(n), xl, yreg(i,:), 'Color', qcolor{qgrad.NTile(i)}, 'Linestyle', ':');
%            xlim(ax1(n), xl);
%            ylim(ax1(n), yl);
%        end
%        yregavg = [xl(1) * mean(qgrad.Gradient), 0];
%        plot(ax1(n), xl, yregavg, 'Color', qcolor{qgrad.NTile(i)}, 'Linestyle', '-', 'LineWidth', 1);
%        hold off;
%        title(ax1(n), sprintf('Quintile %d (Avg Max Fev1 %.0f%%): Avg Gradient %.2f', n, mean(qgrad.Max), mean(qgrad.Gradient)), 'FontSize', 6);
%    end
%    basedir = setBaseDir();
%    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
%    close(f);
%end

%patientgradients = sortrows(patientgradients, {'PatientNbr'}, 'ascend');
    