function [mpresultsfile] = selectMPResultsFile(fv1, lb1, rm1)

% selectMPResultsFile - select the matlab saved variable file for the
% missingness pattern results file given a label type and a raw measure combinations

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
matchstring = sprintf('pm%s*rm%d*lm%d*MPRes.mat', fv1, rm1, lb1);
mpresultslisting = dir(fullfile(basedir, subfolder, matchstring));

mpresultsfiles = cell(size(mpresultslisting,1),1);
for a = 1:size(mpresultsfiles,1)
    mpresultsfiles{a} = strrep(mpresultslisting(a).name, '.mat', '');
end

nmodels = size(mpresultsfiles,1);
fprintf('Missingness pattern results files available\n');
fprintf('-------------------------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, mpresultsfiles{i});
end
fprintf('\n');

mpresidx = input('Choose file to use ? ');
if mpresidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(mpresidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

mpresultsfile = mpresultsfiles{mpresidx};

end

