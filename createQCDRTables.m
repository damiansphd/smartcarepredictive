function [pmQCDRIndex] = createQCDRTables(nrows)

% createQCDRTables - creates the missingness pattern tables

pmQCDRIndex = table('Size',[nrows, 7], ...
    'VariableTypes', {'double',    'double',   'cell',     'double',  'double',  'double',  'logical'}, ...
    'VariableNames', {'Iteration', 'MoveType', 'MoveDesc', 'Measure', 'MPIndex', 'SelPred', 'MoveAccepted'});

%if nrows == 1
%    pmQCDRMissPatt    = zeros(nrawmeas, mpdur);
%    pmQCDRDataWin     = zeros(nrawmeas, dwdur);
%else
%    pmQCDRMissPatt    = zeros(nrows, nrawmeas, mpdur);
%    pmQCDRDataWin     = zeros(nrows, nrawmeas, dwdur);
%end
%
%pmQCDRFeatures     = zeros(nrows, nrawmeas * dwdur);
%pmQCDRCyclicPred   = zeros(nrows, cyclicdur);

end

