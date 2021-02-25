function plotMissQSByOutcomeFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, fplabels, ...
    pmQSConstr, opthresh, measures, datawin, baseqcdatasetfile, plotsubfolder)

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

for i = 1:size(pmQSConstr.qsmeasure, 1)
    qsmeasure   = pmQSConstr.qsmeasure{i};
    qsshortname = pmQSConstr.qsshortname{i};
    qsthreshold = pmQSConstr.qsthresh(i);
    fpthresh    = pmQSConstr.fpthresh(i);

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
                tpidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, fplabels, opthresh, 'TP');
            case 'FP1'
                fp1idx = getIndexForOutcome(pmQCModelRes.Pred, labels, fplabels, opthresh, 'FP1');
            case 'FP2'
                fp2idx = getIndexForOutcome(pmQCModelRes.Pred, labels, fplabels, opthresh, 'FP2');
            case 'TN'
                tnidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, fplabels, opthresh, 'TN');
            case 'FN'
                fnidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, fplabels, opthresh, 'FN');
        end

        baseplotname = sprintf('%s%s%s%.3f', baseqcdatasetfile, qsshortname, outcome, opthresh);
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

end

