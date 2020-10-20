function [resultrow, resultstring] = setBSQSTableDisplayRowNew(pmFeatureParamsRow, pmModelParamsRow, modeldayres, measures, nmeasures)

% setBSQSTableDisplayRowNew - creates the tabular BootStrap Quality Score results 
% row for a given model results file (with less cryptic values for
% parameters).
% Also creates the less crytpic feature combination as a string.

resultrow = table('Size',[1 43], ...
    'VariableTypes', {'cell', 'cell', 'cell', 'double', 'double', ...
                      'cell', 'double', 'cell', 'cell', 'double', 'cell', ...
                      'cell', 'double', 'cell', ...
                      'cell', 'cell', 'cell', 'cell', ...
                      'cell', 'cell', 'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double'}, ...
    'VariableNames', {'FeatVer', 'ModelVer', 'StudyDisplayName', 'FeatureDuration', 'LabelMethod', ...
                      'NormMethod', 'NormWindow', 'SmFunction', 'SmWindow', 'SmLength', 'InterpMthd', ...
                      'AugMthd', 'MSConst', 'MissInterp', ...
                      'RawMeas', 'MSMeas', 'Volatility', 'PMean', ...
                      'PScore', 'ElecPScore', 'AvgEPV', 'AvgEpiTPred', 'AvgEpiFPred', ...
                      'PRAUC', 'ROCAUC', 'Acc', 'PosAcc', 'NegAcc', ...
                      'PRAUC_AvR', 'PRAUCBestR', 'PRAUCWorstR', ...
                      'ROCAUC_AvR', 'ROCAUCBestR', 'ROCAUCWorstR', ...
                      'Acc_AvR', 'AccBestR', 'AccWorstR', ...
                      'PosAcc_AvR', 'PosAccBestR', 'PosAccWorstR', ...
                      'NegAcc_AvR', 'NegAccBestR', 'NegAccWorstR'});

resultrow.FeatVer     = pmFeatureParamsRow.FeatVer;
resultrow.ModelVer    = pmModelParamsRow.ModelVer;

resultrow.StudyDisplayName = pmFeatureParamsRow.StudyDisplayName;
resultrow.FeatureDuration  = pmFeatureParamsRow.featureduration;
resultrow.LabelMethod = pmModelParamsRow.labelmethod;

if pmFeatureParamsRow.normmethod == 1
    resultrow.NormMethod = {'1:MuOvSigOv'};
elseif pmFeatureParamsRow.normmethod == 2
    resultrow.NormMethod = {'2:MuPtSigPt'};
elseif pmFeatureParamsRow.normmethod == 3
    resultrow.NormMethod = {'3:MuWnSigPt'};
elseif pmFeatureParamsRow.normmethod == 4
    resultrow.NormMethod = {'4:MuWnSigOv'};  
end

resultrow.NormWindow = pmFeatureParamsRow.normwindow;

if pmFeatureParamsRow.smfunction == 0
    resultrow.SmFunction = {'0:None'};
elseif pmFeatureParamsRow.smfunction == 1
    resultrow.SmFunction = {'1:Mean'};
elseif pmFeatureParamsRow.smfunction == 2
    resultrow.SmFunction = {'2:Median'};
elseif pmFeatureParamsRow.smfunction == 3
    resultrow.SmFunction = {'3:FMaxOMean'};
elseif pmFeatureParamsRow.smfunction == 4
    resultrow.SmFunction = {'4:FMaxONone'}; 
end

if pmFeatureParamsRow.smwindow == 0
    resultrow.SmWindow = {'0:None'};
elseif pmFeatureParamsRow.smwindow == 1
    resultrow.SmWindow = {'1:Center'};
elseif pmFeatureParamsRow.smwindow == 2
    resultrow.SmWindow = {'2:Trail'};
end

resultrow.SmLength = pmFeatureParamsRow.smlength;

if pmFeatureParamsRow.interpmethod == 0
    resultrow.InterpMthd = {'0:None'};
elseif pmFeatureParamsRow.interpmethod == 1
    resultrow.InterpMthd = {'1:Full'};
elseif pmFeatureParamsRow.interpmethod >= 2
    resultrow.InterpMthd = {sprintf('%d:Range%dd', pmFeatureParamsRow.interpmethod, (pmFeatureParamsRow.interpmethod - 1))};
end

