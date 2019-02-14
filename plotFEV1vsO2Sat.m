function gradient = plotFEV1vsO2Sat(ax1, fev1data, o2satdata, dcolor, xl, yl, plottitle, pointsize)

% plotFEV1vsO2Sat - plots the fev1 vs o2saturation data and adds a
% regression line. Return the gradient of the regression line to be
% included in the legend

fidx = ~isnan(fev1data);
oidx = ~isnan(o2satdata);
    
idx = fidx & oidx;
    
fev1data  = fev1data(idx);
o2satdata = o2satdata(idx);

% plot results and observe any correlations
    
scatter(ax1, fev1data, o2satdata, 'MarkerEdgeColor', 'none', 'MarkerFaceColor',dcolor, 'MarkerFaceAlpha', 0.3, 'SizeData', pointsize);
pu = polyfitZero(fev1data, o2satdata,1);
yu_ls = polyval(pu, xl);
plot(ax1, xl, yu_ls, dcolor);
xlim(ax1, xl);
ylim(ax1, yl);
xlabel(ax1, 'FEV1');
ylabel(ax1, 'O2 Sat');
title(ax1, plottitle);

gradient = pu(1);

end

