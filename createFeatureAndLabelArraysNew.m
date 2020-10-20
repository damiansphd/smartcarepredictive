function [pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels] ...
            = createFeatureAndLabelArraysNew(nexamples, nmeasures, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures)
    
pmFeatureIndex = table('Size',[nexamples, 12], ...
    'VariableTypes', {'double', 'cell', 'double', 'datetime', 'double', 'double', ...
                      'cell', 'double', 'cell', 'double', 'double', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'CalcDate', 'CalcDatedn', 'ScenType', ...
                      'Scenario', 'BaseExample', 'Measure', 'Frequency', 'Percentage', 'MSExample'});

pmMuIndex         = zeros(nexamples, nmeasures);
pmSigmaIndex      = zeros(nexamples, nmeasures);

pmRawMeasFeats   = zeros(nexamples, nrawfeatures);
pmMSFeats        = zeros(nexamples, nmsfeatures);
pmVolFeats       = zeros(nexamples, nvolfeatures);
pmPMeanFeats     = zeros(nexamples, npmeanfeatures);

pmExABxElLabels    = false(nexamples, 1);

end

