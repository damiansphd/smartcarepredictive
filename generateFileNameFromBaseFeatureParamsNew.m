function [basefilename] = generateFileNameFromBaseFeatureParamsNew(pmBaseFeatureParamsRow)

% generateFileNameFromBaseFeatureParamsNew - generates the base file name from a
% set of base feature parameters (for the stripped down version fixing
% interpolation issue

% for backward compatibility
if ~any(ismember(pmBaseFeatureParamsRow.Properties.VariableNames, {'msfeat'}))
    pmBaseFeatureParamsRow.msfeat = 1;
end
if ~any(ismember(pmBaseFeatureParamsRow.Properties.VariableNames, {'interpmethod'}))
    pmBaseFeatureParamsRow.interpmethod = 1;
end
if ~any(ismember(pmBaseFeatureParamsRow.Properties.VariableNames, {'augmethod'}))
    pmBaseFeatureParamsRow.augmethod = 1;
end
if ~any(ismember(pmBaseFeatureParamsRow.Properties.VariableNames, {'msconst'}))
    pmBaseFeatureParamsRow.msconst = -10;
end
if ~any(ismember(pmBaseFeatureParamsRow.Properties.VariableNames, {'missinterp'}))
    pmBaseFeatureParamsRow.msconst = 1;
end

basefilename = sprintf('pmbfp%sst%sfd%dnm%dnw%dsf%dsw%dsl%dip%dau%dmc%dmi%d', ...
        pmBaseFeatureParamsRow.FeatVer{1},          pmBaseFeatureParamsRow.StudyDisplayName{1}, ...
        pmBaseFeatureParamsRow.featureduration,     pmBaseFeatureParamsRow.normmethod, ...
        pmBaseFeatureParamsRow.normwindow,          pmBaseFeatureParamsRow.smfunction, ...
        pmBaseFeatureParamsRow.smwindow,            pmBaseFeatureParamsRow.smlength, ...
        pmBaseFeatureParamsRow.interpmethod,        pmBaseFeatureParamsRow.augmethod, ...
        pmBaseFeatureParamsRow.msconst,             pmBaseFeatureParamsRow.missinterp);
    
end

