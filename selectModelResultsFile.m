function [modelrpfile] = selectModelResultsFile()

% selectModelResultsFile - select the matlab saved variable file for the model
% results file

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
modelresultslisting = dir(fullfile(basedir, subfolder, 'pm*ModelResults.mat'));
modelresultsfiles = cell(size(modelresultslisting,1),1);
for a = 1:size(modelresultsfiles,1)
    modelresultsfiles{a} = strrep(modelresultslisting(a).name, '.mat', '');
end

nmodels = size(modelresultsfiles,1);
fprintf('Model parameter files available\n');
fprintf('-------------------------------\n');

for i = 1:nmodels
    fprintf('%d: %s\n', i, modelresultsfiles{i});
end
fprintf('\n');

moderplidx = input('Choose file to use ? ');
if moderplidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(moderplidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

modelrpfile = modelresultsfiles{moderplidx};

end

