function [gradient, dlm] = plotFEV1vsO2Sat(ax1, fev1data, o2satdata, dcolor, xl, yl, plottitle, pointsize, ntile)

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

%pu = polyfitZero(fev1data, o2satdata,1);
%yu_ls = polyval(pu, xl);
%plot(ax1, xl, yu_ls, dcolor);

%dlm = fitlm(fev1data, o2satdata, 'Intercept', false);
dlm = fitlm(fev1data, o2satdata);
%anova(dlm, 'summary')
rounding = 5;
minx = floor(min(fev1data * 1.1)/rounding) * rounding;
maxx = 0;
pxl = [minx maxx];
yu2_ls = feval(dlm, pxl);
plot(ax1, pxl, yu2_ls, dcolor, 'LineWidth', 2);
fprintf('For ntile %d, y-intercept is %.3f, gradient is %.3f, R-squared is %.4f, p-value is %.2e\n', ...
    ntile, dlm.Coefficients.Estimate(1), dlm.Coefficients.Estimate(2), dlm.Rsquared.Ordinary, coefTest(dlm));

xlim(ax1, xl);
ylim(ax1, yl);
xlabel(ax1, 'FEV1');
ylabel(ax1, 'O2 Sat');
title(ax1, plottitle);

gradient = dlm.Coefficients.Estimate(2);

end