if pmFeatureParamsRow.augmethod == 1
    resultrow.AugMthd = {'1:Reg'};
elseif pmFeatureParamsRow.augmethod >= 2
    resultrow.AugMthd = {sprintf('%d:Aug',pmFeatureParamsRow.augmethod)};
end

resultrow.MSConst = pmFeatureParamsRow.msconst;

if pmFeatureParamsRow.missinterp == 1
    resultrow.MissInterp = {'1:After'};
elseif pmFeatureParamsRow.missinterp == 2
    resultrow.MissInterp = {'2:Before'};
end

resultstring = sprintf('pmfv%smv%sst%slm%d|fd%d|nm%snw%d|sf%ssw%ssl%d|ip%sau%smc%dmi%s|', resultrow.FeatVer{1}, resultrow.ModelVer{1}, ...
    resultrow.StudyDisplayName{1}, resultrow.LabelMethod, resultrow.FeatureDuration, ...
    resultrow.NormMethod{1}, resultrow.NormWindow, resultrow.SmFunction{1}, resultrow.SmWindow{1}, resultrow.SmLength, ...
    resultrow.InterpMthd{1}, resultrow.AugMthd{1}, resultrow.MSConst, resultrow.MissInterp{1});

if sum(measures.RawMeas) == 0
    rawtext = 'None';
elseif sum(measures.RawMeas) == nmeasures
    rawtext = 'All';
elseif (sum(measures.RawMeas) > 0)
    rawtext = strcat(measures.ShortName{logical(measures.RawMeas)});
end
resultrow.RawMeas = {sprintf('%d:%s', pmFeatureParamsRow.rawmeasfeat, rawtext)};
if sum(measures.RawMeas)~=0
    resultstring = sprintf('%srm%s|', resultstring, resultrow.RawMeas{1});
end

if sum(measures.MSMeas) == 0
    rawtext = 'None';
elseif sum(measures.MSMeas) == nmeasures
    rawtext = 'All';
elseif (sum(measures.MSMeas) > 0)
    rawtext = strcat(measures.ShortName{logical(measures.MSMeas)});
end
resultrow.MSMeas = {sprintf('%d:%s', pmFeatureParamsRow.msfeat, rawtext)};
if sum(measures.MSMeas)~=0
    resultstring = sprintf('%sms%s|', resultstring, resultrow.MSMeas{1});
end

if sum(measures.Volatility) == 0
    voltext = 'None';
elseif sum(measures.Volatility) == nmeasures    
    voltext= 'All';
else
    voltext= strcat(measures.ShortName{logical(measures.Volatility)});
end
resultrow.Volatility = {sprintf('%d:%s', pmFeatureParamsRow.volfeat, voltext)};
if sum(measures.Volatility) ~= 0
    resultstring = sprintf('%svo%s|', resultstring, resultrow.Volatility{1});
end

if sum(measures.PMean) == 0
    pmeantext = 'None';
elseif sum(measures.PMean) == nmeasures    
    pmeantext= 'All';
else
    pmeantext= strcat(measures.ShortName{logical(measures.PMean)});
end
resultrow.PMean = {sprintf('%d:%s', pmFeatureParamsRow.pmeanfeat, pmeantext)};
if sum(measures.PMean) ~= 0
    resultstring = sprintf('%spm%s|', resultstring, resultrow.PMean{1});
end

resultrow.PScore      = {sprintf('%.1f%% (%d/%d/%d)', modeldayres.PScore, modeldayres.HighP, ...
                            modeldayres.MedP, modeldayres.LowP)};
resultrow.ElecPScore  = {sprintf('%.1f%% (%d/%d/%d)', modeldayres.ElecPScore, modeldayres.ElecHighP, ...
                            modeldayres.ElecMedP, modeldayres.ElecLowP)};
resultrow.AvgEPV      = modeldayres.AvgEPV;
resultrow.AvgEpiTPred = modeldayres.AvgEpiTPred;
resultrow.AvgEpiFPred = modeldayres.AvgEpiFPred;    
resultrow.PRAUC       = modeldayres.PRAUC;
resultrow.ROCAUC      = modeldayres.ROCAUC;
resultrow.Acc         = modeldayres.Acc;
resultrow.PosAcc      = modeldayres.PosAcc;
resultrow.NegAcc      = modeldayres.NegAcc;  

end

