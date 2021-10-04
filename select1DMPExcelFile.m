function [mpfile, validresponse] = select1DMPExcelFile()

% select1DMPExcelFile - convenience function to select the excel file of
% missingness patterns to check the safety of.

basedir = setBaseDir();
subfolder = 'DataFiles';
matchstring = sprintf('1DMPScen*');
mpfilelisting = dir(fullfile(basedir, subfolder, matchstring));

mpfiles = cell(size(mpfilelisting,1),1);
for a = 1:size(mpfiles,1)
    mpfiles{a} = strrep(mpfilelisting(a).name, '.xlsx', '');
end

nfiles = size(mpfiles,1);
fprintf('Missingness pattern files available\n');
fprintf('-----------------------------------\n');

for i = 1:nfiles
    fprintf('%2d: %s\n', i, mpfiles{i});
end
fprintf('\n');

smpidx = input('Choose file to use ? ', 's');
mpidx = str2double(smpidx);

if (isnan(mpidx) || mpidx < 1 || mpidx > nfiles)
    fprintf('Invalid choice\n');
    mpfile = '';
    validresponse = false;
else
    mpfile = mpfiles{mpidx};
    validresponse = true;
end

fprintf('\n');

end


