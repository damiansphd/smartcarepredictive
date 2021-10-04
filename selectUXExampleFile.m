function [uxfile, validresponse] = selectUXExampleFile()

% selectUXExampleFile - convenience function to select the excel file of
% UX Vizualisation examples

basedir = setBaseDir();
subfolder = 'DataFiles';
matchstring = sprintf('UXViz*');
uxfilelisting = dir(fullfile(basedir, subfolder, matchstring));

uxfiles = cell(size(uxfilelisting,1),1);
for a = 1:size(uxfiles,1)
    uxfiles{a} = strrep(uxfilelisting(a).name, '.xlsx', '');
end

nfiles = size(uxfiles,1);
fprintf('UX Viz example files available\n');
fprintf('------------------------------\n');

for i = 1:nfiles
    fprintf('%2d: %s\n', i, uxfiles{i});
end
fprintf('\n');

suxidx = input('Choose file to use ? ', 's');
uxidx = str2double(suxidx);

if (isnan(uxidx) || uxidx < 1 || uxidx > nfiles)
    fprintf('Invalid choice\n');
    uxfile = '';
    validresponse = false;
else
    uxfile = uxfiles{uxidx};
    validresponse = true;
end

fprintf('\n');

end


