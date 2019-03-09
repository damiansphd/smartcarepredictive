function [basefilename] = generateFileNameFromFeatureParams(pmFeatureParamsRow)

% generateFileNameFromFeatureParams - generates the base file name from a
% set of feature parameters

basefilename = sprintf('pmfp%sst%sfd%dff%dpd%dnm%dnw%dsf%dsw%dsl%drm%dbf%dnb%drn%dvo%das%dna%dvs%dnv%dcc%dpm%dps%dbm%dbs%dnp%dmf%ddm%d', ...
        pmFeatureParamsRow.Version{1},          pmFeatureParamsRow.StudyDisplayName{1}, ...
        pmFeatureParamsRow.featureduration,     pmFeatureParamsRow.featfreq, ...
        pmFeatureParamsRow.predictionduration,  pmFeatureParamsRow.normmethod, ...
        pmFeatureParamsRow.normwindow,          pmFeatureParamsRow.smfunction, ...
        pmFeatureParamsRow.smwindow,            pmFeatureParamsRow.smlength, ...
        pmFeatureParamsRow.rawmeasfeat,         pmFeatureParamsRow.bucketfeat, ...
        pmFeatureParamsRow.nbuckets,            pmFeatureParamsRow.rangefeat, ...
        pmFeatureParamsRow.volfeat,             pmFeatureParamsRow.avgsegfeat, ...
        pmFeatureParamsRow.navgseg,             pmFeatureParamsRow.volsegfeat, ...
        pmFeatureParamsRow.nvolseg,             pmFeatureParamsRow.cchangefeat, ...
        pmFeatureParamsRow.pmeanfeat,           pmFeatureParamsRow.pstdfeat, ...
        pmFeatureParamsRow.buckpmean,           pmFeatureParamsRow.buckpstd, ...
        pmFeatureParamsRow.nbuckpmeas, ...
        pmFeatureParamsRow.monthfeat,           pmFeatureParamsRow.demofeat);
    
     
    
end

