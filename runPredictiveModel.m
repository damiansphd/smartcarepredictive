clear; close all; clc;

[modelinputfile, modelidx, modelinputs] = selectModelInputs();

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
modelinputsmatfile = sprintf('%s.mat',modelinputfile);
fprintf('Loading predictive model input data\n');
load(fullfile(basedir, subfolder, modelinputsmatfile));
toc

mdl = fitglm(pmTrFeatures, pmTrIVLabels(:,1), 'linear', 'Distribution', 'binomial', 'Link', 'logit');

ypred = predict(mdl, pmValFeatures);