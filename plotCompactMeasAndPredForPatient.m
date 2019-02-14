function plotCompactMeasAndPredForPatient(pmpatientrow, pabs, pmampredrow, pmRawDatacube, pmInterpDatacube, ...
                pmTrCVFeatureIndex, trcvlabels, pmModelRes, pmOverallStats, pmeasstats, ...
                measures, nmeasures, npred, plotsacross, dbfab, dafab, sp, labelidx, ...
                lbdisplayname, lgtype)
            
% plotCompactMeasAndPredForPatient- compact plots of measures and
% prediction for a patient

plotsperpat = nmeasures + npred;
plotsdown   = ceil(plotsperpat / plotsacross);
     
pnbr      = pmampredrow.PatientNbr;
pmaxdays  = pmpatientrow.LastMeasdn - pmpatientrow.FirstMeasdn + 1;
    
exstart   = pmampredrow.Pred;
ivstart   = pmampredrow.IVScaledDateNum;
pivabsdates = pabs(ismember(pabs.Route, 'IV') & pabs.RelStartdn == ivstart,{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
poralabsdates = pabs(ismember(pabs.Route, 'Oral') & pabs.RelStartdn == ivstart,{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});

dfrom     = ivstart - dbfab;
if dfrom < 1
    dfrom = 1;
end
dto       = ivstart + dafab;
if dto > pmaxdays
    dto = pmaxdays;
end
days      = (dfrom:dto);

ax1 = gobjects(plotsdown * plotsacross,1);
    
for m = 1:nmeasures
        
    mrawdata  = pmRawDatacube(pnbr, dfrom:dto, m);
    mdata     = pmInterpDatacube(pnbr, dfrom:dto, m);
    interppts = mdata;
    interppts(~isnan(mrawdata)) = nan;
    [combinedmask, plottext, left_color, lint_color, right_color, rint_color] = setPlotColorsAndText(measures(m, :));
    xl = [dfrom dto];

    % set min/max y display range to be mean +/- 1 stddev (using patient/
    % measure level stats where they exist, otherwise overall study level
    % stats
    if size(pmeasstats.Mean(pmeasstats.MeasureIndex == m), 1) == 0
        yl = [(pmOverallStats.Mean(m) - pmOverallStats.StdDev(m)) (pmOverallStats.Mean(m) + pmOverallStats.StdDev(m))];
    else
        yl = [(pmeasstats.Mean(pmeasstats.MeasureIndex == m) - pmeasstats.StdDev(pmeasstats.MeasureIndex == m)) ...
              (pmeasstats.Mean(pmeasstats.MeasureIndex == m) + pmeasstats.StdDev(pmeasstats.MeasureIndex == m))];
    end
        
    ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent', sp);
        
    [xl, yl] = plotMeasurementData(ax1(m), days, mdata, xl, yl, plottext, combinedmask, left_color, ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(m), days, smooth(mdata,5), xl, yl, plottext, combinedmask, left_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(m), days, interppts, xl, yl, plottext, combinedmask, left_color, 'none', 1.0, 'o', 1.0, lint_color, lint_color);
        
    hold on;
    if ismember(lgtype, {'TP', 'FN'})
        [xl, yl] = plotVerticalLine(ax1(m), pmampredrow.Pred, xl, yl, 'blue', '-', 1.0);
        plotFillArea(ax1(m), pmampredrow.RelLB1, pmampredrow.RelUB1, yl(1), yl(2), 'blue', 0.1, 'none');
        if pmampredrow.RelLB2 ~= -1
            plotFillArea(ax1(m), pmampredrow.RelLB2, pmampredrow.RelUB2, yl(1), yl(2), 'blue', 0.1, 'none');
        end
    end
    for ab = 1:size(poralabsdates,1)
        plotFillArea(ax1(m), poralabsdates.RelStartdn(ab), dto, yl(1), yl(2), 'yellow', 0.1, 'none');
    end
    for ab = 1:size(pivabsdates,1)
        plotFillArea(ax1(m), pivabsdates.RelStartdn(ab), dto, yl(1), yl(2), 'red', 0.1, 'none');
    end
    hold off;
end
    
% add prediction plots
fidx = (pmTrCVFeatureIndex.PatientNbr == pnbr);
pfeatindex = pmTrCVFeatureIndex(fidx,:);
ppred  = pmModelRes.pmNDayRes(labelidx).Pred(fidx);
plabel = trcvlabels(fidx,labelidx);

ppreddata = nan(1, pmaxdays);
plabeldata = nan(1, pmaxdays);
for d = 1:size(ppred,1)
    ppreddata(pfeatindex.CalcDatedn(d))  = ppred(d);
    plabeldata(pfeatindex.CalcDatedn(d)) = plabel(d);
end
ppreddata = ppreddata(dfrom:dto);
plabeldata = plabeldata(dfrom:dto);

m = m + 1;
ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent', sp);
xlim(xl);
yl = [0 1];
ylim(yl);
plottitle = sprintf('Prediction for %s Labels', lbdisplayname);
[xl, yl] = plotMeasurementData(ax1(m), days, plabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
[xl, yl] = plotMeasurementData(ax1(m), days, ppreddata, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

end

