clear; close all; clc;

[modelinputfile, modelidx, modelinputs] = selectModelInputs();

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%s.mat',modelinputfile);
fprintf('Loading predictive model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));
toc

mdl = fitglm(pmTrNormFeatures, pmTrIVLabels(:,1), ...
    'linear', ...
    'Distribution', 'binomial', ...
    'Link', 'logit');

[X, Y, T, AUC, OPTROCPT] = perfcurve(pmTrIVLabels(:,1), mdl.Fitted.Probability, 1, 'Cost',[0 0.99;0.01 0]);

plot(X,Y);
hold on
plot(OPTROCPT(1),OPTROCPT(2),'ro')
xlabel('False positive rate') 
ylabel('True positive rate')
title('ROC Curve for Classification by Logistic Regression')
hold off

ypred = predict(mdl, pmValNormFeatures);

%inputs_mmAll_fd20_pd1 = [pmNormFeatures, pmIVLabels(:,1)];
%inputs_mmCW_fd10_pd1 = [pmNormFeatures(:,31:40), pmNormFeatures(:,171:180), pmIVLabels(:,1)];
%inputs_mmCW_fd10_pd5 = [pmNormFeatures(:,31:40), pmNormFeatures(:,171:180), pmIVLabels(:,5)];
