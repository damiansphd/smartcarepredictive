function [basefilename] = generateFileNameFromFeatureParams(pmFeatureParamsRow)

% generateFileNameFromFeatureParams - generates the base file name from a
% set of feature parameters

basefilename = sprintf('pmfp_%s_st%s_fd%d_pd%d_nm%d_sm%d_rm%d_bf%d_nb%d_rn%d_vo%d_as%d_na%d_vs%d_nv%d_cc%d_mf%d_dm%d', ...
        pmFeatureParamsRow.Version{1},          pmFeatureParamsRow.StudyDisplayName{1}, ...
        pmFeatureParamsRow.featureduration,     pmFeatureParamsRow.predictionduration,  ...
        pmFeatureParamsRow.normmethod,          pmFeatureParamsRow.smoothingmethod, ...
        pmFeatureParamsRow.rawmeasfeat,         pmFeatureParamsRow.bucketfeat, ...
        pmFeatureParamsRow.nbuckets,            pmFeatureParamsRow.rangefeat, ...
        pmFeatureParamsRow.volfeat,             pmFeatureParamsRow.avgsegfeat, ...
        pmFeatureParamsRow.navgseg,             pmFeatureParamsRow.volsegfeat, ...
        pmFeatureParamsRow.nvolseg,             pmFeatureParamsRow.cchangefeat, ...
        pmFeatureParamsRow.monthfeat,           pmFeatureParamsRow.demofeat);
    
     
    
end

