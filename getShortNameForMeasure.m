function [shortname] = getShortNameForMeasure(measure)

% getShortNameForMeasure - returns the short name from physdata for the
% measure passed in

switch measure
    case 'ActivityRecording'
        shortname = 'Ac';
    case {'CoughRecording'}
        shortname = 'Co';
    case 'LungFunctionRecording'
        shortname = 'Lu';
    case 'O2SaturationRecording'
        shortname = 'O2';
    case 'PulseRateRecording'
        shortname = 'Pu';
    case {'SleepActivityRecording'}
        shortname = 'Sl';
    case 'TemperatureRecording'
        shortname = 'Te';
    case 'WeightRecording'
        shortname = 'Wt';
    case {'WellnessRecording'}
        shortname = 'We';    
    otherwise
        shortname = '';
end

end

