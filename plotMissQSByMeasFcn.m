function plotMissQSByMeasFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
    qsthreshold, fpthreshold, thresh, measures, datawin, baseqcdatasetfile, plotsubfolder, qsmeasure)

% plotMissingnessQSFcn - plots the quality scores vs the %age of missing
% data and also colour by correct vs incorrect result by the missingess
% classifier

widthinch = 7;
heightinch = 5;
name = '';

plotsacross = 1;
plotsdown = 1;

measarray = [{'Overall'};measures.DisplayName(logical(measures.RawMeas))];
fnmeasarray = [{'Ov'};measures.ShortName(logical(measures.RawMeas))];

%if size(measarray, 1) > plotsacross * plotsdown
%    fprintf('Need to increase the number of subplots for the number of measures used in this model run\n');
%    return
%end

ydata = 100 * table2array(pmMissPattQSPct(:, {qsmeasure}));

tpidx  = pmQCModelRes.Pred >= thresh & labels == 1;
fp1idx = pmQCModelRes.Pred >= thresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) >= fpthreshold / 100;
fp2idx = pmQCModelRes.Pred >= thresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) <  fpthreshold / 100;
tnidx  = pmQCModelRes.Pred <  thresh & labels == 0;
fnidx  = pmQCModelRes.Pred <  thresh & labels == 1;

for m = 1:size(measarray, 1)

    meas = measarray{m};
    fnmeas = fnmeasarray{m};

    baseplotname = sprintf('%sfp%d%s%s', baseqcdatasetfile, fpthreshold, qsmeasure, fnmeas);
    [f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
    ax = subplot(plotsdown, plotsacross, 1, 'Parent', p);

    % for overall plot, use full pmMissPattArray to calculate
    % missingness percentage, otherwise, use the subset of columns
    % relevant to the individual measure
    if m == 1
        xdata = sum(pmMissPattArray, 2) * 100 / (datawin * sum(measures.RawMeas));
    else
        xdata = sum(pmMissPattArray(:,(((m-2) * datawin) + 1):((m-1) * datawin)), 2) * 100 / datawin;
    end

    plotMissQSByMeasPlotFcn(ax, xdata, ydata, qsthreshold, fpthreshold, ...
        qsmeasure, meas, tpidx, fp1idx, fp2idx, tnidx, fnidx); 

    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);

end

end

