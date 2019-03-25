function plotModelCalibration(ax, binmids, modelcalibration, color1, color2, plottitle)

% plotModelCalibration - plots the model calibration results

hold on;
plot(ax, 100 * binmids, 100 * binmids, 'Color', color1);
plot(ax, 100 * binmids, modelcalibration, 'Color', color2, 'Marker', 'o');
hold off;
set(gca,'fontsize',6);
title(ax, plottitle,'FontSize', 6);
legend(ax, 'Ideal', 'Actual', 'Location', 'northwest');
xlabel('Bin Mid-Points', 'FontSize', 6);
ylabel('Actual Predictions', 'FontSize', 6); 

end

