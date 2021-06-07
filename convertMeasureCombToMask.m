function [idx] = convertMeasureCombToMask(meascomb, measures, nmeasures)

% convertMeasureCombToMask - convenience function to convert from a measure
% combination id to an index mask

idx = false(nmeasures,1);

switch meascomb
    case 1
        fprintf('Set for no measures\n');
    case 2
        fprintf('Set for all measures\n');
        idx = true(nmeasures,1);
    case 3
        fprintf('Set for LungFunction, O2Saturation, PulseRate\n');
        idx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    case 4
        fprintf('Set for Cough and Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    case 5
        fprintf('Set for Cough, Wellness, LungFunction\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction'});
    case 6
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation'});
    case 7
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate'});
    case 8
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate, Weight\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight'});
    case 9
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate, Weight, Sleep Activity\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'SleepActivity'});
    case 10
        fprintf('Set for Cough, Wellness, Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate'}); 
    case 11
        fprintf('Set for Cough, Wellness, Pulse Rate, LungFunction\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'PulseRate'});
    case 12
        fprintf('Set for Cough, Wellness, Pulse Rate, O2 Saturation\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'O2Saturation'});
    case 13
        fprintf('Set for Cough, Wellness, Pulse Rate, Weight\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'Weight'});
    case 14
        fprintf('Set for Cough, Wellness, Pulse Rate, Weight, Lung Function\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'Weight', 'LungFunction'});
    case 15
        fprintf('Set for Activity\n');
        idx = ismember(measures.DisplayName,{'Activity'});
    case 16
        fprintf('Set for Cough\n');
        idx = ismember(measures.DisplayName,{'Cough'});
    case 17
        fprintf('Set for Lung Function\n');
        idx = ismember(measures.DisplayName,{'LungFunction'});
    case 18
        fprintf('Set for O2 Saturation\n');
        idx = ismember(measures.DisplayName,{'O2Saturation'});
    case 19
        fprintf('Set for Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'PulseRate'});
    case 20
        fprintf('Set for Sleep Activity\n');
        idx = ismember(measures.DisplayName,{'SleepActivity'});    
    case 21
        fprintf('Set for Temperature\n');
        idx = ismember(measures.DisplayName,{'Temperature'});
    case 22
        fprintf('Set for Weight\n');
        idx = ismember(measures.DisplayName,{'Weight'});
    case 23
        fprintf('Set for Wellness\n');
        idx = ismember(measures.DisplayName,{'Wellness'});
    case 24
        fprintf('Set for Lung Function, Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'LungFunction', 'PulseRate'});
    case 25
        fprintf('Set for Lung Function, Pulse Rate, Sleep Activity\n');
        idx = ismember(measures.DisplayName,{'LungFunction', 'PulseRate', 'SleepActivity'});
    case 26
        fprintf('Set for Pulse Rate, Wellness\n');
        idx = ismember(measures.DisplayName,{'PulseRate', 'Wellness'});
    case 27
        fprintf('Set for O2 Saturation, Wellness\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'Wellness'});
    case 28
        fprintf('Set for O2 Saturation, Pulse Rate, Wellness\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate', 'Wellness'});
    case 29
        fprintf('Set for Cough, O2 Saturation, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'Wellness'});
    case 30
        fprintf('Set for O2 Saturation, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'Weight', 'Wellness'});
    case 31
        fprintf('Set for Cough, Wellness, Pulse Rate, LungFunction, Activity\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'PulseRate', 'Activity'});
    case 32
        fprintf('Set for O2 Saturation, Activity\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'Activity'});
    case 33
        fprintf('Set for Pulse Rate, Wellness, Activity\n');
        idx = ismember(measures.DisplayName,{'PulseRate', 'Wellness', 'Activity'});
    case 34
        fprintf('Set for Cough, Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'Cough', 'PulseRate'});
    case 35
        fprintf('Set for Pulse Rate, Weight\n');
        idx = ismember(measures.DisplayName,{'PulseRate', 'Weight'});
    case 36
        fprintf('Set for LungFunction, O2Saturation\n');
        idx = ismember(measures.DisplayName,{'LungFunction', 'O2Saturation'});
    case 37
        fprintf('Set for Cough, LungFunction\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction'});
    case 38
        fprintf('Set for O2 Saturation, PulseRate\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate'});
    case 39
        fprintf('Set for Cough, Wellness, SleepActivity\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'SleepActivity'});
    case 40
        fprintf('Set for Activity, LungFunction, O2Saturation, PulseRate, Weight\n');
        idx = ismember(measures.DisplayName,{'Activity', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight'});
    case 41
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Wellness'});
    case 42
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'Wellness'});
    case 43
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    case 44
        fprintf('Set for Cough, O2Saturation, PulseRate, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    case 45
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction','O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    case 46
        fprintf('Set for Cough, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    case 47
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    case 48
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    case 49
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    case 50
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    case 51
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    case 52
        fprintf('Set for Cough, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    case 53
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    case 54
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    case 55
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    case 56
        fprintf('Set for Activity, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    case 57
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    case 58
        fprintf('Set for Activity, Cough, LungFunction, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    case 59
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, SleepActivity, Temperature, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    case 60
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, Temperature, Weight, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Temperature', 'Weight', 'Wellness'});
    case 61
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Wellness\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Wellness'});
    case 62
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Weight\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight'});
    case 63
        fprintf('Set for LungFunction, O2Saturation, PulseRate, Wellness\n');
        idx = ismember(measures.DisplayName,{'LungFunction', 'O2Saturation', 'PulseRate', 'Wellness'});
    case 64
        fprintf('Set for Cough, LungFunction, O2Saturation, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'Wellness'});
    case 65
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate\n');
        idx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate'});
    case 101
        fprintf('Set for Calorie\n');
        idx = ismember(measures.DisplayName,{'Calorie'});
    case 102
        fprintf('Set for Cough\n');
        idx = ismember(measures.DisplayName,{'Cough'});
    case 103
        fprintf('Set for FEF2575\n');
        idx = ismember(measures.DisplayName,{'FEF2575'});
    case 104
        fprintf('Set for FEV075\n');
        idx = ismember(measures.DisplayName,{'FEV075'});
    case 105
        fprintf('Set for FEV1DivFEV6\n');
        idx = ismember(measures.DisplayName,{'FEV1DivFEV6'});
    case 106
        fprintf('Set for FEV1\n');
        idx = ismember(measures.DisplayName,{'FEV1'});
    case 107
        fprintf('Set for FEV6\n');
        idx = ismember(measures.DisplayName,{'FEV6'});
    case 108
        fprintf('Set for HasColdOrFlu\n');
        idx = ismember(measures.DisplayName,{'HasColdOrFlu'});
    case 109
        fprintf('Set for HasHayFever\n');
        idx = ismember(measures.DisplayName,{'HasHayFever'});
    case 110
        fprintf('Set for MinsAsleep\n');
        idx = ismember(measures.DisplayName,{'MinsAsleep'});
    case 111
        fprintf('Set for MinsAwake\n');
        idx = ismember(measures.DisplayName,{'MinsAwake'});
    case 112
        fprintf('Set for O2 Saturation\n');
        idx = ismember(measures.DisplayName,{'O2Saturation'});
    case 113
        fprintf('Set for Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'PulseRate'});
    case 114
        fprintf('Set for RestingHR\n');
        idx = ismember(measures.DisplayName,{'RestingHR'});
    case 115
        fprintf('Set for Temperature\n');
        idx = ismember(measures.DisplayName,{'Temperature'});
    case 116
        fprintf('Set for Weight\n');
        idx = ismember(measures.DisplayName,{'Weight'});
    case 117
        fprintf('Set for Wellness\n');
        idx = ismember(measures.DisplayName,{'Wellness'});
    case 118
        fprintf('Set for Cough, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    case 119
        fprintf('Set for FEV1, MinsAsleep, RestingHR, Temperature\n');
        idx = ismember(measures.DisplayName,{'FEV1', 'MinsAsleep', 'RestingHR', 'Temperature'});
    case 120
        fprintf('Set for FEV1, MinsAsleep, O2Saturation, RestingHR, Temperature\n');
        idx = ismember(measures.DisplayName,{'FEV1', 'MinsAsleep', 'O2Saturation', 'RestingHR', 'Temperature'});
    case 121
        fprintf('Set for Cough, FEV1, MinsAsleep, RestingHR, Temperature, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'MinsAsleep', 'RestingHR', 'Temperature', 'Wellness'});
    case 122
        fprintf('Set for Cough, FEV1, MinsAsleep, O2Saturation, RestingHR, Temperature, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'MinsAsleep', 'O2Saturation', 'RestingHR', 'Temperature', 'Wellness'});
    case 123
        fprintf('Set for Cough, Wellness, FEV1, O2 Saturation, Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'FEV1', 'O2Saturation', 'PulseRate'});
    case 124
        fprintf('Set for Cough, Wellness, FEV1, O2 Saturation, RestingHR\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'FEV1', 'O2Saturation', 'RestingHR'});
    case 125
        fprintf('Set for FEV1, O2 Saturation, Pulse Rate\n');
        idx = ismember(measures.DisplayName,{'FEV1', 'O2Saturation', 'PulseRate'});
    case 126
        fprintf('Set for FEV1, O2 Saturation, RestingHR\n');
        idx = ismember(measures.DisplayName,{'FEV1', 'O2Saturation', 'RestingHR'});
    case 127
        fprintf('Set for O2 Saturation, Pulse Rate, Wellness\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate', 'Wellness'});
    case 128
        fprintf('Set for O2 Saturation, RestingHR, Wellness\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'RestingHR', 'Wellness'});
    case 129
        fprintf('Set for Cough, FEV1, O2Saturation, RestingHR, Temperature, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'O2Saturation', 'RestingHR', 'Temperature', 'Wellness'});
    case 201
        fprintf('Set for Activity\n');
        idx = ismember(measures.DisplayName,{'Activity'});
    case 202
        fprintf('Set for Appetite\n');
        idx = ismember(measures.DisplayName,{'Appetite'});
    case 203
        fprintf('Set for Breathlessness\n');
        idx = ismember(measures.DisplayName,{'Breathlessness'});
    case 204
        fprintf('Set for Cough\n');
        idx = ismember(measures.DisplayName,{'Cough'});
    case 205
        fprintf('Set for FEV1\n');
        idx = ismember(measures.DisplayName,{'FEV1'});
    case 206
        fprintf('Set for InterpFEV1\n');
        idx = ismember(measures.DisplayName,{'InterpFEV1'});
    case 207
        fprintf('Set for InterpWeight\n');
        idx = ismember(measures.DisplayName,{'InterpWeight'});
    case 208
        fprintf('Set for O2Saturation\n');
        idx = ismember(measures.DisplayName,{'O2Saturation'});
    case 209
        fprintf('Set for PulseRate\n');
        idx = ismember(measures.DisplayName,{'PulseRate'});
    case 210
        fprintf('Set for RespiratoryRate\n');
        idx = ismember(measures.DisplayName,{'RespiratoryRate'});
    case 211
        fprintf('Set for SleepActivity\n');
        idx = ismember(measures.DisplayName,{'SleepActivity'});
    case 212
        fprintf('Set for SleepDisturbance\n');
        idx = ismember(measures.DisplayName,{'SleepDisturbance'});
    case 213
        fprintf('Set for SputumVolume\n');
        idx = ismember(measures.DisplayName,{'SputumVolume'});
    case 214
        fprintf('Set for Temperature\n');
        idx = ismember(measures.DisplayName,{'Temperature'});
    case 215
        fprintf('Set for Tiredness\n');
        idx = ismember(measures.DisplayName,{'Tiredness'});
    case 216
        fprintf('Set for Weight\n');
        idx = ismember(measures.DisplayName,{'Weight'});
    case 217
        fprintf('Set for Wellness\n');
        idx = ismember(measures.DisplayName,{'Wellness'});
    case 218
        fprintf('Set for Cough, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    case 219
        fprintf('Set for Appetite, SleepActivity, SputumVolume, Tiredness\n');
        idx = ismember(measures.DisplayName,{'Appetite', 'SleepActivity', 'SputumVolume', 'Tiredness'});
    case 220
        fprintf('Set for Appetite, Cough, SleepActivity, SputumVolume, Tiredness, Wellness,\n');
        idx = ismember(measures.DisplayName,{'Appetite', 'Cough', 'SleepActivity', 'SputumVolume', 'Tiredness', 'Wellness'});
    case 221
        fprintf('Set for FEV1, O2Saturation, PulseRate\n');
        idx = ismember(measures.DisplayName,{'FEV1', 'O2Saturation', 'PulseRate'});
    case 222
        fprintf('Set for FEV1, O2Saturation, PulseRate, Temperature, Weight\n');
        idx = ismember(measures.DisplayName,{'FEV1', 'O2Saturation', 'PulseRate', 'Temperature', 'Weight'});
    case 223
        fprintf('Set for Cough, FEV1, O2Saturation, PulseRate, Wellness\n');
        idx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'O2Saturation', 'PulseRate', 'Wellness'});
    case 224
        fprintf('Set for Appetite, Cough, FEV1, O2Saturation, PulseRate, SleepActivity, SputumVolume, Temperature, Tiredness, Weight, Wellness,\n');
        idx = ismember(measures.DisplayName,{'Appetite', 'Cough', 'FEV1', 'O2Saturation', 'PulseRate', ...
                                                'SleepActivity', 'SputumVolume', 'Temperature', 'Tiredness', 'Wellness', 'Weight'});
    case 225
        fprintf('Set for Appetite, Breathlessness, Cough, SleepActivity, Wellness\n');
        idx = ismember(measures.DisplayName,{'Appetite', 'Breathlessness', 'Cough', 'SleepActivity', 'Wellness'});
    case 226
        fprintf('Set for PulseRate, Temperature\n');
        idx = ismember(measures.DisplayName,{'PulseRate', 'Temperature'});
    case 227
        fprintf('Set for Appetite, Breathlessness, Cough, PulseRate, SleepActivity, Temperature, Wellness\n');
        idx = ismember(measures.DisplayName,{'Appetite', 'Breathlessness', 'Cough', 'PulseRate', 'SleepActivity', 'Temperature', 'Wellness'});    
    case 228
        fprintf('Set for Activity, Appetite, Breathlessness, Cough, SleepActivity, SleepDisturbance, Tiredness, Wellness,\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Appetite', 'Breathlessness', 'Cough', 'SleepActivity', 'SleepDisturbance', 'Tiredness', 'Wellness'});
    case 229
        fprintf('Set for O2Saturation, PulseRate, Temperature, Weight\n');
        idx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate', 'Temperature', 'Weight'});
    case 230
        fprintf('Set for Activity, Appetite, Breathlessness, Cough, O2Saturation, PulseRate, SleepActivity, SleepDisturbance, Temperature, Tiredness, Weight, Wellness,\n');
        idx = ismember(measures.DisplayName,{'Activity', 'Appetite', 'Breathlessness', 'Cough', 'O2Saturation', ...
                                                 'PulseRate', 'SleepActivity', 'SleepDisturbance', 'Temperature', 'Tiredness', 'Weight', 'Wellness'});
end

end

