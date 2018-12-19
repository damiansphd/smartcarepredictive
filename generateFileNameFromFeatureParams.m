function [basefilename] = generateFileNameFromFeatureParams(pmFeatureParamsRow)

% generateFileNameFromFeatureParams - generates the base file name from a
% set of feature parameters

basefilename = sprintf('pmfp_%s_st%s_fd%d_pd%d_mm%d_nm%d_bf%d_nb%d_sm%d_rn%d_vo%d', ...
        pmFeatureParamsRow.Version{1},          pmFeatureParamsRow.StudyDisplayName{1}, ...
        pmFeatureParamsRow.featureduration,     pmFeatureParamsRow.predictionduration,  ...
        pmFeatureParamsRow.rawmeasfeat,         pmFeatureParamsRow.normmethod, ...
        pmFeatureParamsRow.bucketfeat,          pmFeatureParamsRow.nbuckets, ...
        pmFeatureParamsRow.smoothingmethod,     pmFeatureParamsRow.rangefeat, ...
        pmFeatureParamsRow.volfeat);
    
end

