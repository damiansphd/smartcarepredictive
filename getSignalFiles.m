function [signalfiles, nsignalfiles] = getSignalFiles(study, signaldir, basesignalfilename)

% getBreatheScoreFiles - get a list of breathe score files for a given
% study

basedir = setBaseDir();
subfolder = sprintf('DataFiles/%s/%s', signaldir, study);
matchstring = sprintf('%s-*.csv', basesignalfilename);

signalfilelisting = dir(fullfile(basedir, subfolder, matchstring));

signalfiles = cell(size(signalfilelisting,1),1);
for a = 1:size(signalfiles,1)
    signalfiles{a} = signalfilelisting(a).name;
end

nsignalfiles = size(signalfiles,1);
fprintf('Signal Files found\n');
fprintf('------------------\n');

for i = 1:nsignalfiles
    fprintf('%2d: %s\n', i, signalfiles{i});
end
fprintf('\n');

end

