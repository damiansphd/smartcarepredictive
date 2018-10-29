clear; close all; clc;

[modelinputfile, modelidx, modelinputs] = selectFeatureAndLabelInputs();

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%s.mat',modelinputfile);
fprintf('Loading predictive model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));
load(fullfile(basedir, subfolder, pmRunParameters.modelinputsmatfile{rp}));
toc

featureduration = pmRunParameters.featureduration(rp);
plotsdown = 2;
plotsacross = 1;
name = 'PM Feature Plots';
subfolder = './Plots';

[f, p] = createFigureAndPanel(name, 'Portrait', 'A4');

ax = subplot(plotsdown, plotsacross, 1, 'Parent',p);        

%ptrnormfeatures = pmTrNormFeatures(pmTrIVLabels==1);
%ntrnormfeatures = pmTrNormFeatures(pmTrIVLabels==0);

xl = [0 nmeasures];

for i = 1:size(pmTrNormFeatures)
    if pmTrIVLabels(i,1) == 1
        lcol = 'blue';
    else
        lcol = 'red';
    end
    %if pmTrIVLabels(i,1) == 1
    line(((1/featureduration):(1/featureduration):nmeasures), pmTrNormFeatures(i,:), ...
        'Color', lcol, ...
        'LineStyle', '-', ...
        'LineWidth', 0.5);
    %end
end
    
    
xlim(xl);
yl = [min(min(pmTrNormFeatures * 0.99)) max(max(pmTrNormFeatures * 1.01))];
ylim(yl);

set(gca,'fontsize',6);
title(name,'FontSize', 6);
xlabel('Features', 'FontSize', 6);
ylabel('Normalised Measure', 'FontSize', 6);
        
        
    

savePlotInDir(f, name, subfolder);
close(f);
