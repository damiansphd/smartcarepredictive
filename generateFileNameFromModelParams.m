function [mbasefilename] = generateFileNameFromModelParams(fbasefilename, pmModelParamsRow)

% generateFileNameFromModelParams - updates the base file name by adding 
% the model run parameters

fbasefilename = strrep(fbasefilename, 'pmfp', 'pm');

mbasefilename = sprintf('%slm%d', ...
        fbasefilename, pmModelParamsRow.labelmethod);
    
end

