function [pmQCDRIndex] = createQCDRTables(nrows)

% createQCDRTables - creates the missingness pattern tables

pmQCDRIndex = table('Size',[nrows, 9], ...
    'VariableTypes', {'double',    'double',   'cell',     'double',  'cell',      'double',  'double',     'double',  'logical'}, ...
    'VariableNames', {'Iteration', 'MoveType', 'MoveDesc', 'Measure', 'ShortName', 'MPIndex', 'MPRelIndex', 'SelPred', 'MoveAccepted'});

end

