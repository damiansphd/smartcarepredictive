clear; close all; clc;

% load predictive model inputs for chosen study

[~, studydisplayname, ~] = selectStudy();

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%spredictivemodelinputs.mat', studydisplayname);

fprintf('Loading model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));

plotsubfolder = sprintf('Plots/%sFEV1vsO2Sat', studydisplayname);
mkdir(fullfile(basedir, plotsubfolder));

% plot FEV1 vs O2 Sat
% plot each data point minus robust max for each patient
% color code points into 1) upper 50% robust max of FEV1 2) lower 50%

mfev1idx  = measures.Index(ismember(measures.DisplayName, 'LungFunction'));
mo2satidx = measures.Index(ismember(measures.DisplayName, 'O2Saturation'));

fev1max  = pmPatientMeasStats(pmPatientMeasStats.MeasureIndex == mfev1idx, {'PatientNbr', 'Max'});
o2satmax = pmPatientMeasStats(pmPatientMeasStats.MeasureIndex == mo2satidx,{'PatientNbr', 'Max'});

temp = sortrows(fev1max, {'Max'}, 'ascend');

midpoint = ceil(npatients/2);
lpatients = temp.PatientNbr(1:midpoint);
upatients = temp.PatientNbr(midpoint + 1:npatients);

ldatapoints = sum(pmPatients.RelLastMeasdn(lpatients));
udatapoints = sum(pmPatients.RelLastMeasdn(upatients));
lfev1data  = zeros(ldatapoints, 1);
lo2satdata = zeros(ldatapoints, 1);
ufev1data  = zeros(udatapoints, 1);
uo2satdata = zeros(udatapoints, 1);

ulastpoint = 0;
llastpoint = 0;

for n = 1:npatients
    
    pnbr  = pmPatients.PatientNbr(n);
    pfmdn = pmPatients.RelFirstMeasdn(n);
    plmdn = pmPatients.RelLastMeasdn(n);
    
    pfev1max   = fev1max.Max(fev1max.PatientNbr == pnbr);
    po2satmax  = o2satmax.Max(o2satmax.PatientNbr == pnbr);
    
    pfev1data  = pmInterpDatacube(pnbr, pfmdn:plmdn, mfev1idx) - pfev1max;
    po2satdata = pmInterpDatacube(pnbr, pfmdn:plmdn, mo2satidx) - po2satmax;
    
    if ismember(pnbr, lpatients)
        lfev1data((llastpoint + 1):(llastpoint + plmdn)) = pfev1data;
        lo2satdata((llastpoint + 1):(llastpoint + plmdn)) = po2satdata;
        llastpoint = llastpoint + plmdn;
    else
        ufev1data((ulastpoint + 1):(ulastpoint + plmdn)) = pfev1data;
        uo2satdata((ulastpoint + 1):(ulastpoint + plmdn)) = po2satdata;
        ulastpoint = ulastpoint + plmdn;
    end
    
end

% plot results and observe any correlations

baseplotname = sprintf('%s - FEV1 vs O2Sat - %s', studydisplayname);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
    
plotsacross = 1;
plotsdown   = 1;
    
ax1(1) = subplot(plotsdown, plotsacross, 1, 'Parent', p);
scatter(ax1, lfev1data, lo2satdata, [], 'blue');
hold on;
scatter(ax1, ufev1data, uo2satdata, [], 'red');
xlabel(ax1, 'FEV1');
ylabel(ax1, 'O2 Sat');
title(ax1, 'FEV1 vs O2 Saturation');
legend(ax1, {'Lower 50 FEV1', 'Upper 50 FEV1'}, 'Location', 'best', 'FontSize', 6);
hold off;

basedir = setBaseDir();
savePlotInDir(f, baseplotname, basedir, plotsubfolder);
close(f);

    