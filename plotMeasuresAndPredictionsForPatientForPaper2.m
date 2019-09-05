function plotMeasuresAndPredictionsForPatientForPaper2(patientrow, pabs, pexsts, prawdata, pinterpdata, pinterpvoldata, ...
    pmFeatureIndex, trcvlabels, pmModelRes, pmOverallStats, ...
    pmeasstats, measures, nmeasures, mvolstats, labelidx, pmFeatureParamsRow, ...
    lbdisplayname, plotsubfolder, basefilename, studydisplayname)

% plotMeasuresAndPredictionsForPatientForPaper - for a given patient, plot the measures along
% with the predictions from the predictive classification model and the 
% true labels.

smfn       = pmFeatureParamsRow.smfunction;
smwin      = pmFeatureParamsRow.smwindow;
smln       = pmFeatureParamsRow.smlength;
normwindow = pmFeatureParamsRow.normwindow;

patientnbr = patientrow.PatientNbr;
pmaxdays = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;

mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));

titlefontsize = 14;
labelfontsize = 12;
axisfontsize = 10;
unitfontsize = 10;

widthinch = 8.25;
heightinch = 7.5;
name = '';
singlehght = 1/13.5;
halfhght = singlehght * 0.5;
doublehght = singlehght * 2;
twoandhalfhght = singlehght * 2.5;
triplehght = singlehght * 3;
labelwidth = 0.15;
plotwidth  = 0.85;

ntitles = 1;
npredictions = 1;
tmpnmeasures = sum(measures.RawMeas | measures.BucketMeas | measures.Range | measures.Volatility | measures.CChange | measures.PMean);
nlabels = npredictions + tmpnmeasures;

typearray = 1;
for i = 1:tmpnmeasures
    typearray = [typearray, 2, 5];
end
typearray = [typearray, 3, 6];

typehght = [halfhght, doublehght, twoandhalfhght, singlehght, doublehght, twoandhalfhght];

labeltext = [];
labeltext = [labeltext; {' '}];
[measures] = sortMeasuresForPaper(studydisplayname, measures);
tmpmeasures = measures(measures.RawMeas | measures.BucketMeas | measures.Range | measures.Volatility | measures.CChange | measures.PMean, :);

for m = 1:tmpnmeasures
    labeltext = [labeltext; cellstr(tmpmeasures.DisplayName{m}); ' '];
end
labeltext = [labeltext; {'Prediction'; ' '}];

baseplotname1 = sprintf('%s - %s Labels - Patient %d (Study %s, ID %d) For Paper 2', ...
    basefilename, lbdisplayname, patientnbr, patientrow.Study{1}, patientrow.ID);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

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
ppred  = pmModelRes.pmNDayRes(labelidx).Pred(fidx);
plabel = trcvlabels(fidx,labelidx);

ppreddata = nan(1, pmaxdays);
plabeldata = nan(1, pmaxdays);
for d = 1:size(ppred,1)
    ppreddata(pfeatindex.CalcDatedn(d))  = ppred(d);
    plabeldata(pfeatindex.CalcDatedn(d)) = plabel(d);
end

