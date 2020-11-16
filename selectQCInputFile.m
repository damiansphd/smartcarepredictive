function [qcinputfile] = selectQCInputFile(fv1, lb1, rm1, filetext)

% selectQCInputFile - select the matlab saved variable file for the
% missingness pattern and quality score data set used by the quality
% classifier

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
matchstring = sprintf('pm%s*rm%d*lm%d*%s.mat', fv1, rm1, lb1, filetext);
qcinputfilelisting = dir(fullfile(basedir, subfolder, matchstring));

qcinputfiles = cell(size(qcinputfilelisting,1),1);
for a = 1:size(qcinputfiles,1)
    qcinputfiles{a} = strrep(qcinputfilelisting(a).name, '.mat', '');
end

nmodels = size(qcinputfiles,1);
fprintf('Quality Classifier input files available\n');
fprintf('----------------------------------------\n');

for i = 1:nmodels
    fprintf('%2d: %s\n', i, qcinputfiles{i});
end
fprintf('\n');

qcinputidx = input('Choose file to use ? ');
if qcinputidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(qcinputidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

qcinputfile = qcinputfiles{qcinputidx};

end

