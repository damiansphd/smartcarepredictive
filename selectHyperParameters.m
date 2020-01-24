function [modelrpfile, modelrpidx, modelrunparams, validresponse] = selectHyperParameters()

% selectHyperParameters - select the matlab saved variable file for the model
% hyper parameters

basedir = setBaseDir();
subfolder = 'DataFiles';
modelinputslisting = dir(fullfile(basedir, subfolder, 'pmhp*.xlsx'));
modelrunparams = cell(size(modelinputslisting,1),1);
for a = 1:size(modelrunparams,1)
    modelrunparams{a} = strrep(modelinputslisting(a).name, '.xlsx', '');
end

nmodels = size(modelrunparams,1);
fprintf('Hyper parameter files available\n');
fprintf('-------------------------------\n');
fprintf('0: N/A\n');

for i = 1:nmodels
    fprintf('%d: %s\n', i, modelrunparams{i});
end
fprintf('\n');

shpidx = input('Choose hyperparameter file ? ', 's');

modelrpidx = str2double(shpidx);

if (isnan(modelrpidx) || modelrpidx < 0 || modelrpidx > nmodels)
    fprintf('Invalid choice\n');
    validresponse = false;
    modelrpidx = 0;
    modelrpfile = '';
    return;
else
    validresponse = true;
end

fprintf('\n');

if modelrpidx > 0
    modelrpfile = modelrunparams{modelrpidx};
else
    modelrpfile = '';
end

end

