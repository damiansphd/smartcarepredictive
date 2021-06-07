function plotDWMeasuresAndPredictionsForPatient(patientrow, pabs, pexsts, prawdata, pinterpdata, pinterpvoldata, ...
    testfeatidx, testlabels, pmModelRes, pmOverallStats, ...
    pmeasstats, measures, nmeasures, mvolstats, labelidx, pmFeatureParamsRow, ...
    lbdisplayname, plotsubfolder, basefilename)

% plotDWMeasuresAndPredictionsForPatient - for a given patient, plot the measures along
% with the predictions from the predictive classification model and the 
% true labels.

basedir = setBaseDir();

smfn       = pmFeatureParamsRow.smfunction;
smwin      = pmFeatureParamsRow.smwindow;
smln       = pmFeatureParamsRow.smlength;
normwindow = pmFeatureParamsRow.normwinduration;

patientnbr = patientrow.PatientNbr;
pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;

if ismember(pmFeatureParamsRow.StudyDisplayName, {'BR', 'CL'})
    mfev1idx = measures.Index(ismember(measures.DisplayName, 'FEV1'));
else
    mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));
end

baseplotname1 = sprintf('%s-%s%dDPredP%d(%s%d)', ...
    basefilename, lbdisplayname, labelidx, patientnbr, patientrow.Study{1}, patientrow.ID);

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

fidx = (testfeatidx.PatientNbr == patientnbr & testfeatidx.ScenType == 0);
pfeatindex = testfeatidx(fidx,:);
ppred  = pmModelRes.pmNDayRes(labelidx).Pred(fidx);
plabel = testlabels(fidx,labelidx);

ppreddata = nan(1, pmaxdays);
plabeldata = nan(1, pmaxdays);
for d = 1:size(ppred,1)
    ppreddata(pfeatindex.CalcDatedn(d))  = ppred(d);
    plabeldata(pfeatindex.CalcDatedn(d)) = plabel(d);
end

plotsacross = 1;
plotsdown   = 10;
perioddays  = 300;
nperiods    = ceil(pmaxdays / perioddays);
npages      = ceil((nmeasures + 1) / plotsdown);

