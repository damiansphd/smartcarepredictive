clear; close all; clc;

% choose study
[~, studydisplayname, ~] = selectStudy();

% load predictive model inputs for chosen study
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat', studydisplayname);

fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));

% need to create interpolated data cube and vol cubes here as they are no
% longer created as part of the data pipeline
fprintf('Creating interpolated cube\n');
[pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures);
[pmInterpDatacube] = handleMissingFeatures(pmPatients, pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures);
toc
fprintf('\n');

plotsubfolder = sprintf('Plots/%sFEV1SmoothingAnalysis', studydisplayname);
mkdir(fullfile(basedir, plotsubfolder));

rawcolor = [0.13, 0.55, 0.13];
wcolors = [{'black'}; {'blue'}; {'red'}; {'black'}; {'blue'}; {'red'}];

npages = 15;
plotsacross = 1;
plotsdown   = 6;
fevidx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

rng(2);
expatients = [78, 29, 36, 40, 44, 71, 73, randperm(npatients)]; % hardcode to include patient who did duplicate/triplicate lung measures

%for n = 1:npages
for n = 1:1
    pnbr = expatients(n);
    baseplotname = sprintf('%s - FEV1 Smoothing Analysis - Patient %d', studydisplayname, pnbr);
    %[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
    widthinch = 8.25;
    heightinch = 11.75;
    [f, p] = createFigureAndPanelForPaper('', widthinch, heightinch);
    ax1 = gobjects(plotsdown,1);
    
    pmaxdays  = pmPatients.LastMeasdn(pmPatients.PatientNbr == pnbr) - pmPatients.FirstMeasdn(pmPatients.PatientNbr == pnbr) + 1;
    days      = (1:pmaxdays);
    mrawdata  = pmRawDatacube(pnbr, 1:pmaxdays, fevidx);
    mdata     = pmInterpDatacube(pnbr, 1:pmaxdays, fevidx);
    interppts = mdata;
    interppts(~isnan(mrawdata)) = nan;
    
    xl = [1 pmaxdays];
    if size(pmPatientMeasStats.Mean(pmPatientMeasStats.PatientNbr == pnbr & pmPatientMeasStats.MeasureIndex == fevidx), 1) == 0
        yl = [(pmOverallStats.Mean(fevidx) - pmOverallStats.StdDev(fevidx)) (pmOverallStats.Mean(fevidx) + pmOverallStats.StdDev(fevidx))];
    else
        yl = [(pmPatientMeasStats.Mean(pmPatientMeasStats.PatientNbr == pnbr & pmPatientMeasStats.MeasureIndex == fevidx) ...
                - pmPatientMeasStats.StdDev(pmPatientMeasStats.PatientNbr == pnbr & pmPatientMeasStats.MeasureIndex == fevidx)) ...
              (pmPatientMeasStats.Mean(pmPatientMeasStats.PatientNbr == pnbr & pmPatientMeasStats.MeasureIndex == fevidx) ...
                + pmPatientMeasStats.StdDev(pmPatientMeasStats.PatientNbr == pnbr & pmPatientMeasStats.MeasureIndex == fevidx))];
    end
    
    pc = 1;
    ax1(pc) = subplot(plotsdown, plotsacross, pc, 'Parent', p);
    plottext = sprintf('Centered 5 day Mean');
    [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');
    [xl, yl] = plotMeasurementData(ax1(pc), days, smooth(mdata, 5), xl, yl, plottext, 0, wcolors{pc}, '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    pc = pc + 1;
    ax1(pc) = subplot(plotsdown, plotsacross, pc, 'Parent', p);
    plottext = sprintf('Centered 3 day Max');
    [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');
    [xl, yl] = plotMeasurementData(ax1(pc), days, movmax(mdata, 3), xl, yl, plottext, 0, wcolors{pc}, '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    pc = pc + 1;
    ax1(pc) = subplot(plotsdown, plotsacross, pc, 'Parent', p);
    plottext = sprintf('Centered 5 day Median');
    [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');    
    [xl, yl] = plotMeasurementData(ax1(pc), days, movmedian(mdata, 5), xl, yl, plottext, 0, wcolors{pc}, '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    pc = pc + 1;
    ax1(pc) = subplot(plotsdown, plotsacross, pc, 'Parent', p);
    plottext = sprintf('Trailing 3 day Mean');
    [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');
    [xl, yl] = plotMeasurementData(ax1(pc), days, movmean(mdata, [2 0]), xl, yl, plottext, 0, wcolors{pc}, '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    pc = pc + 1;
    ax1(pc) = subplot(plotsdown, plotsacross, pc, 'Parent', p);
    plottext = sprintf('Trailing 3 day Max');
    [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');
    [xl, yl] = plotMeasurementData(ax1(pc), days, movmax(mdata, [2 0]), xl, yl, plottext, 0, wcolors{pc}, '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    pc = pc + 1;
    ax1(pc) = subplot(plotsdown, plotsacross, pc, 'Parent', p);
    plottext = sprintf('Trailing 3 day Median');
    [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');    
    [xl, yl] = plotMeasurementData(ax1(pc), days, movmedian(mdata, [2 0]), xl, yl, plottext, 0, wcolors{pc}, '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
    
    if pnbr == 78
        widthinch = 8.25;
        heightinch = 4.5;
        baseplotname = sprintf('%s - Thesis FEV1 Analysis - Patient %d', studydisplayname, pnbr);
        [f, p] = createFigureAndPanelForPaper('', widthinch, heightinch);

        ax1(pc) = subplot(2, 1, 1, 'Parent', p);
        plottext = sprintf('Raw FEV1%% data');
        [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, '-', 1.0, 'none', 1.0, 'blue', 'green');
        [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');

        ax1(pc) = subplot(2, 1, 2, 'Parent', p);
        plottext = sprintf('Trailing 3 day max filter');
        [xl, yl] = plotMeasurementData(ax1(pc), days, mdata, xl, yl, plottext, 0, rawcolor, ':', 1.0, 'none', 1.0, 'blue', 'green');
        [xl, yl] = plotMeasurementData(ax1(pc), days, interppts, xl, yl, plottext, 0, rawcolor, 'none', 1.0, 'o', 1.0, 'red', 'red');
        [xl, yl] = plotMeasurementData(ax1(pc), days, movmax(mdata, [2 0]), xl, yl, plottext, 0, 'blue', '-', 1.0, 'none', 1.0, 'blue', 'green');

        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f);
    end
end
    