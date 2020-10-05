function [basefilename] = generateFileNameFromBaseFeatureParams(pmBaseFeatureParamsRow)

% generateFileNameFromBaseFeatureParams - generates the base file name from a
% set of base feature parameters

% for backward compatibility
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

basefilename = sprintf('pmbfp%sst%sfd%dpd%dnm%dnw%dsf%dsw%dsl%dip%dau%dmc%dmi%dnb%dna%dnv%dnp%ddf%d', ...
        pmBaseFeatureParamsRow.FeatVer{1},          pmBaseFeatureParamsRow.StudyDisplayName{1}, ...
        pmBaseFeatureParamsRow.featureduration,     pmBaseFeatureParamsRow.predictionduration, ...
        pmBaseFeatureParamsRow.normmethod,          pmBaseFeatureParamsRow.normwindow, ...
        pmBaseFeatureParamsRow.smfunction,          pmBaseFeatureParamsRow.smwindow, ...
        pmBaseFeatureParamsRow.smlength,            pmBaseFeatureParamsRow.interpmethod, ...
        pmBaseFeatureParamsRow.augmethod,           pmBaseFeatureParamsRow.msconst, ...
        pmBaseFeatureParamsRow.missinterp,          pmBaseFeatureParamsRow.nbuckets, ...         
        pmBaseFeatureParamsRow.navgseg,             pmBaseFeatureParamsRow.nvolseg, ...
        pmBaseFeatureParamsRow.nbuckpmeas,          pmBaseFeatureParamsRow.datefeat);
    
end

