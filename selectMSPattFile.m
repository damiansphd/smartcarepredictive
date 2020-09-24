function [mspattfile] = selectMSPattFile(fv1, lb1, rm1)

% selectMSPattFile - select the matlab saved variable file for the
% missingness pattern and quality score data set

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
matchstring = sprintf('pm%s*rm%d*lm%d*MPRes.mat', fv1, rm1, lb1);
mspattfilelisting = dir(fullfile(basedir, subfolder, matchstring));

mspattfiles = cell(size(mspattfilelisting,1),1);
for a = 1:size(mspattfiles,1)
    mspattfiles{a} = strrep(mspattfilelisting(a).name, '.mat', '');
end

nmodels = size(mspattfiles,1);
fprintf('Model results files available\n');
fprintf('-----------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, mspattfiles{i});
end
fprintf('\n');

mspattidx = input('Choose file to use ? ');
if mspattidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(mspattidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

mspattfile = mspattfiles{mspattidx};

end

