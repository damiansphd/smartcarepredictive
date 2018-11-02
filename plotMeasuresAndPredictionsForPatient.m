function plotMeasuresAndPredictionsForPatient(patientrow, pabs, prawdata, pinterpdata, pmFeatureIndex, pmIVLabels, pmModelRes, measures, nmeasures, runparamsrow)

% plotMeasuresAndPredictions - for a given patient, plot the measures along
% with the predictions from the predictive classification model and the 
% true labels.

patientnbr = patientrow.PatientNbr;

plotsacross = 1;
plotsdown = nmeasures + 1;

basefilename = generateFileNameFromRunParameters(runparamsrow);
baseplotname1 = sprintf('%s-Prediction', basefilename);
[f1,p1] = createFigureAndPanel(baseplotname1, 'Portrait', 'A4');

pabsdates = pabs(ismember(pabs.Route, 'IV'),{'Startdn','Stopdn'});
for ab = 1:size(pabsdates,1)
    if pabsdates.Startdn(ab) < patientrow.FirstMeasdn
        pabsdates.Startdn(ab) = patientrow.FirstMeasdn;
    end
    if pabsdates.Stopdn(ab) > patientrow.LastMeasdn
        pabsdates.Stopdn(ab) = patientrow.LastMeasdn;
    end
end

for m = 1:nmeasures
    pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;
    days = (1:pmaxdays);
    mrawdata = prawdata(1, 1:pmaxdays, m);
    mdata = pinterpdata(1, 1:pmaxdays, m);
    interppts = mdata;
    interppts(~isnan(mrawdata)) = nan;
    
    xl = [1 pmaxdays];
    if min(mdata) == 0 && max(mdata) == 0
        yl = [-0.01 0.01];
    else
        yl = [min(mdata) max(mdata)];
    end
    
    ax(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
    
    [xl, yl] = plotMeasurementData(ax(m), days, mdata, xl, yl, measures(m,:), [0, 0.65, 1], ':', 1.0, 'none', 1.0, 'blue', 'green');
    [xl, yl] = plotMeasurementData(ax(m), days, smooth(mdata,5), xl, yl, measures(m,:), [0, 0.65, 1], '-', 1.0, 'none', 1.0, 'blue', 'green');
    
    [xl, yl] = plotMeasurementData(ax(m), days, interppts, xl, yl, measures(m,:), [0, 0.65, 1], 'none', 1.0, 'o', 2.0, 'red', 'red');
    
    for ab = 1:size(pabsdates,1)
        hold on;
        plotFillArea(ax(m), pabsdates.Startdn(ab) - patientrow.FirstMeasdn, pabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
        hold off;
    end
    
end

m = nmeasures + 1;

ax(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
xlim(xl);
yl = [-0.01 0.01];
ylim(yl);

% create function for plotting prediction results and call here
% create function for plotting true labels and call here

for ab = 1:size(pabsdates,1)
    hold on;
    plotFillArea(ax(m), pabsdates.Startdn(ab) - patientrow.FirstMeasdn, pabsdates.Stopdn(ab) - patientrow.FirstMeasdn, yl(1), yl(2), 'red', 0.1, 'none');
    hold off;
end

basedir = setBaseDir();
subfolder = 'Plots';
plotname = sprintf('%s Patient %d (Study %s, ID %d)', baseplotname1, patientnbr, patientrow.Study{1}, patientrow.ID);
savePlotInDir(f1, plotname, basedir, subfolder);
close(f1);
    
end

