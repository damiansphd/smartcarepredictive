function [safeparamfile] = selectSafeMthdParamsFile()

% selectSafeMthdParamsFile - select the excel file of safe day methodology
% params to run with

basedir = setBaseDir();
subfolder = 'DataFiles';
matchstring = sprintf('SafeMethodParams*');
safemthdlisting = dir(fullfile(basedir, subfolder, matchstring));

safemthdfiles = cell(size(safemthdlisting,1),1);
for a = 1:size(safemthdfiles,1)
    safemthdfiles{a} = strrep(safemthdlisting(a).name, '.xlsx', '');
end

nfiles = size(safemthdfiles,1);
fprintf('Safe Method Param files available\n');
fprintf('---------------------------------\n');

for i = 1:nfiles
    fprintf('%2d: %s\n', i, safemthdfiles{i});
end
fprintf('\n');

safeparamidx = input('Choose file to use ? ');
if safeparamidx > nfiles 
    fprintf('Invalid choice\n');
    return;
end
if isequal(safeparamidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

safeparamfile = safemthdfiles{safeparamidx};

end

