function [basedir] = setBaseDir()

% setBaseDir - sets the root directory for the code, plots, data files etc


if ismember(computer, {'MACI64'})
    username = getenv('USER');
else
    username = getenv('USERNAME');
end

basedir = sprintf('/Users/%s/OneDrive - University of Cambridge/Documents/PredictiveModel/', username);

end
