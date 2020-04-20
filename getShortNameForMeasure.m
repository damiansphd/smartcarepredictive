function [shortname] = getShortNameForMeasure(measure)

% getShortNameForMeasure - returns the short name from physdata for the
% measure passed in

switch measure
    case 'ActivityRecording'
        shortname = 'Ac';
    case 'AppetiteRecording'
        shortname = 'Ap';
    case 'BreathlessnessRecording'
        shortname = 'Br'; 
    case {'CoughRecording'}
        shortname = 'Co';
    case 'LungFunctionRecording'
        shortname = 'Lu';
    case 'O2SaturationRecording'
        shortname = 'O2';
    case 'PulseRateRecording'
        shortname = 'Pu';
    case 'RespiratoryRateRecording'
        shortname = 'Rr';
    case {'SleepActivityRecording'}
        shortname = 'Sl';
    case {'SleepDisturbanceRecording'}
        shortname = 'Sd';
    case {'SputumVolumeRecording'}
        shortname = 'Sv';
    case 'TemperatureRecording'
        shortname = 'Te';
    case 'TirednessRecording'
        shortname = 'Ti';
    case 'WeightRecording'
        shortname = 'Wt';
    case {'WellnessRecording'}
        shortname = 'We';    
    otherwise
        shortname = '';
end

end

