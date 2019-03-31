function [basefilename] = generateFileNameFromBaseFeatureParams(pmBaseFeatureParamsRow)

% generateFileNameFromBaseFeatureParams - generates the base file name from a
% set of base feature parameters

basefilename = sprintf('pmbfp%sst%sfd%dpd%dnm%dnw%dsf%dsw%dsl%dnb%dna%dnv%dnp%ddf%d', ...
        pmBaseFeatureParamsRow.FeatVer{1},          pmBaseFeatureParamsRow.StudyDisplayName{1}, ...
        pmBaseFeatureParamsRow.featureduration,     pmBaseFeatureParamsRow.predictionduration, ...
        pmBaseFeatureParamsRow.normmethod,          pmBaseFeatureParamsRow.normwindow, ...
        pmBaseFeatureParamsRow.smfunction,          pmBaseFeatureParamsRow.smwindow, ...
        pmBaseFeatureParamsRow.smlength,            pmBaseFeatureParamsRow.nbuckets, ...         
        pmBaseFeatureParamsRow.navgseg,             pmBaseFeatureParamsRow.nvolseg, ...
        pmBaseFeatureParamsRow.nbuckpmeas,          pmBaseFeatureParamsRow.datefeat);
    
end

