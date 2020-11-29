function plotMissingnessQSFcn(pmQCModelRes, pmMissPattIndex, pmMissPattQSPct, labels, ...
    qsthreshold, fpthreshold, thresh, basemsresultsfile, plotsubfolder)

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

xdata = pmMissPattIndex.MSPct;

for i = 1:size(qsarray, 2)
    
    qsmeasure = qsarray{i};
    
    tpidx  = pmQCModelRes.Pred >= thresh & labels == 1;
    fp1idx = pmQCModelRes.Pred >= thresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) >= fpthreshold / 100;
    fp2idx = pmQCModelRes.Pred >= thresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) <  fpthreshold / 100;
    tnidx  = pmQCModelRes.Pred <  thresh & labels == 0;
    fnidx  = pmQCModelRes.Pred <  thresh & labels == 1;
    
    baseplotname1 = sprintf('%sfp%d%s', basemsresultsfile, fpthreshold, qsmeasure);
    [f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
    ax = subplot(plotsdown, plotsacross, 1, 'Parent', p);
    
    ydata = 100 * table2array(pmMissPattQSPct(:, {qsmeasure}));
    
    plotMissQSByMeasPlotFcn(ax, xdata, ydata, qsthreshold, fpthreshold, ...
            qsmeasure, meas, tpidx, fp1idx, fp2idx, tnidx, fnidx); 
    
    basedir = setBaseDir();
    savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
    close(f);
end 

end

