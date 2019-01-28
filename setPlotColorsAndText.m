function [combinedmask, plottext, left_color, lint_color, right_color, rint_color] = setPlotColorsAndText(measurerow)

% setPlotColorsAndText - sets the plot title text and colors based on
% measures feature mask settings

combinedmask = measurerow.RawMeas|| measurerow.BucketMeas || measurerow.Range ...
                || measurerow.Volatility || measurerow.AvgSeg || measurerow.VolSeg || measurerow.CChange;

if (measurerow.RawMeas|| measurerow.BucketMeas || measurerow.Range || measurerow.AvgSeg || measurerow.CChange)
    left_color = [0, 0.65, 1];
    lint_color = 'red';
else
    left_color = [0.83, 0.83, 0.83];
    lint_color = [0.83, 0.83, 0.83];
end
if (measurerow.Volatility || measurerow.VolSeg)
    right_color = [0.13, 0.55, 0.13];
    rint_color = 'red';
else
    right_color = [0.83, 0.83, 0.83];
    rint_color = [0.83, 0.83, 0.83];
end
    
plottext = measurerow.DisplayName{1};
if measurerow.RawMeas
    plottext = sprintf('%s-M', plottext);
end
if measurerow.BucketMeas
    plottext = sprintf('%s-BM', plottext);
end
if measurerow.Range
    plottext = sprintf('%s-R', plottext);
end
if measurerow.Volatility
    plottext = sprintf('%s-V', plottext);
end
if measurerow.AvgSeg
    plottext = sprintf('%s-AS', plottext);
end
if measurerow.VolSeg
    plottext = sprintf('%s-VS', plottext);
end
if measurerow.CChange
    plottext = sprintf('%s-CC', plottext);
end

end

