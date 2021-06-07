function [gooddays, totdays, dailytotal] = plotDWMeasuresCompletenessForPatient(pmPatients, pmAntibiotics, pmAMPred, pmRawDatacube, ...
    measures, nmeasures, pmFeatureParamsRow, plotsubfolder, basefilename)

% plotDWMeasuresCompletenessForPatient - plot the measures completeness for
% all patients (for each measure and overall)

basedir = setBaseDir();

hmaprows    = nmeasures + 2; % heatmap has one row per measure + total + dummy (not displayed)
nhmapvals   = nmeasures + 2 + 1; % values of cells in heatmap = 2 for individual measures (present/missind) + 9 for total cells (nmeasures + 1 (for 0 total)

temp            = hsv(64);
tcolors         = zeros(nmeasures + 3, 3);
tcolors(1,  :)  = [1 1 1];       % Array val =  0: Individual measure, missing: white
tcolors(2,  :)  = [0.7 0.7 0.7]; % Array val =  1: Individual measure, present: grey
tcolors(3,  :)  = [0 0 0];     % Array val =  2: Total by day = 0:            black
tcolors(4,  :)  = temp(4,:);   % Array val =  3: Total by day = 1:            red
tcolors(5,  :)  = temp(6,:);   % Array val =  4: Total by day = 2:            red/amber  
tcolors(6,  :)  = temp(8,:);   % Array val =  5: Total by day = 3:            amber
tcolors(7,  :)  = temp(10,:);  % Array val =  6: Total by day = 4:            amber/yellow
tcolors(8,  :)  = temp(12,:);  % Array val =  7: Total by day = 5:            yellow
tcolors(9,  :)  = temp(14,:);  % Array val =  8: Total by day = 6:            yellow/green
tcolors(10, :)  = temp(16,:);  % Array val =  9: Total by day = 7:            light green
tcolors(11, :)  = temp(18,:);  % Array val = 10: Total by day = 8:            green

widthinch     = 11.6;
heightinch    = 15;
plotsacross   = 1;
plotsdown     = 10;
currhght      = 1.0;
panelhght     = 1/plotsdown;
perioddays    = 300;
labelinterval = 50;
npatients     = size(pmPatients, 1);
pmPatients.NPeriods = ceil(pmPatients.RelLastMeasdn / perioddays);
totperiods    = sum(pmPatients.NPeriods);
npages        = ceil(totperiods / plotsdown);
page          = 1;
thisplot      = 1;
totdays       = 0;
gooddays      = 0;
mthresh       = 2; % threshold of number of measures per day

ydisplaylabels = cell(size(hmaprows, 1));
ydisplaylabels(1:nmeasures)   = measures.DisplayName;
ydisplaylabels(nmeasures + 1) = {'Total'};
ydisplaylabels(nmeasures + 2) = {' '};

plotname = sprintf('%sMeasComp-P%dof%d', basefilename, page, npages);
[f1, p1] = createFigureAndPanelForPaper('', widthinch, heightinch);

% populate measure count array - by patient by day by (individual measure and total)
maxperiods = max(pmPatients.NPeriods);
mcompdata = zeros(npatients, maxperiods * perioddays, hmaprows);
mcompdata(:, 1:size(pmRawDatacube, 2), 1:nmeasures) = double(~isnan(pmRawDatacube));
mcompdata(:, :, nmeasures + 1) = 2 + sum(mcompdata(:, :, 1:nmeasures), 3);

% populate dummy row with all values in heatmap to ensure full color scale
% is correctly used in all patient/periods +
dummydata = repmat((0:nhmapvals - 1), npatients, ceil((maxperiods * perioddays) / nhmapvals));
dummydata = dummydata(:, 1:(maxperiods * perioddays));
mcompdata(:, :, hmaprows) = dummydata;

dailytotal = zeros(sum(pmPatients.RelLastMeasdn), 1);
didx = 1;

for p = 1:npatients
    
    pnbr      = pmPatients.PatientNbr(p);
    pmaxdays  = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
    npperiods = pmPatients.NPeriods(p);
    
    pmcompdata = reshape(mcompdata(pnbr, :, :), maxperiods * perioddays, hmaprows)';
    pmcompdata(:, pmaxdays + 1:end) = 0; % set all the points after end of measurement to zero
    
    dailytotal(didx:(didx + pmaxdays - 1)) = pmcompdata((nmeasures + 1), (1:pmaxdays)) - 2;
    didx = didx + pmaxdays;
    
    pgooddays = sum(pmcompdata(nmeasures + 1, :) - 2 > mthresh);
    fprintf('Patient %3d: %5.2f%% (%3d days with > %1d measures out of a total of %3d)\n', pnbr, 100 * pgooddays / pmaxdays, pgooddays, mthresh, pmaxdays);
    gooddays = gooddays + pgooddays;
    totdays = totdays + pmaxdays;
    
    for period = 1:npperiods
    
        dfrom = (period - 1) * perioddays + 1;
        dto   = period * perioddays;
        pdto  = dto;
        if dto > pmaxdays
            pdto = pmaxdays;
        end
        
        xdisplaylabels = cell(perioddays, 1);
        xdisplaylabels{1} = sprintf('%d', 1);
        for i = 2:perioddays
            if (i / labelinterval == round(i / labelinterval))
                xdisplaylabels{i} = sprintf('%d', dfrom - 1 + i);
            else
                xdisplaylabels{i} = ' ';
            end
        end
        xdisplaylabels((dto - dfrom + 2):end) = [];
        
        currhght = currhght - panelhght;
        
        sp(thisplot) = uipanel('Parent', p1, ...
                        'BorderType', 'none', ...
                        'BackgroundColor', 'white', ...
                        'OuterPosition', [0, currhght, 1, panelhght]);       
        
        h = heatmap(sp(thisplot), pmcompdata(:, dfrom:dto), 'Colormap', tcolors);
        h.Title = sprintf('Patient %d (%s%d) - %d to %d days', pnbr, pmPatients.Study{pnbr}, pmPatients.ID(pnbr), dfrom, pdto);
        h.FontSize = 8;
        h.XLabel = 'Days';
        h.YLimits = {1, nmeasures + 1};
        h.YDisplayLabels = ydisplaylabels;
        h.XDisplayLabels = xdisplaylabels;
        h.CellLabelColor = 'none';
        h.GridVisible = 'off';
        h.ColorbarVisible = 'off';
        
        thisplot = thisplot + 1;
        if thisplot > plotsdown
            savePlotInDir(f1, plotname, basedir, plotsubfolder);
            close(f1);
            currhght = 1.0;
            thisplot = 1;
            page = page + 1;
            plotname = sprintf('%sMeasComp-P%dof%d', basefilename, page, npages);
            [f1, p1] = createFigureAndPanelForPaper('', widthinch, heightinch);
        end
    end
    
end

basedir = setBaseDir();
savePlotInDir(f1, plotname, basedir, plotsubfolder);
close(f1);

fprintf('\n');
fprintf('Total      : %5.2f%% (%3d days with > %1d measures out of a total of %3d)\n', 100 * gooddays / totdays, gooddays, mthresh, totdays);
fprintf('\n');

widthinch     = 8;
heightinch    = 6;
plotname = sprintf('%sDailyMeasHist', basefilename);
[f1, p1] = createFigureAndPanelForPaper('', widthinch, heightinch);
ax1 = subplot(1, 1, 1, 'Parent',p1);
h = histogram(ax1, dailytotal);
title(ax1, 'Daily measures count');
xlabel(ax1, 'Measures per day');
ylabel(ax1, 'Number of days');

savePlotInDir(f1, plotname, basedir, plotsubfolder);
close(f1);

end

