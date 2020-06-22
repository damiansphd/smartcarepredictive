function [msfile, isvalid, msidx, msfiles] = selectMissingnessFile()

% selectMissingnessFile - select the excel file with the missingness
% scenarios to run

isvalid = true;

basedir = setBaseDir();
subfolder = 'DataFiles';
msfilelisting = dir(fullfile(basedir, subfolder, '*MSEx*.xlsx'));
msfiles = cell(size(msfilelisting,1),1);
for a = 1:size(msfiles,1)
    msfiles{a} = strrep(msfilelisting(a).name, '.xlsx', '');
end

nmsfiles = size(msfiles,1);
fprintf('Missingness files available\n');
fprintf('---------------------------\n');
for i = 1:nmsfiles
    fprintf('%d: %s\n', i, msfiles{i});
end
fprintf('\n');

smsidx = input('Choose model run to use ? ', 's');

msidx = str2double(smsidx);

if (isnan(msidx) || msidx < 1 || msidx > nmsfiles)
    fprintf('Invalid choice\n');
    msidx = -1;
    msfile = '**';
    isvalid = false;
    return;
end

fprintf('\n');

msfile = msfiles{msidx};

end

