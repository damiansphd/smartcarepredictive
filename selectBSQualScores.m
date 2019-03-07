function [bsqsfile] = selectBSQualScores(studydisplayname, labelstring)

% selectBSQualScores - select the matlab saved variable file for the 
% set of saved bootstrap quality scores to analyse

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
bsqsinputslisting = dir(fullfile(basedir, subfolder, sprintf('BSQ*%s*%s*.mat', studydisplayname, labelstring)));
bsqsinputs = cell(size(bsqsinputslisting,1),1);
for a = 1:size(bsqsinputs,1)
    bsqsinputs{a} = bsqsinputslisting(a).name;
end

ncombinations = size(bsqsinputs,1);
fprintf('Bootstrap Quality Score files available\n');
fprintf('---------------------------------------\n');

for i = 1:ncombinations
    fprintf('%2d: %s\n', i, bsqsinputs{i});
end
fprintf('\n');

bsqsidx = input('Choose file to use ? ');
if bsqsidx > ncombinations 
    fprintf('Invalid choice\n');
    return;
end
if isequal(bsqsidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

bsqsfile = bsqsinputs{bsqsidx};

end

