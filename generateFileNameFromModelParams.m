function [mbasefilename] = generateFileNameFromModelParams(fbasefilename, pmModelParamRow)

% generateFileNameFromModelParams - updates the base file name by adding 
% the model run parameters

fbasefilename = strrep(fbasefilename, 'pmfp', 'pm');

mbasefilename = sprintf('%s_lm%d_cm%.2f_tp%0.2f', ...
        fbasefilename, pmModelParamRow.labelmethod, ...
        pmModelParamRow.costmethod, pmModelParamRow.trainpct);
    
end

