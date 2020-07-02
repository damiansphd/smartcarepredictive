function plotModelCalibration(ax, binmids, modelcalibration, sdidx, color1, color2, color3, plottitle)

% plotModelCalibration - plots the model calibration results

hold on;
plot(ax, 100 * binmids, 100 * binmids, 'Color', color1);
plot(ax, 100 * binmids, modelcalibration, 'Color', color2, 'Marker', 'o');
plot(ax, 100 * binmids(sdidx), modelcalibration(sdidx), 'Color', color3, 'Marker', 'o', 'LineStyle', 'none');
hold off;
ax.FontSize = 6;
%set(gca,'fontsize',6);
title(ax, plottitle,'FontSize', 6);
legend(ax, 'Ideal', 'Actual', 'Actual (Low Count)', 'Location', 'northwest');
xlabel(ax, 'Bin Mid-Points', 'FontSize', 6);
ylabel(ax, 'Actual Predictions', 'FontSize', 6); 
xlim(ax, [0 100]);
xlim(ax, [0 100]);

end

