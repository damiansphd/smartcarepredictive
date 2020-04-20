function [measures, nmeasures] = createMeasuresTableForOneStudy(physdata, study)

% createMeasuresTable - creates the table of measures

nmeasures = size(unique(physdata.RecordingType),1);
measures = table('Size',[nmeasures 17], ...
    'VariableTypes', {'double', 'cell',   'cell',   'cell',   'cell', 'double', ...
                      'double', 'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Index', 'Name', 'DisplayName', 'Column', 'ShortName', 'Factor', ...
                      'RawMeas', 'BucketMeas', 'Range', 'Volatility', 'AvgSeg', ...
                      'VolSeg', 'CChange', 'PMean', 'PStd', 'BuckPMean', 'BuckPStd'});
measures.Index       = (1:nmeasures)';
measures.Name        = unique(physdata.RecordingType);
measures.DisplayName = replace(measures.Name, 'Recording', '');
measures.Factor      = ones(nmeasures, 1);

[invmeasarray] = getInvertedMeasures(study);
%measures.Factor(ismember(measures.DisplayName, {'PulseRate'})) = -1;
measures.Factor(ismember(measures.DisplayName, invmeasarray)) = -1;

measures.RawMeas     = zeros(nmeasures, 1); % populate during model execution
measures.BucketMeas  = zeros(nmeasures, 1); % populate during model execution
measures.Range       = zeros(nmeasures, 1); % populate during model execution
measures.Volatility  = zeros(nmeasures, 1); % populate during model execution
measures.AvgSeg      = zeros(nmeasures, 1); % populate during model execution
measures.VolSeg      = zeros(nmeasures, 1); % populate during model execution
measures.CChange     = zeros(nmeasures, 1); % populate during model execution
measures.PMean       = zeros(nmeasures, 1); % populate during model execution
measures.PStd        = zeros(nmeasures, 1); % populate during model execution
measures.BuckPMean   = zeros(nmeasures, 1); % populate during model execution
measures.BuckPStd    = zeros(nmeasures, 1); % populate during model execution


for i = 1:size(measures,1)
     measures.Column(i) = cellstr(getColumnForMeasure(measures.Name{i}));
     measures.ShortName(i) = cellstr(getShortNameForMeasure(measures.Name{i}));
end

end

