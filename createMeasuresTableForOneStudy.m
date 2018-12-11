function [measures, nmeasures] = createMeasuresTableForOneStudy(physdata)

% createMeasuresTable - creates the table of measures

nmeasures = size(unique(physdata.RecordingType),1);
measures = table('Size',[nmeasures 6], 'VariableTypes', {'double', 'cell', 'cell', 'cell', 'double', 'double'} ,'VariableNames', {'Index', 'Name', 'DisplayName', 'Column', 'Mask', 'Bucket'});
measures.Index = (1:nmeasures)';
measures.Name = unique(physdata.RecordingType);
measures.DisplayName = replace(measures.Name, 'Recording', '');
measures.Mask = zeros(nmeasures, 1); % populate during model execution
measures.Bucket = zeros(nmeasures, 1); % populate during model execution

for i = 1:size(measures,1)
     measures.Column(i) = cellstr(getColumnForMeasure(measures.Name{i}));
end

end

