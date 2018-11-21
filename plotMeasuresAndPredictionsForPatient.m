function plotMeasuresAndPredictionsForPatient(patientrow, pabs, pexsts, prawdata, pinterpdata, ...
    pmFeatureIndex, pmIVLabels, pmExLabels, pmIVModelRes, pmExModelRes, pmOverallStats, ...
    pmeasstats, measures, nmeasures, labelidx, pmFeatureParamsRow, plotsubfolder, basefilename)

% plotMeasuresAndPredictions - for a given patient, plot the measures along
% with the predictions from the predictive classification model and the 
% true labels.

patientnbr = patientrow.PatientNbr;
pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;

plotsacross = 1;
plotsdown = nmeasures + 2;

baseplotname1 = sprintf('%s - %d Day Prediction - Patient %d (Study %s, ID %d)', basefilename, labelidx, patientnbr, patientrow.Study{1}, patientrow.ID);

[f1,p1] = createFigureAndPanel(baseplotname1, 'Portrait', 'A4');

pivabsdates = pabs(ismember(pabs.Route, 'IV'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
for ab = 1:size(pivabsdates,1)
    if pivabsdates.Startdn(ab) < patientrow.FirstMeasdn
        pivabsdates.Startdn(ab)    = patientrow.FirstMeasdn;
        pivabsdates.RelStartdn(ab) = 1;
    end
    if pivabsdates.Stopdn(ab) > patientrow.LastMeasdn
        pivabsdates.Stopdn(ab)    = patientrow.LastMeasdn;
        pivabsdates.RelStopdn(ab) = pmaxdays;
    end
end

poralabsdates = pabs(ismember(pabs.Route, 'Oral'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
for ab = 1:size(poralabsdates,1)
    if poralabsdates.Startdn(ab) < patientrow.FirstMeasdn
        poralabsdates.Startdn(ab)    = patientrow.FirstMeasdn;
        poralabsdates.RelStartdn(ab) = 1;
    end
    if poralabsdates.Stopdn(ab) > patientrow.LastMeasdn
        poralabsdates.Stopdn(ab)    = patientrow.LastMeasdn;
        poralabsdates.RelStopdn(ab) = pmaxdays;
    end
end

pexstsdates = pexsts(:, {'IVStartDate', 'IVDateNum', 'Offset', 'Ex_Start', ...
    'LowerBound1', 'UpperBound1', 'LowerBound2', 'UpperBound2', ...
    'Pred', 'RelLB1', 'RelUB1', 'RelLB2', 'RelUB2'});

fidx = (pmFeatureIndex.PatientNbr == patientnbr);
pfeatindex = pmFeatureIndex(fidx,:);
pivpred  = pmIVModelRes.pmNDayRes(labelidx).Pred(fidx);
pivlabel = pmIVLabels(fidx,labelidx);
pexpred  = pmExModelRes.pmNDayRes(labelidx).Pred(fidx);
pexlabel = pmExLabels(fidx,labelidx);

pivpreddata = nan(1, pmaxdays);
pivlabeldata = nan(1, pmaxdays);
for d = 1:size(pivpred,1)
    pivpreddata(pfeatindex.CalcDatedn(d))  = pivpred(d);
    pivlabeldata(pfeatindex.CalcDatedn(d)) = pivlabel(d);
end
pexpreddata = nan(1, pmaxdays);
pexlabeldata = nan(1, pmaxdays);
for d = 1:size(pexpred,1)
    pexpreddata(pfeatindex.CalcDatedn(d))  = pexpred(d);
    pexlabeldata(pfeatindex.CalcDatedn(d)) = pexlabel(d);
end

for m = 1:nmeasures
    
    days = (1:pmaxdays);
    mrawdata = prawdata(1, 1:pmaxdays, m);
    mdata = pinterpdata(1, 1:pmaxdays, m);
    interppts = mdata;
    interppts(~isnan(mrawdata)) = nan;
    
    xl = [1 pmaxdays];
    
    % relevant if plotting normalised data
    %if min(mdata) == max(mdata)
    %    if min(mdata) < 0
    %        yl = [min(mdata) * 1.01 min(mdata) * 0.99];
    %    elseif min(mdata) > 0
    %        yl = [min(mdata) * 0.99 min(mdata) * 1.01];
    %    else
    %        yl = [-0.01 0.01];
    %    end
    %else
    %    yl = [min(mdata) max(mdata)];
    %end
    
    % relevant if plotting actual data
    % set minimum y display range to be mean +/- 1 stddev (using patient/
    % measure level stats where they exist, otherwise overall study level
    % stats
    if size(pmeasstats.Mean(pmeasstats.MeasureIndex == m), 1) == 0
        yl = [(pmOverallStats.Mean(m) - pmOverallStats.StdDev(m)) (pmOverallStats.Mean(m) + pmOverallStats.StdDev(m))];
    else
        yl = [(pmeasstats.Mean(pmeasstats.MeasureIndex == m) - pmeasstats.StdDev(pmeasstats.MeasureIndex == m)) ...
            (pmeasstats.Mean(pmeasstats.MeasureIndex == m) + pmeasstats.StdDev(pmeasstats.MeasureIndex == m))];
    end
    
    ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
    
    [xl, yl] = plotMeasurementData(ax1(m), days, mdata, xl, yl, measures.DisplayName(m), measures.Mask(m), [0, 0.65, 1], ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(m), days, smooth(mdata,5), xl, yl, measures.DisplayName(m), measures.Mask(m), [0, 0.65, 1], '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    [xl, yl] = plotMeasurementData(ax1(m), days, interppts, xl, yl, measures.DisplayName(m), measures.Mask(m), [0, 0.65, 1], 'none', 1.0, 'o', 1.0, 'red', 'red');
    
    for ab = 1:size(poralabsdates,1)
        hold on;
        plotFillArea(ax1(m), poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
        hold off;
    end
    
    for ab = 1:size(pivabsdates,1)
        hold on;
        plotFillArea(ax1(m), pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    
    for ex = 1:size(pexstsdates, 1)
        hold on;
        [xl, yl] = plotVerticalLine(ax1(m), pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
        plotFillArea(ax1(m), pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        if pexstsdates.RelLB2(ex) ~= -1
            plotFillArea(ax1(m), pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        end
    end
end

% Predictions for IV Labels
m = nmeasures + 1;
ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
xlim(xl);
yl = [0 1];
ylim(yl);
plottitle = sprintf('%d Day Prediction for IV Labels', labelidx);
[xl, yl] = plotMeasurementData(ax1(m), days, pivlabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
[xl, yl] = plotMeasurementData(ax1(m), days, pivpreddata, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

for ab = 1:size(poralabsdates, 1)
    hold on;
    plotFillArea(ax1(m), poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
    hold off;
end
for ab = 1:size(pivabsdates, 1)
    hold on;
    plotFillArea(ax1(m), pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
    hold off;
end

% Predictions for Ex_Start Labels
m = nmeasures + 2;
ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
xlim(xl);
yl = [0 1];
ylim(yl);
plottitle = sprintf('%d Day Prediction for Exacerbation Start Labels', labelidx);
[xl, yl] = plotMeasurementData(ax1(m), days, pexlabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
[xl, yl] = plotMeasurementData(ax1(m), days, pexpreddata, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

for ex = 1:size(pexstsdates, 1)
    hold on;
    [xl, yl] = plotVerticalLine(ax1(m), pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
    plotFillArea(ax1(m), pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
    if pexstsdates.RelLB2(ex) ~= -1
        plotFillArea(ax1(m), pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
    end
end

basedir = setBaseDir();
savePlotInDir(f1, baseplotname1, basedir, plotsubfolder);
close(f1);

predictionduration = pmFeatureParamsRow.predictionduration;
plotsacross = 1;
plotsdown = predictionduration;

baseplotname2 = sprintf('%s - All IV Predictions - Patient %d (Study %s, ID %d)', basefilename, patientnbr, patientrow.Study{1}, patientrow.ID);
[f2,p2] = createFigureAndPanel(baseplotname2, 'Portrait', 'A4');

for n = 1:predictionduration
    pivpred  = pmIVModelRes.pmNDayRes(n).Pred(fidx);
    pivlabel = pmIVLabels(fidx, n);
    
    pivpreddata = nan(1, pmaxdays);
    pivlabeldata = nan(1, pmaxdays);

    for d = 1:size(pivpred,1)
        pivpreddata(pfeatindex.CalcDatedn(d))  = pivpred(d);
        pivlabeldata(pfeatindex.CalcDatedn(d)) = pivlabel(d);
    end

    ax2(n) = subplot(plotsdown, plotsacross, n, 'Parent',p2);
    xlim(xl);
    yl = [0 1];
    ylim(yl);
    plottitle = sprintf('%d Day Prediction for IV Labels', n);
    [xl, yl] = plotMeasurementData(ax2(n), days, pivlabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax2(n), days, pivpreddata,  xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

    for ab = 1:size(poralabsdates,1)
        hold on;
        plotFillArea(ax2(n), poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
        hold off;
    end
    
    for ab = 1:size(pivabsdates,1)
        hold on;
        plotFillArea(ax2(n), pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    
end

basedir = setBaseDir();
savePlotInDir(f2, baseplotname2, basedir, plotsubfolder);
close(f2);

baseplotname3 = sprintf('%s - All Ex Start Predictions - Patient %d (Study %s, ID %d)', basefilename, patientnbr, patientrow.Study{1}, patientrow.ID);
[f3,p3] = createFigureAndPanel(baseplotname3, 'Portrait', 'A4');

for n = 1:predictionduration
    pexpred  = pmExModelRes.pmNDayRes(n).Pred(fidx);
    pexlabel = pmExLabels(fidx, n);
    
    pexpreddata = nan(1, pmaxdays);
    pexlabeldata = nan(1, pmaxdays);

    for d = 1:size(pivpred,1)
        pexpreddata(pfeatindex.CalcDatedn(d))  = pexpred(d);
        pexlabeldata(pfeatindex.CalcDatedn(d)) = pexlabel(d);
    end

    ax3(n) = subplot(plotsdown, plotsacross, n, 'Parent', p3);
    xlim(xl);
    yl = [0 1];
    ylim(yl);
    plottitle = sprintf('%d Day Prediction for Exacerbation Start Labels', n);
    [xl, yl] = plotMeasurementData(ax3(n), days, pexlabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax3(n), days, pexpreddata,  xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

    for ex = 1:size(pexstsdates, 1)
        hold on;
        [xl, yl] = plotVerticalLine(ax3(n), pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
        plotFillArea(ax3(n), pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        if pexstsdates.RelLB2(ex) ~= -1
            plotFillArea(ax3(n), pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        end
    end    
end

basedir = setBaseDir();
savePlotInDir(f3, baseplotname3, basedir, plotsubfolder);
close(f3);

end

