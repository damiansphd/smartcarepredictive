function [pmQCDRIndex, pmQCDRArray, pmQCDRPred] = createQCDRTables(nrows, nfeats)

% createQCDRTables - creates the missingness pattern tables

pmQCDRIndex = table('Size',[nrows, 8], ...
    'VariableTypes', {'double', 'cell', 'cell', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Iteration', 'MoveType', 'MoveDesc', 'Measure', 'Frequency', 'Percentage', 'MSExample', 'MSPct', 'QCFold'});

pmQCDRArray = zeros(nrows, nfeats);

pmQCDRPred  = zeros(nrows, 1);

end

