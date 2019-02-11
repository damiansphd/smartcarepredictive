function [pmampred] = plotBestAndWorstPred(pmPatients, pmAntibiotics, pmampred, pmRawDatacube, pmInterpDatacube, ...
                pmTrCVPatientSplit, pmTrCVFeatureIndex, trcvlabels, pmModelRes, pmOverallStats, pmPatientMeasStats, ...
                measures, nmeasures, labelidx, pmFeatureParamsRow, ...
                lbdisplayname, plotsubfolder, basefilename)
            
% plotBestAndWorstPred - compact plots of measures and prediction for the
% best and worst results

ninterventions = size(pmampred,1);
pmampred.SplitNbr(:) = -1.0;
pmampred.IntrDuration(:) = -1.0;
pmampred.MeanPred(:) = -1.0;
pmampred.MedianPred(:) = -1.0;
pmampred.MaxPred(:) = -1.0;
pmampred.MaxPredDay(:) = -1.0;

for i = 1:ninterventions
    pnbr = pmampred.PatientNbr(i);
    exstart = pmampred.Pred(i);
    ivstart = pmampred.IVScaledDateNum(i);
    intridx = pmTrCVFeatureIndex.PatientNbr == pnbr & pmTrCVFeatureIndex.CalcDatedn >= exstart & pmTrCVFeatureIndex.CalcDatedn < ivstart;
    if sum(intridx) ~= 0
        pmampred.SplitNbr(i) = pmTrCVPatientSplit.SplitNbr(pmTrCVPatientSplit.PatientNbr == pnbr);
        pmampred.IntrDuration(i) = ivstart - exstart;
        pmampred.MeanPred(i) = mean(pmModelRes.pmNDayRes(labelidx).Pred(intridx));
        pmampred.MedianPred(i) = median(pmModelRes.pmNDayRes(labelidx).Pred(intridx));
        [pmampred.MaxPred(i), pmampred.MaxPredDay(i)] = max(pmModelRes.pmNDayRes(labelidx).Pred(intridx));
    end
end

pmampred(pmampred.MeanPred == -1,:) = [];

patperpage  = 3;
npred       = 1;
plotsperpat = nmeasures + npred;
plotsacross = 4;
plotsdown   = ceil(plotsperpat / plotsacross);
npat        = ceil(size(pmampred,1) * 0.2);
%npat        = 4;
npages      = ceil(npat/patperpage);
cpage       = 1;
cpat        = 1;
bcolors     = [0.88, 0.88, 0.88; 0.95, 0.95, 0.95; 0.88, 0.88, 0.88];

% 1) best results where there should be a prediction
baseplotname = sprintf('%s - Best Predictions - Page %d of %d', basefilename, cpage, npages);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');

pmampred = sortrows(pmampred, {'MaxPred'}, 'descend');

for i = 1:npat      
    pnbr      = pmampred.PatientNbr(i);
    pmaxdays  = pmPatients.LastMeasdn(pmPatients.PatientNbr == pnbr) - pmPatients.FirstMeasdn(pmPatients.PatientNbr == pnbr) + 1;
    pmeasstats = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:);
    
    exstart   = pmampred.Pred(i);
    ivstart   = pmampred.IVScaledDateNum(i);
    pivabsdates = pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & ismember(pmAntibiotics.Route, 'IV') & pmAntibiotics.RelStartdn == ivstart,{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    poralabsdates = pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & ismember(pmAntibiotics.Route, 'Oral') & pmAntibiotics.RelStartdn == ivstart,{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    dbfab     = 28;
    dafab     = 2;
    dfrom     = ivstart - dbfab;
    if dfrom < 1
        dfrom = 1;
    end
    dto       = ivstart + dafab;
    if dto > pmaxdays
        dto = pmaxdays;
    end
    days      = (dfrom:dto);
    
    uipypos = 1 - cpat/patperpage;
    uipysz  = 1/patperpage;
    uiptitle = sprintf('Patient %d', pnbr);
    sp(cpat) = uipanel('Parent', p, ...
                  'BorderType', 'none', 'BackgroundColor', bcolors(cpat,:), ...
                  'OuterPosition', [0.0,uipypos, 1.0, uipysz], ...
                  'Title', uiptitle, 'TitlePosition', 'centertop', 'FontSize', 8);
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
        
        ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent', sp(cpat));
        
        [xl, yl] = plotMeasurementData(ax1(m), days, mdata, xl, yl, plottext, combinedmask, left_color, ':', 1.0, 'none', 1.0, 'blue', 'green');
        [xl, yl] = plotMeasurementData(ax1(m), days, smooth(mdata,5), xl, yl, plottext, combinedmask, left_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
        [xl, yl] = plotMeasurementData(ax1(m), days, interppts, xl, yl, plottext, combinedmask, left_color, 'none', 1.0, 'o', 1.0, lint_color, lint_color);
        
        hold on;
        [xl, yl] = plotVerticalLine(ax1(m), pmampred.Pred(i), xl, yl, 'blue', '-', 1.0);
        plotFillArea(ax1(m), pmampred.RelLB1(i), pmampred.RelUB1(i), yl(1), yl(2), 'blue', 0.1, 'none');
        if pmampred.RelLB2(i) ~= -1
            plotFillArea(ax1(m), pmampred.RelLB2(i), pmampred.RelUB2(i), yl(1), yl(2), 'blue', 0.1, 'none');
        end
        for ab = 1:size(poralabsdates,1)
            plotFillArea(ax1(m), poralabsdates.RelStartdn(ab), dto, yl(1), yl(2), 'yellow', 0.1, 'none');
        end
        for ab = 1:size(pivabsdates,1)
            plotFillArea(ax1(m), pivabsdates.RelStartdn(ab), dto, yl(1), yl(2), 'red', 0.1, 'none');
        end
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
    ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent', sp(cpat));
    xlim(xl);
    yl = [0 1];
    ylim(yl);
    plottitle = sprintf('Prediction for %s Labels', lbdisplayname);
    [xl, yl] = plotMeasurementData(ax1(m), days, plabeldata, xl, yl, plottitle, 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax1(m), days, ppreddata, xl, yl, plottitle, 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');

    cpat = cpat + 1;
    
    if (i == npat)
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f); 
    elseif ((cpat - 1) == patperpage) 
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f);
        cpage = cpage + 1;
        cpat = 1;
        baseplotname = sprintf('%s - Best Predictions - Page %d of %d', basefilename, cpage, npages);
        [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
        
    end
    
end




% 2) worst results where there should be a prediction

% 3) (worst) results - highest predictions where there should not be a
% prediction

end

