function [mbasefilename] = generateFileNameFromModelParams(fbasefilename, pmModelParamRow)

% generateFileNameFromModelParams - updates the base file name by adding 
% the model run parameters

fbasefilename = strrep(fbasefilename, 'pmfp', 'pm');

mbasefilename = sprintf('%s_lm%d_rg%.2f', ...
        fbasefilename, pmModelParamRow.labelmethod, pmModelParamRow.lambda);
    
end

