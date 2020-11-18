function [qcinputfiles, nbatchfiles] = getQCBatchInputFiles(baseqcinputfile, batchsize)

% getQCBatchInputFiles - get a list of QC batch input files for a given trained 
%inner (predictive) classifier 

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
matchstring = sprintf('%sB%d*.mat', baseqcinputfile, batchsize);
qcinputfilelisting = dir(fullfile(basedir, subfolder, matchstring));

qcinputfiles = cell(size(qcinputfilelisting,1),1);
for a = 1:size(qcinputfiles,1)
    qcinputfiles{a} = strrep(qcinputfilelisting(a).name, '.mat', '');
end

nbatchfiles = size(qcinputfiles,1);
fprintf('Quality Classifier batch input files\n');
fprintf('------------------------------------\n');

for i = 1:nbatchfiles
    fprintf('%2d: %s\n', i, qcinputfiles{i});
end
fprintf('\n');

end

