function [outputfilename] = generateFileNameFromModFeatureParams(pmModFeatParamsRow)

% generateFileNameFromModFeatureParams - generates the file name from a
% set of model feature parameters for data window version

outputfilename = sprintf('pmmfp%sst%sfd%dnw%dau%dnm%dsf%dsw%dsl%dip%dmc%dmi%drm%dms%dvo%dpm%d', ...
        pmModFeatParamsRow.FeatVer{1},          pmModFeatParamsRow.StudyDisplayName{1}, ...
        pmModFeatParamsRow.datawinduration,     pmModFeatParamsRow.normwinduration, ...
        pmModFeatParamsRow.augmethod,           pmModFeatParamsRow.normmethod, ...
        pmModFeatParamsRow.smfunction,          pmModFeatParamsRow.smwindow, ...
        pmModFeatParamsRow.smlength,            pmModFeatParamsRow.interpmethod, ...
        pmModFeatParamsRow.msconst,             pmModFeatParamsRow.missinterp, ...
        pmModFeatParamsRow.rawmeasfeat,         pmModFeatParamsRow.msfeat, ...             
        pmModFeatParamsRow.volfeat,             pmModFeatParamsRow.pmeanfeat);
    
end