currhght = 1.0;
currplot = 1;
for i = 1:(ntitles + tmpnmeasures + npredictions + nlabels)
    type = typearray(i);
    if type == 1
        % labels for left and right axes
        currhght = currhght - typehght(type);
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [0, currhght, 1, typehght(type)]);
        displaytext = 'Measure';
        annotation(sp(i), 'textbox',  ...
                        'String', displaytext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0.2, 0, .2, 1], ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment', 'bottom', ...
                        'LineStyle', 'none', ...
                        'FontSize', labelfontsize);
    elseif type == 2 || type == 3
        % Label
        currhght = currhght - typehght(type);
        displaytext = {formatTexDisplayMeasure(labeltext{i}); sprintf('\\fontsize{%d} (%s)', unitfontsize, getUnitsForMeasure(labeltext{i}))};
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [0, currhght, labelwidth, typehght(type)]);
        annotation(sp(i), 'textbox',  ...
                        'String', displaytext, ...
                        'Interpreter', 'tex', ...
                        'Units', 'normalized', ...
                        'Position', [0, 0, 1, 1], ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'LineStyle', 'none', ...
                        'FontSize', labelfontsize);
    elseif type == 4 || type == 5 || type == 6
        % plot
        sp(i) = uipanel('Parent', p, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [labelwidth, currhght, plotwidth, typehght(type)]);
        %set(sp(i),'defaultAxesColorOrder',[[0, 0, 0]; [0, 0, 0]]);
        
        if currplot <= tmpnmeasures
            m = currplot;

            days = (1:pmaxdays);
            mrawdata = prawdata(1, 1:pmaxdays, tmpmeasures.Index(m));
            mdata = pinterpdata(1, 1:pmaxdays, tmpmeasures.Index(m));
            vdata = pinterpvoldata(1, 1:pmaxdays, tmpmeasures.Index(m));

            displaymeasure = tmpmeasures.DisplayName{m};
            [smcolour, rwcolour] = getColourForMeasure(displaymeasure);            

            xl = [35 pmaxdays];

            % set minimum y display range to be mean +/- 1 stddev (using patient/
            % measure level stats where they exist, otherwise overall study level
            % stats
            if size(pmeasstats.Mean(pmeasstats.MeasureIndex == tmpmeasures.Index(m)), 1) == 0
                yl = [(pmOverallStats.Mean(tmpmeasures.Index(m)) - pmOverallStats.StdDev(tmpmeasures.Index(m))) (pmOverallStats.Mean(tmpmeasures.Index(m)) + pmOverallStats.StdDev(tmpmeasures.Index(m)))];
            else
                yl = [(pmeasstats.Mean(pmeasstats.MeasureIndex == tmpmeasures.Index(m)) - pmeasstats.StdDev(pmeasstats.MeasureIndex == tmpmeasures.Index(m))) ...
                    (pmeasstats.Mean(pmeasstats.MeasureIndex == tmpmeasures.Index(m)) + pmeasstats.StdDev(pmeasstats.MeasureIndex == tmpmeasures.Index(m)))];
            end
            
            yl(1) = min(yl(1), min(mdata));
            yl(2) = max(yl(2), max(mdata));
            rangelimit = setMinYDisplayRangeForMeasure(tmpmeasures.Name{m});
            [yl] = setYDisplayRange(yl(1), yl(2), rangelimit);
            
            ax = subplot(1, 1, 1,'Parent', sp(i));
            ax.FontSize = axisfontsize;
            ax.TickDir = 'out';
            ax.XTickLabel = '';
            ax.XColor = 'white';
            xlim(ax, xl);
            ylim(ax, yl);
    
            %plotMeasurementDataForPaper(ax, days, applySmoothMethodToInterpRow(mdata, smfn, smwin, smln, tmpmeasures.Index(m), mfev1idx), smcolour, '-', 1.5, 'none', 1.0);
            plotMeasurementDataForPaper(ax, days, mrawdata, smcolour, '-', 1.5, 'none', 1.0);

            for ab = 1:size(poralabsdates,1)
                hold on;
                plotFillArea(ax, poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
                hold off;
            end

            for ab = 1:size(pivabsdates,1)
                hold on;
                plotFillArea(ax, pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
                hold off;
            end

            for ex = 1:size(pexstsdates, 1)
                hold on;
                plotVerticalLine(ax, pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
                plotFillArea(ax, pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
                if pexstsdates.RelLB2(ex) ~= -1
                    plotFillArea(ax, pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
                end
            end
            
            yticks = setTicks(yl(1), yl(2), 3);
            ax.YTick = yticks;
            ax.YTickLabel = addCommaFormat(yticks);
            title(ax,' ');
            
        else 
            % Predictions for Labels
            ax = subplot(1, 1, 1,'Parent', sp(i));
            
            xlim(xl);
            yl = [0 100];
            ylim(yl);
            xlabel(ax, 'Days from start of study');
            plotMeasurementDataForPaper(ax, days, ppreddata * 100,  'black', '-', 1.5, 'none', 1.0);

            for ab = 1:size(poralabsdates, 1)
                hold on;
                plotFillArea(ax, poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
                hold off;
            end
            for ab = 1:size(pivabsdates, 1)
                hold on;
                plotFillArea(ax, pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
                hold off;
            end
            for ex = 1:size(pexstsdates, 1)
                hold on;
                plotVerticalLine(ax, pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
                plotFillArea(ax, pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
                if pexstsdates.RelLB2(ex) ~= -1
                    plotFillArea(ax, pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
                end
            end
            
        end
        currplot = currplot + 1;
    end
end

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end
