function [mbasefilename] = generateFileNameFromFullModelParams(fbasefilename, pmModelParamsRow)

% generateFileNameFromModelParams - updates the base file name by adding 
% the model run parameters

fbasefilename = strrep(fbasefilename, 'pmfp', 'pm');
fbasefilename = strrep(fbasefilename, 'pmmfp', 'pm');

mbasefilename = sprintf('%smv%slm%d', ...
        fbasefilename, pmModelParamsRow.ModelVer{1}, pmModelParamsRow.labelmethod);
    
end

