function plotMissQSByOutcomeFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
    qsthreshold, fpthresh, opthresh, measures, datawin, baseqcdatasetfile, plotsubfolder, qsmeasure)

% plotMissingnessQSFcn - plots the quality scores vs the %age of missing
% data and also colour by correct vs incorrect result by the missingess
% classifier

widthinch = 8.5;
heightinch = 11;
name = '';
showlegend = false;

plotsacross = 2;
plotsdown = 3;

ocarray = {'TP', 'FP1', 'FP2', 'TN', 'FN'};
measarray = [{'Overall'};measures.DisplayName(logical(measures.RawMeas))];

ydata = 100 * table2array(pmMissPattQSPct(:, {qsmeasure}));

for oc = 1:size(ocarray, 2)
    outcome = ocarray{oc};
    %ocidx = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, outcome);
    

    tpidx  = false(size(labels, 1), 1);
    fp1idx = false(size(labels, 1), 1);
    fp2idx = false(size(labels, 1), 1);
    tnidx  = false(size(labels, 1), 1);
    fnidx  = false(size(labels, 1), 1);
    
    switch outcome
        case 'TP'
            tpidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'TP');
        case 'FP1'
            fp1idx = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'FP1');
        case 'FP2'
            fp2idx = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'FP2');
        case 'TN'
            tnidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'TN');
        case 'FN'
            fnidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'FN');
    end
    
    baseplotname = sprintf('%s%s%s', baseqcdatasetfile, qsmeasure, outcome);
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

        plotMissQSByMeasPlotFcn(ax, xdata, ydata, qsthreshold, fpthresh, ...
            qsmeasure, meas, tpidx, fp1idx, fp2idx, tnidx, fnidx, outcome, showlegend); 

    end

    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
end

end

