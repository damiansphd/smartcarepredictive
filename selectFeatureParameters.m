function [modelrpfile, moderplidx, modelrunparams] = selectFeatureParameters()

% selectFeatureParameters - select the matlab saved variable file for the 
% combinations of parameters to create features and labels for

basedir = setBaseDir();
subfolder = 'DataFiles';
modelinputslisting = dir(fullfile(basedir, subfolder, 'pmfp*.xlsx'));
modelrunparams = cell(size(modelinputslisting,1),1);
for a = 1:size(modelrunparams,1)
    modelrunparams{a} = strrep(modelinputslisting(a).name, '.xlsx', '');
end

nmodels = size(modelrunparams,1);
fprintf('Feature parameter files available\n');
fprintf('---------------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, modelrunparams{i});
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

modelrpfile = modelrunparams{moderplidx};

end

