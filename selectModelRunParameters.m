function [modelrpfile, moderplidx, modelrunparams] = selectModelRunParameters()

% selectModelRunParameters - select the matlab saved variable file for the model
% run parameters

basedir = setBaseDir();
subfolder = 'DataFiles';
modelinputslisting = dir(fullfile(basedir, subfolder, 'pm*.xlsx'));
modelrunparams = cell(size(modelinputslisting,1),1);
for a = 1:size(modelrunparams,1)
    modelrunparams{a} = strrep(modelinputslisting(a).name, '.xlsx', '');
end

nmodels = size(modelrunparams,1);
fprintf('Run parameter files available\n');
fprintf('-----------------------------\n');

for i = 1:nmodels
    fprintf('%d: %s\n', i, modelrunparams{i});
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

