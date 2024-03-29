function [modelrpfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext)

% selectQCModelResultsFile - select the matlab saved variable file for the 
% quality classifier model results file given a feature version, a label type 
% and a raw measure combinations

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
matchstring = sprintf('pm%s*rm%d*lm%d*%s*.mat', fv1, rm1, lb1, typetext);
modelresultslisting = dir(fullfile(basedir, subfolder, matchstring));

modelresultsfiles = cell(size(modelresultslisting,1),1);
for a = 1:size(modelresultsfiles,1)
    modelresultsfiles{a} = strrep(modelresultslisting(a).name, '.mat', '');
end

nmodels = size(modelresultsfiles,1);
fprintf('Model results files available\n');
fprintf('-----------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, modelresultsfiles{i});
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

