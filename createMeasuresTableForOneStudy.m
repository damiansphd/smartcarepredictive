function [measures, nmeasures] = createMeasuresTableForOneStudy(physdata)

% createMeasuresTable - creates the table of measures

nmeasures = size(unique(physdata.RecordingType),1);
measures = table('Size',[nmeasures 14], ...
    'VariableTypes', {'double', 'cell',   'cell',   'cell',   'cell', 'double', ...
                      'double', 'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double'}, ...
    'VariableNames', {'Index', 'Name', 'DisplayName', 'Column', 'ShortName', 'Factor', ...
                      'RawMeas', 'BucketMeas', 'Range', 'Volatility', 'AvgSeg', ...
                      'VolSeg', 'CChange', 'PatMeas'});
measures.Index       = (1:nmeasures)';
measures.Name        = unique(physdata.RecordingType);
measures.DisplayName = replace(measures.Name, 'Recording', '');
measures.Factor      = ones(nmeasures, 1);
measures.Factor(ismember(measures.DisplayName, {'PulseRate'})) = -1;
measures.RawMeas     = zeros(nmeasures, 1); % populate during model execution
measures.BucketMeas  = zeros(nmeasures, 1); % populate during model execution
measures.Range       = zeros(nmeasures, 1); % populate during model execution
measures.Volatility  = zeros(nmeasures, 1); % populate during model execution
measures.AvgSeg      = zeros(nmeasures, 1); % populate during model execution
measures.VolSeg      = zeros(nmeasures, 1); % populate during model execution
measures.CChange     = zeros(nmeasures, 1); % populate during model execution
measures.PatMeas     = zeros(nmeasures, 1); % populate during model execution

for i = 1:size(measures,1)
     measures.Column(i) = cellstr(getColumnForMeasure(measures.Name{i}));
     measures.ShortName(i) = cellstr(getShortNameForMeasure(measures.Name{i}));
end

end

