function [datawinrpfile, datawinrpidx, datawinparamrunparams] = selectDataWindowArrayParameters(fv1name)

% selectDataWindowArrayParameters - select the matlab saved variable file for 
% the combinations of parameters to create features and labels for
% a given feature version

basedir = setBaseDir();
subfolder = 'DataFiles';
datawinparaminputslisting = dir(fullfile(basedir, subfolder, sprintf('*pmdwp%s*.xlsx', fv1name)));
datawinparamrunparams = cell(size(datawinparaminputslisting,1),1);
for a = 1:size(datawinparamrunparams,1)
    datawinparamrunparams{a} = strrep(datawinparaminputslisting(a).name, '.xlsx', '');
end

nmodels = size(datawinparamrunparams,1);
fprintf('Feature parameter files available\n');
fprintf('---------------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, datawinparamrunparams{i});
end
fprintf('\n');

datawinrpidx = input('Choose file to use ? ');
if datawinrpidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(datawinrpidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

datawinrpfile = datawinparamrunparams{datawinrpidx};

end

