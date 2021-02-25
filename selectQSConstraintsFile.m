function [qsconstrfile, validresponse] = selectQSConstraintsFile()

% selectQSConstraintsFile - select the excel file containing the list of
% quality score constraints and thresholds to be used to determine the
% labels for the quality classifier

basedir = setBaseDir();
subfolder = 'DataFiles';
matchstring = 'QC-QSConstr-*';
qsconstrlisting = dir(fullfile(basedir, subfolder, matchstring));

qsconstrfiles = cell(size(qsconstrlisting,1),1);
for a = 1:size(qsconstrfiles,1)
    qsconstrfiles{a} = strrep(qsconstrlisting(a).name, '.mat', '');
end

nfiles = size(qsconstrfiles,1);
fprintf('QC - quality score constraints files available\n');
fprintf('----------------------------------------------\n');

for i = 1:nfiles
    fprintf('%2d: %s\n', i, qsconstrfiles{i});
end
fprintf('\n');

sfileidx = input('Choose file to use ? ', 's');

fileidx = str2double(sfileidx);

if (isnan(fileidx) || fileidx < 1 || fileidx > nfiles)
    fprintf('Invalid choice\n');
    validresponse = false;
    qsconstrfile = 'N/A';
    fprintf('\n');
    return;
else
    validresponse = true;
    qsconstrfile = qsconstrfiles{fileidx};
    fprintf('\n');
end

end

