function [xl, yl] = plotMeasurementData(ax, days, mdata, xl, yl, measurename, measuremask, colour, linestyle, linewidth, marker, markersize, markerec, markerfc)

% plotMeasurementData - plots the measurement data for a given measurement
% type

% plot measurement data
line(ax, days, mdata, ...
    'Color', colour, ...
    'LineStyle', linestyle, ...
    'LineWidth', linewidth, ...
    'Marker', marker, ...
    'MarkerSize', markersize,...
    'MarkerEdgeColor', markerec, ...
    'MarkerFaceColor', markerfc);
xl = [min(min(days), xl(1)) max(max(days), xl(2))];
xlim(xl);
yl = [min(min(mdata * 0.95), yl(1)) max(max(mdata * 1.05), yl(2))];
ylim(yl);

set(gca,'fontsize',6);
if measuremask == 1
    title(measurename, 'FontSize', 6, 'BackgroundColor', 'green');
else
    title(measurename,'FontSize', 6);
end
xlabel('Days', 'FontSize', 6);
ylabel('Measure', 'FontSize', 6);
    
end

