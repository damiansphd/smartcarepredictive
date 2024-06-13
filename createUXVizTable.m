function [pmUXVizTable] = createUXVizTable(nrows)

% createUXVizTable - function to create the table to hold the
% list of participants + dates to run the UXViz for the ACE-CF study

pmUXVizTable = table('Size',[nrows, 12], ...
                'VariableTypes', {'cell',         'cell',          'cell',          'double',      ...
                                  'double',       'cell',          'cell',          'cell',        ...
                                  'cell',         'double',        'double',        'double'},     ...
                'VariableNames', {'Description',  'Study',         'Hospital',      'PatientNbr',  ...
                                  'PatientID',    'StudyNumber',   'StudyNumber2',  'StudyEmail',  ...
                                  'Cohort',       'FromRelDn',     'ToRelDn',       'Period'});

end

