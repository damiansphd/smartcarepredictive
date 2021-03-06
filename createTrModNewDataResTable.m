function pmTrModNewDataResTable = createTrModNewDataResTable(nrows)

% createTrModNewDataResTable - creates a table to store the results for
% running a previously trained pair of predictive and quality classifiers
% against a new data set

pmTrModNewDataResTable = table('Size',[nrows, 18], ...
                'VariableTypes', {'cell',      'cell',    'cell',       'double',     ...
                                  'cell',      'cell',    'cell',       'cell',       ...
                                  'double',    'double',  'double',     'double',     'double', ...
                                  'double',    'double',  'double',     'double',     'double'}, ...
                'VariableNames', {'ModStudy',  'PCModel', 'QCModel',    'QCOpThresh', ...
                                  'DataStudy', 'DataSet', 'DataScope',  'DaysScope',  ...
                                  'RunDays',   'TotDays', 'PctDaysRun', 'PosLblDays', 'PctPosLblDays', ... 
                                  'PRAUC',     'ROCAUC',  'Acc',        'PosAcc',     'NegAcc'});

end
