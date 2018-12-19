clear; close all; clc;

[~, studydisplayname, ~] = selectStudy();
[selectdays, focusopt] = setFocusDays();

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
    
    resultrow = pmFeatureParamsRow;
    resultrow(:,{'StudyNbr', 'modelinputsmatfile'}) = [];
    resultrow.Version(:)     = pmModelParamsRow.Version;
    resultrow.labelmethod(:) = pmModelParamsRow.labelmethod;
    resultrow.lambda(:)      = pmModelParamsRow.lambda;
    
    predictionduration = pmFeatureParamsRow.predictionduration;
    labelmethod        = pmModelParamsRow.labelmethod;
    
    for a = 1:predictionduration
        if ismember(a, selectdays)
            colname = sprintf('PR_AUC_Day%d', a);
            resultrow(:,{colname}) = array2table(0.0);
        end
    end
    colname = 'Avg_PR_AUC';
    resultrow(:,{colname}) = array2table(0.0);
    
    for a = 1:predictionduration
        if ismember(a, selectdays)
            colname = sprintf('ROC_AUC_Day%d', a);
            resultrow(:,{colname}) = array2table(0.0);
        end
    end
    colname = 'Avg_ROC_AUC';
    resultrow(:,{colname}) = array2table(0.0);
    
    for a = 1:predictionduration
        if ismember(a, selectdays)
            colname = sprintf('LLH_Day%d', a);
            resultrow(:,{colname}) = array2table(0.0);
        end  
    end
    colname = 'Avg_LLH';
    resultrow(:,{colname}) = array2table(0.0);
    
    for a = 1:predictionduration
        if ismember(a, selectdays)
            colname = sprintf('Iter_Day%d', a);        
            resultrow(:,{colname}) = array2table(0.0);
        end    
    end
    colname = 'Max_Iter';
    resultrow(:,{colname}) = array2table(0.0);
    
    
   
    if labelmethod == 5
        
        avprauc  = pmModelRes.pmNDayRes.PRAUC;
        colname  = 'Avg_PR_AUC';
        resultrow(:,{colname}) = array2table(avprauc);
        
        avrocauc = pmModelRes.pmNDayRes.ROCAUC;
        colname = 'Avg_ROC_AUC';
        resultrow(:,{colname}) = array2table(avrocauc);
        
    else
        
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
    
        avllh = 0;
        for a = 1:predictionduration
            if isequal(pmModelParamsRow.Version{1}, 'vPM2')
                avllh = avllh + pmModelRes.pmNDayRes(a).LLH(size(pmModelRes.pmNDayRes(a).LLH,2));
            end
            if ismember(a, selectdays)
                colname = sprintf('LLH_Day%d', a);
                if isequal(pmModelParamsRow.Version{1}, 'vPM2')
                    resultrow(:,{colname}) = array2table(pmModelRes.pmNDayRes(a).LLH(size(pmModelRes.pmNDayRes(a).LLH,2)));
                else
                    resultrow(:,{colname}) = array2table(0.0);
                end
            end
        end
        avllh = avllh / predictionduration;
        colname = 'Avg_LLH';
        resultrow(:,{colname}) = array2table(avllh);
    
        maxiter = 0;
        for a = 1:predictionduration
            if isequal(pmModelParamsRow.Version{1}, 'vPM2')
                maxiter = max(maxiter,size(pmModelRes.pmNDayRes(a).LLH,2));
            end
            if ismember(a, selectdays)
                colname = sprintf('Iter_Day%d', a);
                if isequal(pmModelParamsRow.Version{1}, 'vPM2')
                    resultrow(:,{colname}) = array2table(size(pmModelRes.pmNDayRes(a).LLH,2));
                else
                    resultrow(:,{colname}) = array2table(0.0);
                end
            end
        end
        colname = 'Max_Iter';
        resultrow(:,{colname}) = array2table(maxiter);
    end
    
    pmModelQualityScores = [pmModelQualityScores; resultrow];
end

basedir = setBaseDir();
subfolder = 'ExcelFiles';
outputfilename = sprintf('%s_fo%d Model Quality Scores.xlsx', studydisplayname, focusopt);
fprintf('Saving results to excel file %s\n', outputfilename);
writetable(pmModelQualityScores, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'Model Quality Scores');


    