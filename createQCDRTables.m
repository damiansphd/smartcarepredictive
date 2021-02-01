function [pmQCDRIndex] = createQCDRTables(nrows)

% createQCDRTables - creates the missingness pattern tables

pmQCDRIndex = table('Size',[nrows, 7], ...
    'VariableTypes', {'double',    'double',   'cell',     'double',  'double',  'double',  'logical'}, ...
    'VariableNames', {'Iteration', 'MoveType', 'MoveDesc', 'Measure', 'MPIndex', 'SelPred', 'MoveAccepted'});

end

