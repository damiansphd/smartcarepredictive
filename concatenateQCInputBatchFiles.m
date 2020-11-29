function [pmFullMissPattIndex, pmFullMissPattArray, pmFullMissPattQS, pmFullMissPattQSPct] = concatenateQCInputBatchFiles(qcinputfiles, nbatchfiles)

% concatenateQCInputBatchFiles - function to create a concatenated data-set
% for the quality classifier across all the batched files

pmFullMissPattIndex = [];
pmFullMissPattArray = [];
pmFullMissPattQS    = [];
pmFullMissPattQSPct = [];

for f = 1:nbatchfiles
    fprintf('%d of %d: Processing file %s\n', f, nbatchfiles, qcinputfiles{f});
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    load(fullfile(basedir, subfolder, qcinputfiles{f}), ...
        'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct');
    
    pmFullMissPattIndex = [pmFullMissPattIndex; pmMissPattIndex];
    pmFullMissPattArray = [pmFullMissPattArray; pmMissPattArray];
    pmFullMissPattQS    = [pmFullMissPattQS   ; pmMissPattQS   ];
    pmFullMissPattQSPct = [pmFullMissPattQSPct; pmMissPattQSPct];
    
end

fprintf('\n');

end

