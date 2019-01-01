clear; close all; clc;

% load predictive model inputs for chosen study

[~, studydisplayname, ~] = selectStudy();

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat', studydisplayname);

fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));

plotsubfolder = sprintf('Plots/%sTreatmentDelayVsSeverity', studydisplayname);
mkdir(fullfile(basedir, plotsubfolder));

% calculate treatment delay and various severity measures for each
% intervention

results = pmAMPred(:,{'PatientNbr', 'ID', 'IntrNbr', 'IVScaledDateNum', 'Ex_Start', 'Offset'});
results.MeasDuration(:)      = 0;
results.IntrFreq(:)          = 0;
results.IntrFreqQuartile(:)  = 0;
results.Delay                = (-1 * results.Ex_Start) - results.Offset;
results.IVDays(:)            = 0;
results.CumIVDays(:)         = 0;
results.ABDays(:)            = 0;
results.CumABDays(:)         = 0;
results.WeightedCumABDays(:) = 0;

ninterventions = size(pmAMPred,1);
quartiledivider = 75;

for n = 1:ninterventions
    pnbr = results.PatientNbr(n);
    intrdn = results.IVScaledDateNum(n);
    results.MeasDuration(n) = (pmPatients.RelLastMeasdn(pmPatients.PatientNbr == pnbr) - pmPatients.RelFirstMeasdn(pmPatients.PatientNbr == pnbr) + 1);
    results.IntrFreq(n) =  results.MeasDuration(n) / (sum(results.PatientNbr == pnbr));
    results.IntrFreqQuartile(n) = ceil(results.IntrFreq(n) / quartiledivider);
    
    tempab = pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStartdn >= intrdn & pmAntibiotics.RelStartdn < intrdn + 30,:);
    tempiv = tempab(ismember(tempab.Route, 'IV'),:);
    
    minstart = min(tempab.RelStartdn);
    maxstop  = max(tempab.RelStopdn);
    
    for d = minstart:maxstop
        nabperday = sum(tempab.RelStartdn <= d & tempab.RelStopdn >= d);
        results.CumABDays(n) = results.CumABDays(n) + nabperday;
        if nabperday > 0
            results.ABDays(n) = results.ABDays(n) + 1;
        end
        nivperday = sum(tempiv.RelStartdn <= d & tempiv.RelStopdn >= d);
        results.CumIVDays(n) = results.CumIVDays(n) + nivperday;
        if nivperday > 0
            results.IVDays(n) = results.IVDays(n) + 1;
        end
        noralperday = nabperday - nivperday;
        results.WeightedCumABDays(n) = results.WeightedCumABDays(n) + (nivperday * 3) + noralperday;
    end
end

% plot results and observe any correlations

ntypes = 5;
nplots = 5;
% colormap - red, green, blue, black
cmap = [1, 0, 0;
        0, 1, 0;
        0, 0, 1;
        0, 0, 0];
plottypes = {'All', 'IntrFreq0-74', 'IntrFreq75-149', 'IntrFreq150-224', 'IntrFreq225-299'};
coloffset = 10;

for t = 1:ntypes
    baseplotname = sprintf('%s - Treatment delay vs Severity - %s', studydisplayname, results.Properties.VariableNames{coloffset + t});
    [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
    ax1 = gobjects(nplots,1);
    
    plotsacross = 2;
    plotsdown = round(nplots/plotsacross);
    
    ax1(1) = subplot(plotsdown, plotsacross, 1, 'Parent', p);
    scatter(ax1(1), results.Delay, table2array(results(:,coloffset + t)), [], cmap(3, :));
    xlabel(ax1(1), 'Treatment Delay');
    ylabel(ax1(1), 'Severity');
    title(ax1(1), plottypes{1});
    hold on;

    for n = 2:nplots
        ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent', p);
        scatter(ax1(n), results.Delay(results.IntrFreqQuartile == (n-1)), table2array(results(results.IntrFreqQuartile == (n-1),coloffset + t)), [], cmap(n - 1,:));
        xlabel(ax1(n), 'Treatment Delay');
        ylabel(ax1(n), 'Severity');
        title(ax1(n), plottypes{n});
    end
    
    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
end
    