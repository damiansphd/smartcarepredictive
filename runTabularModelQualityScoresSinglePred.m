clear; close all; clc;

[~, studydisplayname, ~] = selectStudy();
[lb, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
if lb < 5
    fprintf('Chosen label method has multiple prediction days which is not supported by this script\n');
    return
end
labelstring = sprintf('lm%d', lb);

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';

modelresultslisting = dir(fullfile(basedir, subfolder, sprintf('pm*%s*%s*ModelResults.mat', studydisplayname, labelstring)));
modelresultsfiles = cell(size(modelresultslisting,1),1);
for a = 1:size(modelresultsfiles,1)
    modelresultsfiles{a} = modelresultslisting(a).name;
end

nmodels = size(modelresultsfiles,1);
fprintf('\n');
fprintf('Collating results for %d model runs\n', nmodels);
fprintf('\n');

pmModelQualityScores = [];

for i = 1:nmodels
    
    fprintf('Loading predictive model results data for %s\n', modelresultsfiles{i});
    load(fullfile(basedir, subfolder, modelresultsfiles{i}), 'pmModelRes', ...
        'pmFeatureParamsRow', 'pmModelParamsRow');
    featureparamsfile = generateFileNameFromFeatureParams(pmFeatureParamsRow);
    featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
    fprintf('Loading predictive model input data for %s\n', featureparamsfile);
    load(fullfile(basedir, subfolder, featureparamsmatfile), 'measures', 'nmeasures');
    fprintf('\n');
    
    resultrow = setTableDisplayRow(pmFeatureParamsRow, pmModelParamsRow, pmModelRes, measures, nmeasures);              
                  
    pmModelQualityScores = [pmModelQualityScores; resultrow];
end

basedir = setBaseDir();
subfolder = 'ExcelFiles';
outputfilename = sprintf('%s Single Pred Model Quality Scores.xlsx', studydisplayname);
fprintf('Saving results to excel file %s\n', outputfilename);
writetable(pmModelQualityScores, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'Model Quality Scores');


    