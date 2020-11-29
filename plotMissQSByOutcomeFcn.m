function plotMissQSByOutcomeFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
    qsthreshold, fpthreshold, thresh, measures, datawin, baseqcdatasetfile, plotsubfolder, qsmeasure)

% plotMissingnessQSFcn - plots the quality scores vs the %age of missing
% data and also colour by correct vs incorrect result by the missingess
% classifier

widthinch = 8.5;
heightinch = 11;
name = '';

plotsacross = 2;
plotsdown = 3;

ocarray = {'TP', 'FP1', 'FP2', 'TN', 'FN'};
measarray = [{'Overall'};measures.DisplayName(logical(measures.RawMeas))];

ydata = 100 * table2array(pmMissPattQSPct(:, {qsmeasure}));

for oc = 1:size(ocarray, 2)
    outcome = ocarray{oc};

    tpidx  = false(size(labels, 1), 1);
    fp1idx = false(size(labels, 1), 1);
    fp2idx = false(size(labels, 1), 1);
    tnidx  = false(size(labels, 1), 1);
    fnidx  = false(size(labels, 1), 1);
    switch outcome
        case 'TP'
            tpidx  = pmQCModelRes.Pred >= thresh & labels == 1;
        case 'FP1'
            fp1idx = pmQCModelRes.Pred >= thresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) >= fpthreshold / 100;
        case 'FP2'
            fp2idx = pmQCModelRes.Pred >= thresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) <  fpthreshold / 100;
        case 'TN'
            tnidx  = pmQCModelRes.Pred <  thresh & labels == 0;
        case 'FN'
            fnidx  = pmQCModelRes.Pred <  thresh & labels == 1;
    end
    
    baseplotname = sprintf('%sfp%d%s%s', baseqcdatasetfile, fpthreshold, qsmeasure, outcome);
    [f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

    for m = 1:size(measarray, 1)
        meas = measarray{m};
        
        ax = subplot(plotsdown, plotsacross, m, 'Parent', p);

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

    end

    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
end

end

