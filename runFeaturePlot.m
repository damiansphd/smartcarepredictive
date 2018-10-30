clear; close all; clc;

[modelinputfile, modelidx, modelinputs] = selectFeatureAndLabelInputs();

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%s.mat',modelinputfile);
fprintf('Loading predictive model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));
toc

featureduration = pmRunParameters.featureduration(rp);
if nmeasures <= 4
    plotsacross = 1;
    plotsdown = nmeasures;
else
    plotsacross = 2;
    plotsdown = round(nmeasures/plotsacross);
end
    
name1 = sprintf('%s-PM Feature Plots', modelinputfile);
name2 = sprintf('%s-PM MinMax vs Vol Plot', modelinputfile);
subfolder = './Plots';

[f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
[f2, p2] = createFigureAndPanel(name2, 'Portrait', 'A4');
ax1  = zeros(1, nmeasures);
ax2 = zeros(1, nmeasures);

%xl1 = [1 featureduration];
%for i = 1:size(pmTrNormFeatures)
%    if pmTrIVLabels(i,1) == 1
%        lcol = 'blue';
%    else
%        lcol = 'red';
%    end
%    for m = 1:nmeasures
%        %ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);  
%        if pmTrIVLabels(i,1) == 1
%            line((1:featureduration), pmTrNormFeatures(i,((m-1)*featureduration) + 1:(m * featureduration)), ...
%                'Color', lcol, ...
%                'LineStyle', '-', ...
%                'LineWidth', 0.5);
%        end
%        xlim(xl1);
%        yl1 = [min(min(pmTrNormFeatures * 0.99)) max(max(pmTrNormFeatures * 1.01))];
%        ylim(yl1);
%        set(gca,'fontsize',6);
%        title(name1,'FontSize', 6);
%        xlabel('Features', 'FontSize', 6);
%        ylabel('Normalised Measure', 'FontSize', 6);
%        
%        ax2(m) = subplot(plotsdown, plotsacross, m, 'Parent',p2);
%        % hold on
%        scatter(ax2(m), m, max(pmTrNormFeatures(i,((m-1)*featureduration) + 1:(m * featureduration))) ...
%               - min(pmTrNormFeatures(i,((m-1)*featureduration) + 1:(m * featureduration))), ...
%                'Marker', 'o', ...
%                'MarkerEdgeColor', lcol, ...
%                'MarkerFaceColor', lcol);
%        %xlim(xl2);
%        %yl2 = [min(min(pmTrNormFeatures * 0.99)) max(max(pmTrNormFeatures * 1.01))];
%        %ylim(yl2);
%        set(gca,'fontsize',6);
%        title(name2,'FontSize', 6);
%        xlabel('Features', 'FontSize', 6);
%        ylabel('Normalised Measure', 'FontSize', 6);
%    end
%end

for m = 1:nmeasures
    ax2(m) = subplot(plotsdown, plotsacross, m, 'Parent',p2);
    minmaxfeat = nmeasures * featureduration + m;
    volfeat    = nmeasures * featureduration + nmeasures + m;
    scatter(ax2(m), pmNormFeatures(pmIVLabels(:,1)==0,minmaxfeat), ...
        pmNormFeatures(pmIVLabels(:,1)==0,volfeat), ...
        'Marker', 'o', ...
        'MarkerEdgeColor', 'red');
    hold on;
    scatter(ax2(m), pmNormFeatures(pmIVLabels(:,1)==1,minmaxfeat), ...
        pmNormFeatures(pmIVLabels(:,1)==1,volfeat), ...
        'Marker', 'o', ...
        'MarkerEdgeColor', 'blue');
    hold off;
end

savePlotInDir(f1, name1, subfolder);
savePlotInDir(f2, name2, subfolder);
close(f1);
close(f2);
