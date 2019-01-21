function [resultrow] = setTableDisplayRow(pmFeatureParamsRow, pmModelParamsRow, pmModelRes, measures, nmeasures)

% setTableDisplayRow - creates the tabular results row for a given model
% results file (with less cryptic values for parameters)

resultrow = table('Size',[1 18], ...
    'VariableTypes', {'cell', 'cell', 'double', 'double', ...
                      'cell', 'cell', 'cell', 'cell', 'double', ...
                      'cell', 'cell','cell', 'cell', ...
                      'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Version', 'StudyDisplayName', 'FeatureDuration', 'LabelMethod', ...
                      'NormMethod', 'Smoothing', 'RawMeas', 'BucketMeas', 'NumBuckets',  ...
                      'Range', 'Volatility', 'DateFeat', 'DemoFeat', ...
                      'PR_AUC', 'ROC_AUC', 'Accuracy', 'PosAcc', 'NegAcc'});

resultrow.Version     = pmModelParamsRow.Version;
resultrow.StudyDisplayName = pmFeatureParamsRow.StudyDisplayName;
resultrow.FeatureDuration  = pmFeatureParamsRow.featureduration;
resultrow.LabelMethod = pmModelParamsRow.labelmethod;

if pmFeatureParamsRow.normmethod == 1
    resultrow.NormMethod = {'1:Overall'};
elseif pmFeatureParamsRow.normmethod == 2
    resultrow.NormMethod = {'2:Patient'};
end

if pmFeatureParamsRow.smoothingmethod == 1
    resultrow.Smoothing = {'1:N'};
elseif pmFeatureParamsRow.smoothingmethod == 2
    resultrow.Smoothing = {'2:Y'};
end

if sum(measures.RawMeas) == 0
    rawtext = 'None';
elseif sum(measures.RawMeas) == nmeasures
    rawtext = 'All';
elseif (sum(measures.RawMeas) > 0)
    rawtext = strcat(measures.ShortName{logical(measures.RawMeas)});
end
resultrow.RawMeas = {sprintf('%d:%s', pmFeatureParamsRow.rawmeasfeat, rawtext)};

if sum(measures.BucketMeas) == 0
    bucktext = 'None';
elseif sum(measures.BucketMeas) == nmeasures
    bucktext = 'All';
else
    bucktext = strcat(measures.ShortName{logical(measures.BucketMeas)});
end
resultrow.BucketMeas = {sprintf('%d:%s', pmFeatureParamsRow.bucketfeat, bucktext)};

resultrow.NumBuckets = pmFeatureParamsRow.nbuckets;

if sum(measures.Range) == 0
    rangetext = 'None';
elseif sum(measures.Range) == nmeasures
    rangetext = 'All';
else
    rangetext = strcat(measures.ShortName{logical(measures.Range)});
end
resultrow.Range = {sprintf('%d:%s', pmFeatureParamsRow.rangefeat, rangetext)};

if sum(measures.Volatility) == 0
    voltext = 'None';
elseif sum(measures.Volatility) == nmeasures    
    voltext= 'All';
else
    %voltext= strcat(sprintf('%d:', pmFeatureParamsRow.volfeat), measures.ShortName{logical(measures.Volatility)})};
    voltext= strcat(measures.ShortName{logical(measures.Volatility)});
end
resultrow.Volatility = {sprintf('%d:%s', pmFeatureParamsRow.volfeat, voltext)};

if pmFeatureParamsRow.monthfeat == 0
    datetext = 'None';
elseif pmFeatureParamsRow.monthfeat == 1
    datetext = 'SinCos';
elseif pmFeatureParamsRow.monthfeat > 1
    datetext = sprintf('Buck%d', pmFeatureParamsRow.monthfeat);
end
resultrow.DateFeat = {sprintf('%d:%s', pmFeatureParamsRow.monthfeat, datetext)};

if pmFeatureParamsRow.demofeat == 1
    demotext = 'None';
elseif pmFeatureParamsRow.demofeat == 2
    demotext = 'All';
elseif pmFeatureParamsRow.demofeat == 3
    demotext = 'Age';
elseif pmFeatureParamsRow.demofeat == 4
    demotext = 'Height';
elseif pmFeatureParamsRow.demofeat == 5
    demotext = 'Weight';
elseif pmFeatureParamsRow.demofeat == 6
    demotext = 'PredFEV1';
elseif pmFeatureParamsRow.demofeat == 7
    demotext =  'Sex';
end
resultrow.DemoFeat = {sprintf('%d:%s', pmFeatureParamsRow.demofeat, demotext)};

resultrow.PR_AUC   = pmModelRes.pmNDayRes.PRAUC;
resultrow.ROC_AUC  = pmModelRes.pmNDayRes.ROCAUC;
resultrow.Accuracy = pmModelRes.pmNDayRes.Accuracy;
resultrow.PosAcc   = pmModelRes.pmNDayRes.PosAcc;
resultrow.NegAcc   = pmModelRes.pmNDayRes.NegAcc;  

end

