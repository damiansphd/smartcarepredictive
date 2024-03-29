function [datawinfilename] = generateFileNameFromDataWinParams(pmDataWinParamsRow)

% generateFileNameFromDataWinParams - generates the data window file name from a
% set of data window parameters 

datawinfilename = sprintf('pmdwp%sst%sdw%dnw%dau%drd%d', ...
        pmDataWinParamsRow.FeatVer{1},          pmDataWinParamsRow.StudyDisplayName{1}, ...
        pmDataWinParamsRow.datawinduration,     pmDataWinParamsRow.normwinduration, ...
        pmDataWinParamsRow.augmethod,           pmDataWinParamsRow.rundays);
    
end

