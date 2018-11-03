function plotMeasuresAndPredictionsForPatient(patientrow, pabs, prawdata, pinterpdata, ...
    pmFeatureIndex, pmIVLabels, modelresults, measures, nmeasures, labelidx, runparamsrow, plotsubfolder)

% plotMeasuresAndPredictions - for a given patient, plot the measures along
% with the predictions from the predictive classification model and the 
% true labels.

patientnbr = patientrow.PatientNbr;

plotsacross = 1;
plotsdown = nmeasures + 1;

basefilename = generateFileNameFromRunParameters(runparamsrow);
baseplotname = sprintf('%s - %d Day Prediction - Patient %d (Study %s, ID %d)', basefilename, labelidx, patientnbr, patientrow.Study{1}, patientrow.ID);

[f1,p1] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');

pabsdates = pabs(ismember(pabs.Route, 'IV'),{'Startdn','Stopdn'});
for ab = 1:size(pabsdates,1)
    if pabsdates.Startdn(ab) < patientrow.FirstMeasdn
        pabsdates.Startdn(ab) = patientrow.FirstMeasdn;
    end
    if pabsdates.Stopdn(ab) > patientrow.LastMeasdn
        pabsdates.Stopdn(ab) = patientrow.LastMeasdn;
    end
end

pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;
fidx = (pmFeatureIndex.PatientNbr == patientnbr);
pfeatindex = pmFeatureIndex(fidx,:);
ppred = modelresults.pmLabel(5).Pred(fidx);
plabel = pmIVLabels(fidx,labelidx);

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
    
    ax(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
    
    [xl, yl] = plotMeasurementData(ax(m), days, mdata, xl, yl, measures.DisplayName(m), measures.Mask(m), [0, 0.65, 1], ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax(m), days, smooth(mdata,5), xl, yl, measures.DisplayName(m), measures.Mask(m), [0, 0.65, 1], '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    [xl, yl] = plotMeasurementData(ax(m), days, interppts, xl, yl, measures.DisplayName(m), measures.Mask(m), [0, 0.65, 1], 'none', 1.0, 'o', 1.0, 'red', 'red');
    
    for ab = 1:size(pabsdates,1)
        hold on;
        plotFillArea(ax(m), pabsdates.Startdn(ab) - patientrow.FirstMeasdn, pabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    
end

m = nmeasures + 1;

ax(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
xlim(xl);
%yl = [min(ppred) max(ppred)];
yl = [0 1];
ylim(yl);
[xl, yl] = plotMeasurementData(ax(m), days, plabeldata, xl, yl, 'Prediction and Label', 0, 'green', '-', 1.0, 'none', 1.0, 'blue', 'green');
[xl, yl] = plotMeasurementData(ax(m), days, ppreddata, xl, yl, 'Prediction and Label', 0, 'black', '-', 1.0, 'none', 1.0, 'blue', 'green');


% create function for plotting true labels and call here

for ab = 1:size(pabsdates,1)
    hold on;
    plotFillArea(ax(m), pabsdates.Startdn(ab) - patientrow.FirstMeasdn, pabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
    hold off;
end

basedir = setBaseDir();
savePlotInDir(f1, baseplotname, basedir, plotsubfolder);
close(f1);
    
end

