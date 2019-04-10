function axr = plottextModelCalibrationTable(p1, axl, modelcalibration, fold, plotsacross, sdidx, qsrow)

% plottextModelCalibrationTable - writes the model calibration results to a
% uicontrol on the figure


tabletitle = [  {sprintf('   BinRange    TrueLabels NbrInBin  Percentage')} ; ...
                {sprintf('-------------- ---------- --------  ----------')} ; ...
              ];

tabletext = tabletitle;
for a = 1:size(modelcalibration,1)
    if sdidx(a) == true
        sdtext = '***';
    else
        sdtext = '';
    end
    rowstring = sprintf('%13s    %4.0f      %4.0f      %5.1f%%  %3s', modelcalibration.BinRange{a}, ...
        modelcalibration.TrueLabels(a), modelcalibration.NbrInBin(a), modelcalibration.Calibration(a), sdtext);
    tabletext = [tabletext ; rowstring];
end
rowstring = ' ';
tabletext = [tabletext ; rowstring];
rowstring = sprintf('PScore %s', qsrow.PScore{1});
tabletext = [tabletext ; rowstring];
rowstring = sprintf('ElectPScore %s', qsrow.ElecPScore{1});
tabletext = [tabletext ; rowstring];
rowstring = sprintf('PRAUC %5.3f%% | ROCAUC %5.3f%%', qsrow.PRAUC, qsrow.ROCAUC);
tabletext = [tabletext ; rowstring];
rowstring = sprintf('Acc   %5.3f%%', qsrow.Acc);
tabletext = [tabletext ; rowstring];
rowstring = sprintf('PosAcc %5.3f%% | NegAcc %5.3f%%', qsrow.PosAcc, qsrow.NegAcc);
tabletext = [tabletext ; rowstring];


posvector = axl.Position;
posvector(1) = posvector(1) + (1/plotsacross);
plotnbr = 2 * (fold + 1);
axr = uicontrol('Parent', p1, ... 
                'Units', 'normalized', ...
                'OuterPosition', posvector, ...
                'Style', 'text', ...
                'FontName', 'FixedWidth', ...
                'FontSize', 6, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'String', tabletext);
          
end

