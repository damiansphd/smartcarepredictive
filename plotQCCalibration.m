function plotQCCalibration(p, modelcalibration, binmids, fold, plotsperpage, cplot, type)

% plotQCCalibrationend - plots the quality classifier calibration

smalldatathresh = 30;
plotsacross = 2;

uipypos = 1 - cplot/plotsperpage;
uipysz  = 1/plotsperpage;
uiptitle = '';
sp(cplot) = uipanel('Parent', p, ...
              'BorderType', 'none', ...
              'OuterPosition', [0.0,uipypos, 1.0, uipysz], ...
              'Title', uiptitle, 'TitlePosition', 'centertop', 'FontSize', 8);
ax1 = gobjects(plotsacross, 1);

ax1(1) = subplot(1, plotsacross, 1, 'Parent', sp(cplot));
sdidx = (modelcalibration.NbrInBin(modelcalibration.Fold == fold) <= smalldatathresh);
plotModelCalibration(ax1(1), binmids, modelcalibration.Calibration(modelcalibration.Fold == fold), sdidx, [0.7, 0.7, 0.7], 'Blue', 'Red', type);

modelcalib = modelcalibration(modelcalibration.Fold == fold, :);

tabletitle = [  {sprintf('   BinRange    TrueLabels NbrInBin  Percentage')} ; ...
                {sprintf('-------------- ---------- --------  ----------')} ; ...
              ];

tabletext = tabletitle;
for a = 1:size(modelcalib,1)
    if sdidx(a) == true
        sdtext = '***';
    else
        sdtext = '';
    end
    rowstring = sprintf('%13s    %4.0f      %4.0f      %5.1f%%  %3s', modelcalib.BinRange{a}, ...
        modelcalib.TrueLabels(a), modelcalib.NbrInBin(a), modelcalib.Calibration(a), sdtext);
    tabletext = [tabletext ; rowstring];
end

ax1(2) = uicontrol('Parent', p, ... 
                'Units', 'normalized', ...
                'OuterPosition', [0.5,uipypos, 1.0, uipysz], ...
                'Style', 'text', ...
                'FontName', 'FixedWidth', ...
                'FontSize', 6, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'String', tabletext);
            
end
