function pmTrModNewDataResTable = createTrModNewDataResTable(nrows)

% createTrModNewDataResTable - creates a table to store the results for
% running a previously trained pair of predictive and quality classifiers
% against a new data set

pmTrModNewDataResTable = table('Size',[nrows, 45], ...
                'VariableTypes', {'cell',        'cell',        'cell',       'double',      ...
                                  'double',      'double',      'double', ...
                                  'cell',        'cell',        'cell',       'cell',        ...
                                  'double',      'double',      'double',     'double',      'double', ...
                                  'double',      'double',      'double',     'double',      'double', ...
                                  'double',      'double',      'double',     'double',      'double', ...
                                  'double',      'double',      'double',     'double',      'double', ...
                                  'double',      'double',      'double',     'double',      'double', ...
                                  'double',      'double',      'double',     'double',      'double', ...
                                  'double',      'double',      'double',     'double'}, ...
                'VariableNames', {'ModStudy',    'PCModel',     'QCModel',    'QCOpThresh',  ...
                                  'MinDataDays', 'MaxDataGap',  'RecPctGap', ...
                                  'DataStudy',   'DataSet',     'DataScope',  'DaysScope',   ...
                                  'RunDays',     'TotDays',     'PctDaysRun', 'PosLblDays',  'PctPosLblDays', ...
                                  'RunEpi',      'TotEpi',      'PctEpiRun',  'PosLblEpi',   'PctPosLblEpi', ...
                                  'PRAUC',       'ROCAUC',      'Acc',        'PosAcc',      'NegAcc', ...
                                  'HighP',       'MedP',        'LowP',       'ElecHighP',   'ElecMedP', ...
                                  'ElecLowP',    'PScore',      'ElecPScore', 'AvgEpiTPred', 'AvgEpiFPred', ...
                                  'AvgEPV',      'TrigIntrTPR', 'TrigDelay',  'EarlyWarn',   'EpiFPROp', ...
                                  'EpiPredOp',   'IdxOp',       'IntrCount',  'IntrTrig'});
                  
end