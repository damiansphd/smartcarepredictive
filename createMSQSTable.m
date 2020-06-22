function msTestQS = createMSQSTable(nmsscenarios)

% createMSQSTable - creates a table to store the results from missingness
% analysis

msTestQS = table('Size',[nmsscenarios, 27], ...
                'VariableTypes', {'double', 'double', 'cell',   'double', 'double', 'double', ...
                                  'double', 'double', 'cell',   'double', 'double', 'double', ...
                                  'double', 'double', 'double', 'double', 'double', 'double', ...
                                  'double', 'double', 'double', 'double', 'double', 'double', ...
                                  'double', 'double', 'double'}, ...
                'VariableNames', {'ScenarioNbr', 'PatientNbr', 'Study', 'ID', 'ScaledDateNumFrom', 'ScaledDateNumTo', ...
                                  'ScenarioType', 'MMask', 'MMaskText', 'Frequency', 'Duration', 'Percentage', ...
                                  'AvgLoss', 'PScore', 'ElecPScore', 'AvgEpiTPred', 'AvgEpiFPred', 'AvgEPV', ...
                                  'PRAUC', 'ROCAUC', 'Acc', 'PosAcc', 'NegAcc', 'MaxTPred', ...
                                  'AvgTPred', 'MinFPred', 'AvgFPred'});

end

