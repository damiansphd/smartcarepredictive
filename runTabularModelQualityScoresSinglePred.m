clear; close all; clc;

[~, studydisplayname, ~] = selectStudy();

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
labelstring = 'lm5';
modelresultslisting = dir(fullfile(basedir, subfolder, sprintf('pm*%s*%s*ModelResults.mat', studydisplayname, labelstring)));
modelresultsfiles = cell(size(modelresultslisting,1),1);
for a = 1:size(modelresultsfiles,1)
    modelresultsfiles{a} = modelresultslisting(a).name;
end

nmodels = size(modelresultsfiles,1);
fprintf('Collating results for %d model runs\n', nmodels);

pmModelQualityScores = [];

for i = 1:nmodels
    
    fprintf('Loading predictive model results data for %s\n', modelresultsfiles{i});
    load(fullfile(basedir, subfolder, modelresultsfiles{i}), 'pmModelRes', ...
        'pmFeatureParamsRow', 'pmModelParamsRow');
    
    resultrow = pmFeatureParamsRow;
    resultrow(:,{'StudyNbr', 'modelinputsmatfile'}) = [];
    resultrow.Version(:)     = pmModelParamsRow.Version;
    resultrow.labelmethod(:) = pmModelParamsRow.labelmethod;
    %resultrow.lambda(:)      = pmModelParamsRow.lambda;
    
    predictionduration = pmFeatureParamsRow.predictionduration;
    labelmethod        = pmModelParamsRow.labelmethod;
    
    colname = 'PR_AUC';
    resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes.PRAUC);
    colname = 'ROC_AUC';
    resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes.ROCAUC);
    colname = 'Accuracy';
    resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes.Accuracy);
    colname = 'PosAcc';
    resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes.PosAcc);
    colname = 'NegAcc';
    resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes.NegAcc);
    
    pmModelQualityScores = [pmModelQualityScores; resultrow];
end

basedir = setBaseDir();
subfolder = 'ExcelFiles';
outputfilename = sprintf('%s Single Pred Model Quality Scores.xlsx', studydisplayname);
fprintf('Saving results to excel file %s\n', outputfilename);
writetable(pmModelQualityScores, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'Model Quality Scores');


    