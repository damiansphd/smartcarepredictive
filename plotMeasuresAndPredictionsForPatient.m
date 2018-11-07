function plotMeasuresAndPredictionsForPatient(patientrow, pabs, prawdata, pinterpdata, ...
    pmFeatureIndex, pmIVLabels, pmExLabels, pmModelRes, pmOverallStats, pmeasstats, measures, ...
    nmeasures, labelidx, pmFeatureParamsRow, pmModelParamsRow,  plotsubfolder, basefilename)

% plotMeasuresAndPredictions - for a given patient, plot the measures along
% with the predictions from the predictive classification model and the 
% true labels.

patientnbr = patientrow.PatientNbr;

plotsacross = 1;
plotsdown = nmeasures + 1;

baseplotname1 = sprintf('%s - %d Day Prediction - Patient %d (Study %s, ID %d)', basefilename, labelidx, patientnbr, patientrow.Study{1}, patientrow.ID);

[f1,p1] = createFigureAndPanel(baseplotname1, 'Portrait', 'A4');

pivabsdates = pabs(ismember(pabs.Route, 'IV'),{'Startdn','Stopdn'});
for ab = 1:size(pivabsdates,1)
    if pivabsdates.Startdn(ab) < patientrow.FirstMeasdn
        pivabsdates.Startdn(ab) = patientrow.FirstMeasdn;
    end
    if pivabsdates.Stopdn(ab) > patientrow.LastMeasdn
        pivabsdates.Stopdn(ab) = patientrow.LastMeasdn;
    end
end

poralabsdates = pabs(ismember(pabs.Route, 'Oral'),{'Startdn','Stopdn'});
for ab = 1:size(poralabsdates,1)
    if poralabsdates.Startdn(ab) < patientrow.FirstMeasdn
        poralabsdates.Startdn(ab) = patientrow.FirstMeasdn;
    end
    if poralabsdates.Stopdn(ab) > patientrow.LastMeasdn
        poralabsdates.Stopdn(ab) = patientrow.LastMeasdn;
    end
end

pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;
fidx = (pmFeatureIndex.PatientNbr == patientnbr);
pfeatindex = pmFeatureIndex(fidx,:);
ppred = pmModelRes.pmLabel(labelidx).Pred(fidx);

if pmModelParamsRow.labelmethod == 1
    plabel = pmIVLabels(fidx,labelidx);
elseif pmModelParamsRow.labelmethod == 2
    plabel = pmExLabels(fidx,labelidx);
else
    fprintf('Unknown label method\n');
end

ppreddata = nan(1, pmaxdays);
plabeldata = nan(1, pmaxdays);
for d = 1:size(ppred,1)
    ppreddata(pfeatindex.CalcDatedn(d))  = ppred(d);
    plabeldata(pfeatindex.CalcDatedn(d)) = plabel(d);
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
        plotFillArea(ax1(m), poralabsdates.Startdn(ab) - patientrow.FirstMeasdn, poralabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'yellow', 0.1, 'none');
        hold off;
    end
    
    for ab = 1:size(pivabsdates,1)
        hold on;
        plotFillArea(ax1(m), pivabsdates.Startdn(ab) - patientrow.FirstMeasdn, pivabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
 
end

m = nmeasures + 1;

ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
xlim(xl);
yl = [0 1];
ylim(yl);
[xl, yl] = plotMeasurementData(ax1(m), days, plabeldata, xl, yl, 'Prediction and Label', 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
[xl, yl] = plotMeasurementData(ax1(m), days, ppreddata, xl, yl, 'Prediction and Label', 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

for ab = 1:size(poralabsdates,1)
    hold on;
    plotFillArea(ax1(m), poralabsdates.Startdn(ab) - patientrow.FirstMeasdn, poralabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'yellow', 0.1, 'none');
    hold off;
end

for ab = 1:size(pivabsdates,1)
    hold on;
    plotFillArea(ax1(m), pivabsdates.Startdn(ab) - patientrow.FirstMeasdn, pivabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
    hold off;
end

basedir = setBaseDir();
savePlotInDir(f1, baseplotname1, basedir, plotsubfolder);
close(f1);

predictionduration = pmFeatureParamsRow.predictionduration;
plotsacross = 1;
plotsdown = predictionduration;

baseplotname2 = sprintf('%s - All Predictions - Patient %d (Study %s, ID %d)', basefilename, patientnbr, patientrow.Study{1}, patientrow.ID);
[f2,p2] = createFigureAndPanel(baseplotname2, 'Portrait', 'A4');

for n = 1:predictionduration
    ppred = pmModelRes.pmLabel(n).Pred(fidx);
    if pmModelParamsRow.labelmethod == 1
        plabel = pmIVLabels(fidx, n);
    elseif pmModelParamsRow.labelmethod == 2
        plabel = pmExLabels(fidx, n);
    else
        fprintf('Unknown label method\n');
    end

    ppreddata = nan(1, pmaxdays);
    plabeldata = nan(1, pmaxdays);

    for d = 1:size(ppred,1)
        ppreddata(pfeatindex.CalcDatedn(d))  = ppred(d);
        plabeldata(pfeatindex.CalcDatedn(d)) = plabel(d);
    end

    ax2(n) = subplot(plotsdown, plotsacross, n, 'Parent',p2);
    xlim(xl);
    yl = [0 1];
    ylim(yl);
    plottitle = sprintf('%d Day Prediction and Label', n);
    [xl, yl] = plotMeasurementData(ax2(n), days, plabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax2(n), days, ppreddata,  xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

    for ab = 1:size(poralabsdates,1)
        hold on;
        plotFillArea(ax2(n), poralabsdates.Startdn(ab) - patientrow.FirstMeasdn, poralabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'yellow', 0.1, 'none');
        hold off;
    end
    
    for ab = 1:size(pivabsdates,1)
        hold on;
        plotFillArea(ax2(n), pivabsdates.Startdn(ab) - patientrow.FirstMeasdn, pivabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    
end

basedir = setBaseDir();
savePlotInDir(f2, baseplotname2, basedir, plotsubfolder);
close(f2);


end