for period = 1:nperiods
    
    dfrom = (period - 1) * perioddays + 1;
    dto   = period * perioddays;
    pdto  = dto;
    if dto > pmaxdays
        dto = pmaxdays;
    end
    if period == 1
        vdo = normwindow + 1;
    else
        vdo = 1;
    end
    xl = [dfrom pdto];
    
    page = 1;
    thisplot = 1;
    plotname = sprintf('%s-M%dof%d(%d_%d)', baseplotname1, page, npages, dfrom, dto);
    [f1,p1] = createFigureAndPanel(plotname, 'Portrait', 'A4');
    left_color = [0, 0.65, 1];
    right_color = [0.13, 0.55, 0.13];
    set(f1,'defaultAxesColorOrder',[left_color; right_color]);

    for m = 1:nmeasures

        
        midx       = measures.Index(m);
        days       = (dfrom:dto);
        mrawdata   = prawdata(1, dfrom:dto, m);
        mdata      = pinterpdata(1, dfrom:dto, m);
        vdata      = pinterpvoldata(1, dfrom:dto, m);
        interppts  = mdata;
        interppts(~isnan(mrawdata)) = nan;
        intervppts = vdata;
        intervppts(~isnan(mrawdata)) = nan;
        [combinedmask, plottext, left_color, lint_color, right_color, rint_color] = setDWPlotColorsAndText(measures(m, :));
        
        % raw measures - capture overall min/max range based on all study data
        ovyl = [min(pinterpdata(1, :, m)) * 0.95, max(pinterpdata(1, :, m)) * 1.05];

        % set minimum y display range to be mean +/- 1 stddev (using patient/
        % measure level stats where they exist, otherwise overall study level
        % stats
        if size(pmeasstats.Mean(pmeasstats.MeasureIndex == midx), 1) == 0
            defyl = [(pmOverallStats.Mean(pmOverallStats.MeasureIndex == midx) - pmOverallStats.StdDev(pmOverallStats.MeasureIndex == midx)), ...
                (pmOverallStats.Mean(pmOverallStats.MeasureIndex == midx) + pmOverallStats.StdDev(pmOverallStats.MeasureIndex == midx))];
        else
            defyl = [(pmeasstats.Mean(pmeasstats.MeasureIndex == midx) - pmeasstats.StdDev(pmeasstats.MeasureIndex == midx)) ...
                (pmeasstats.Mean(pmeasstats.MeasureIndex == midx) + pmeasstats.StdDev(pmeasstats.MeasureIndex == midx))];
        end

        yl = [min(ovyl(1), defyl(1)), max(ovyl(2), defyl(2))];
        
        ax1(thisplot) = subplot(plotsdown, plotsacross, thisplot, 'Parent',p1);
        yyaxis(ax1(thisplot),'left');

        if ~all(isnan(mdata))
            [~, yl] = plotMeasurementData(ax1(thisplot), days, mdata, xl, yl, plottext, combinedmask, left_color, ':', 1.0, 'none', 1.0, 'blue', 'green');
            %[xl, yl] = plotMeasurementData(ax1(thisplot), days, smooth(mdata,5), xl, yl, plottext, combinedmask, left_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
            [~, yl] = plotMeasurementData(ax1(thisplot), days, applySmoothMethodToInterpRow(mdata, smfn, smwin, smln, measures.Index(m), mfev1idx), xl, yl, plottext, combinedmask, left_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
            [~, yl] = plotMeasurementData(ax1(thisplot), days, interppts, xl, yl, plottext, combinedmask, left_color, 'none', 1.0, 'o', 1.0, lint_color, lint_color);
        end
        
        for ab = 1:size(poralabsdates,1)
            hold on;
            plotFillArea(ax1(thisplot), poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
            hold off;
        end

        for ab = 1:size(pivabsdates,1)
            hold on;
            plotFillArea(ax1(thisplot), pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
            hold off;
        end

        for ex = 1:size(pexstsdates, 1)
            hold on;
            [~, yl] = plotVerticalLine(ax1(thisplot), pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
            plotFillArea(ax1(thisplot), pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
            if pexstsdates.RelLB2(ex) ~= -1
                plotFillArea(ax1(thisplot), pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
            end
        end

        % vol data - capture overall min/max range based on all study data
        ovyl2 = [min(pinterpvoldata(1, :, m)) * 0.95, max(pinterpvoldata(1, :, m)) * 1.05];
        defyl2 = [0 mvolstats(measures.Index(m), 6)];
        
        yl2 = [min(ovyl2(1), defyl2(1)), max(ovyl2(2), defyl2(2))];
        
        yyaxis(ax1(thisplot),'right');
        
        if ~all(isnan(vdata(vdo:end)))
            [~, yl2] = plotMeasurementData(ax1(thisplot), days(vdo:end), vdata(vdo:end), xl, yl2, plottext, combinedmask, right_color, ':', 1.0, 'none', 1.0, 'blue', 'green');
            [~, yl2] = plotMeasurementData(ax1(thisplot), days(vdo:end), smooth(vdata(vdo:end),5), xl, yl2, plottext, combinedmask, right_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
            [~, yl2] = plotMeasurementData(ax1(thisplot), days(vdo:end), intervppts(vdo:end), xl, yl2, plottext, combinedmask, right_color, 'none', 1.0, 'o', 1.0, rint_color, rint_color);
        end
        
        xlim(ax1(thisplot), xl);
        
        thisplot = thisplot + 1;
        if thisplot > plotsdown
            savePlotInDir(f1, plotname, basedir, plotsubfolder);
            close(f1);
            thisplot = 1;
            page = page + 1;
            plotname = sprintf('%s-M%dof%d(%d_%d)', baseplotname1, page, npages, dfrom, dto);
            [f1,p1] = createFigureAndPanel(plotname, 'Portrait', 'A4');
            left_color = [0, 0.65, 1];
            right_color = [0.13, 0.55, 0.13];
            set(f1,'defaultAxesColorOrder',[left_color; right_color]);
        end
    end

    % Predictions for Labels
    
    ax1(thisplot) = subplot(plotsdown, plotsacross, thisplot, 'Parent',p1);
    yl = [0 1];
    ylim(yl);
    plottitle = sprintf('%d Day Prediction for %s Labels', labelidx, lbdisplayname);
    [~, yl] = plotMeasurementData(ax1(thisplot), days, plabeldata(dfrom:dto), xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
    [~, yl] = plotMeasurementData(ax1(thisplot), days, ppreddata(dfrom:dto), xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

    for ab = 1:size(poralabsdates, 1)
        hold on;
        plotFillArea(ax1(thisplot), poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
        hold off;
    end
    for ab = 1:size(pivabsdates, 1)
        hold on;
        plotFillArea(ax1(thisplot), pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    for ex = 1:size(pexstsdates, 1)
        hold on;
        [~, yl] = plotVerticalLine(ax1(thisplot), pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
        plotFillArea(ax1(thisplot), pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        if pexstsdates.RelLB2(ex) ~= -1
            plotFillArea(ax1(thisplot), pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
        end
    end
    
    xlim(ax1(thisplot), xl);
    
    basedir = setBaseDir();
    savePlotInDir(f1, plotname, basedir, plotsubfolder);
    close(f1);

end


end

