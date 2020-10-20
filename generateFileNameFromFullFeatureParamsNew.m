function [outputfilename] = generateFileNameFromFullFeatureParamsNew(pmFeatureParamsRow)

% generateFileNameFromFullFeatureParamsNew - generates the file name from a
% full set of feature parameters for interp fixed version

% for backward compatibility
if ~any(ismember(pmFeatureParamsRow.Properties.VariableNames, {'msfeat'}))
    pmFeatureParamsRow.msfeat = 1;
end
if ~any(ismember(pmFeatureParamsRow.Properties.VariableNames, {'interpmethod'}))
    pmFeatureParamsRow.interpmethod = 1;
end
if ~any(ismember(pmFeatureParamsRow.Properties.VariableNames, {'augmethod'}))
    pmFeatureParamsRow.augmethod = 1;
end
if ~any(ismember(pmFeatureParamsRow.Properties.VariableNames, {'msconst'}))
    pmFeatureParamsRow.msconst = -10;
end
if ~any(ismember(pmFeatureParamsRow.Properties.VariableNames, {'missinterp'}))
    pmFeatureParamsRow.msconst = 1;
end

outputfilename = sprintf('pmfp%sst%sfd%dnm%dnw%dsf%dsw%dsl%dip%dau%dmc%dmi%drm%dms%dvo%dpm%d', ...
        pmFeatureParamsRow.FeatVer{1},          pmFeatureParamsRow.StudyDisplayName{1}, ...
        pmFeatureParamsRow.featureduration,     pmFeatureParamsRow.normmethod, ...
        pmFeatureParamsRow.normwindow,          pmFeatureParamsRow.smfunction, ...
        pmFeatureParamsRow.smwindow,            pmFeatureParamsRow.smlength, ...
        pmFeatureParamsRow.interpmethod,        pmFeatureParamsRow.augmethod, ...
        pmFeatureParamsRow.msconst,             pmFeatureParamsRow.missinterp, ...
        pmFeatureParamsRow.rawmeasfeat,         pmFeatureParamsRow.msfeat, ...             
        pmFeatureParamsRow.volfeat,             pmFeatureParamsRow.pmeanfeat);
    
end

