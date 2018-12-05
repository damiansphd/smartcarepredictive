function plotVolatilityMeasuresForPatient(patientrow, pabs, pexsts, prawdata, pinterpdata, ...
    measures, nmeasures, plotsubfolder, basefilename)

% plotVolatilityMeasuresForPatient - for a given patient, plot the trailing
% 5 day volatility of measures

patientnbr = patientrow.PatientNbr;
pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;

plotsacross = 1;
plotsdown = nmeasures;

baseplotname1 = sprintf('%s - Volatility Measures - Patient %d (Study %s, ID %d)', basefilename, patientnbr, patientrow.Study{1}, patientrow.ID);

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

ax1 = gobjects(nmeasures,1);

for m = 1:nmeasures
    
    days = (1:pmaxdays);
    mrawdata = prawdata(1, 1:pmaxdays, m);
    mdata = pinterpdata(1, 1:pmaxdays, m);
    interppts = mdata;
    interppts(~isnan(mrawdata)) = nan;
    
    xl = [1 pmaxdays];
    
    % relevant if plotting normalised data
    if min(mdata) == max(mdata)
        if min(mdata) < 0
            yl = [min(mdata) * 1.01 min(mdata) * 0.99];
        elseif min(mdata) > 0
            yl = [min(mdata) * 0.99 min(mdata) * 1.01];
        else
            yl = [-0.01 0.01];
        end
    else
        yl = [min(mdata) max(mdata)];
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

basedir = setBaseDir();
savePlotInDir(f1, baseplotname1, basedir, plotsubfolder);
close(f1);

end

