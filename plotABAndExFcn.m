function [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl)

% plotABAndExFcn - convenience function to plot the antibiotic treatments
% and exacerbation starts on a lot

for ab = 1:size(poralabsdates, 1)
    hold on;
    plotFillArea(ax, poralabsdates.RelStartdn(ab), poralabsdates.RelStopdn(ab), yl(1), yl(2), 'yellow', 0.1, 'none');
    hold off;
end
for ab = 1:size(pivabsdates, 1)
    hold on;
    plotFillArea(ax, pivabsdates.RelStartdn(ab), pivabsdates.RelStopdn(ab), yl(1), yl(2), 'red', 0.1, 'none');
    hold off;
end
for ex = 1:size(pexstsdates, 1)
    hold on;
    plotVerticalLine(ax, pexstsdates.Pred(ex), xl, yl, 'blue', '-', 1.0);
    plotFillArea(ax, pexstsdates.RelLB1(ex), pexstsdates.RelUB1(ex), yl(1), yl(2), 'blue', 0.1, 'none');
    if pexstsdates.RelLB2(ex) ~= -1
        plotFillArea(ax, pexstsdates.RelLB2(ex), pexstsdates.RelUB2(ex), yl(1), yl(2), 'blue', 0.1, 'none');
    end
    hold off;
end
        
end

