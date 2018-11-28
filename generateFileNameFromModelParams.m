function [mbasefilename] = generateFileNameFromModelParams(fbasefilename, pmModelParamRow)

% generateFileNameFromModelParams - updates the base file name by adding 
% the model run parameters

fbasefilename = strrep(fbasefilename, 'pmfp', 'pm');

mbasefilename = sprintf('%s_lm%d', ...
        fbasefilename, pmModelParamRow.labelmethod);
    
end

