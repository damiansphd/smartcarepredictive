clear; close all; clc;

[~, studydisplayname, ~] = selectStudy();
selectdays = setFocusDays();

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelresultslisting = dir(fullfile(basedir, subfolder, sprintf('pm*%s*ModelResults.mat', studydisplayname)));
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
    
    predictionduration = pmFeatureParamsRow.predictionduration;

    resultrow = pmFeatureParamsRow;
    resultrow(:,{'StudyNbr', 'modelinputsmatfile', 'smoothingmethod', 'minmaxfeat', 'volfeat'}) = [];
    resultrow.Version(:) = pmModelParamsRow.Version;
    resultrow.labelmethod(:) = pmModelParamsRow.labelmethod;
    
    avprauc = 0;
    for a = 1:predictionduration
        avprauc = avprauc + pmModelRes.pmNDayRes(a).PRAUC;
        if ismember(a, selectdays)
            colname = sprintf('PR_AUC_Day%d', a);
            resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes(a).PRAUC);
        end
    end
    avprauc = avprauc / predictionduration;
    colname = 'Avg_PR_AUC';
    resultrow(:,{colname}) = array2table(avprauc);
            
    avrocauc = 0;
    for a = 1:predictionduration
        avrocauc = avrocauc + pmModelRes.pmNDayRes(a).ROCAUC;
        if ismember(a, selectdays)
            colname = sprintf('ROC_AUC_Day%d', a);
            resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes(a).ROCAUC);
        end
    end
    avrocauc = avrocauc / predictionduration;
    colname = 'Avg_ROC_AUC';
    resultrow(:,{colname}) = array2table(avrocauc);
 
    pmModelQualityScores = [pmModelQualityScores; resultrow];
    
end

basedir = setBaseDir();
subfolder = 'ExcelFiles';
outputfilename = sprintf('%s Model Quality Scores.xlsx', studydisplayname);
fprintf('Saving results to excel file %s\n', outputfilename);
writetable(pmModelQualityScores, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'Model Quality Scores');


    