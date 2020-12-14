function plotMissingnessQSFcn(pmQCModelRes, pmMissPattIndex, pmMissPattQSPct, labels, ...
    qsthreshold, fpthresh, opthresh, basemsresultsfile, plotsubfolder)

% plotMissingnessQSFcn - plots the quality scores vs the %age of missing
% data and also colour by correct vs incorrect result by the missingess
% classifier

widthinch = 7;
heightinch = 5;
name = '';
plotsacross = 1;
plotsdown = 1;

qsarray = {'AvgEPV', 'PRAUC', 'ROCAUC', 'Acc', 'PosAcc'};
meas = 'Overall';
outcome = 'All';
showlegend = true;

xdata = pmMissPattIndex.MSPct;

for i = 1:size(qsarray, 2)
    
    qsmeasure = qsarray{i};
    
    [tpidx, ~, fp1idx, fp2idx, tnidx, fnidx] = getIndicesForAllOutcomes(pmQCModelRes.Pred, ...
            labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh);
    
    baseplotname1 = sprintf('%s%s', basemsresultsfile, qsmeasure);
    [f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
    ax = subplot(plotsdown, plotsacross, 1, 'Parent', p);
    
    ydata = 100 * table2array(pmMissPattQSPct(:, {qsmeasure}));
    
    plotMissQSByMeasPlotFcn(ax, xdata, ydata, qsthreshold, fpthresh, ...
            qsmeasure, meas, tpidx, fp1idx, fp2idx, tnidx, fnidx, outcome, showlegend); 
    
    basedir = setBaseDir();
    savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
    close(f);
end 

end

