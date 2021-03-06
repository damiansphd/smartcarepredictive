function [modelrpfile, modelrpidx, modelrunparams, validresponse] = selectModelRunParameters()

% selectModelRunParameters - select the matlab saved variable file for the model
% run parameters

basedir = setBaseDir();
subfolder = 'DataFiles';
modelinputslisting = dir(fullfile(basedir, subfolder, 'pmmp*.xlsx'));
modelrunparams = cell(size(modelinputslisting,1),1);
for a = 1:size(modelrunparams,1)
    modelrunparams{a} = strrep(modelinputslisting(a).name, '.xlsx', '');
end

nmodels = size(modelrunparams,1);
fprintf('Model parameter files available\n');
fprintf('-------------------------------\n');

for i = 1:nmodels
    fprintf('%d: %s\n', i, modelrunparams{i});
end
fprintf('\n');

smodelrpidx = input('Choose file to use ? ', 's');

modelrpidx = str2double(smodelrpidx);

if (isnan(modelrpidx) || modelrpidx < 1 || modelrpidx > nmodels)
    fprintf('Invalid choice\n');
    validresponse = false;
    modelrpidx = 0;
    modelrpfile = '';
    return;
else
    validresponse = true;
end

fprintf('\n');

modelrpfile = modelrunparams{modelrpidx};

end

