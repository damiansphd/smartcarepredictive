function [basefeatrpfile, basefeatrpidx, basefeatparamrunparams] = selectBaseFeatureParametersNew(fv1name)

% selectFeatureParametersNew - select the matlab saved variable file for 
% the combinations of parameters to create features and labels for
% a given feature version

basedir = setBaseDir();
subfolder = 'DataFiles';
basefeatparaminputslisting = dir(fullfile(basedir, subfolder, sprintf('*pmbfp%s*.xlsx', fv1name)));
basefeatparamrunparams = cell(size(basefeatparaminputslisting,1),1);
for a = 1:size(basefeatparamrunparams,1)
    basefeatparamrunparams{a} = strrep(basefeatparaminputslisting(a).name, '.xlsx', '');
end

nmodels = size(basefeatparamrunparams,1);
fprintf('Feature parameter files available\n');
fprintf('---------------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, basefeatparamrunparams{i});
end
fprintf('\n');

basefeatrpidx = input('Choose file to use ? ');
if basefeatrpidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(basefeatrpidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

basefeatrpfile = basefeatparamrunparams{basefeatrpidx};

end

