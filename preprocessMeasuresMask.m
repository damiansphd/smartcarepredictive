function [measures] = preprocessMeasuresMask(measures, nmeasures, featureparamsrow)

% preprocessMeasuresMask - set the various masks for different types of
% measure feature

masks = [featureparamsrow.rawmeasfeat; 
         featureparamsrow.bucketfeat ;
         featureparamsrow.rangefeat  ;
         featureparamsrow.volfeat    ;
         featureparamsrow.avgsegfeat ;
         featureparamsrow.volsegfeat ;
         featureparamsrow.cchangefeat;
         featureparamsrow.pmeanfeat;
         featureparamsrow.pstdfeat;
         featureparamsrow.buckpmean;
         featureparamsrow.buckpstd];
     
colnames = {'RawMeas'; 'BucketMeas'; 'Range'; 'Volatility'; 'AvgSeg'; 'VolSeg'; 'CChange'; 'PMean'; 'PStd'; 'BuckPMean'; 'BuckPStd'};

for a = 1:size(masks,1)
    fprintf('Setting %s mask : ', colnames{a});
    keepidx = false(nmeasures,1);
    mask = zeros(nmeasures,1);
    if     masks(a) == 1
        fprintf('Set for no measures\n');
    elseif masks(a) == 2
        fprintf('Set for all measures\n');
        keepidx = true(nmeasures,1);
    elseif masks(a) == 3
        fprintf('Set for LungFunction, O2Saturation, PulseRate\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    elseif masks(a) == 4
        fprintf('Set for Cough and Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    elseif masks(a) == 5
        fprintf('Set for Cough, Wellness, LungFunction\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction'});
    elseif masks(a) == 6
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation'});
    elseif masks(a) == 7
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate'});
    elseif masks(a) == 8
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate, Weight\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight'});
    elseif masks(a) == 9
        fprintf('Set for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate, Weight, Sleep Activity\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'SleepActivity'});
    elseif masks(a) == 10
        fprintf('Set for Cough, Wellness, Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate'}); 
    elseif masks(a) == 11
        fprintf('Set for Cough, Wellness, Pulse Rate, LungFunction\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'PulseRate'});
    elseif masks(a) == 12
        fprintf('Set for Cough, Wellness, Pulse Rate, O2 Saturation\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'O2Saturation'});
    elseif masks(a) == 13
        fprintf('Set for Cough, Wellness, Pulse Rate, Weight\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'Weight'});
    elseif masks(a) == 14
        fprintf('Set for Cough, Wellness, Pulse Rate, Weight, Lung Function\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'Weight', 'LungFunction'});
    elseif masks(a) == 15
        fprintf('Set for Activity\n');
        keepidx = ismember(measures.DisplayName,{'Activity'});
    elseif masks(a) == 16
        fprintf('Set for Cough\n');
        keepidx = ismember(measures.DisplayName,{'Cough'});
    elseif masks(a) == 17
        fprintf('Set for Lung Function\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction'});
    elseif masks(a) == 18
        fprintf('Set for O2 Saturation\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation'});
    elseif masks(a) == 19
        fprintf('Set for Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate'});
    elseif masks(a) == 20
        fprintf('Set for Sleep Activity\n');
        keepidx = ismember(measures.DisplayName,{'SleepActivity'});    
    elseif masks(a) == 21
        fprintf('Set for Temperature\n');
        keepidx = ismember(measures.DisplayName,{'Temperature'});
    elseif masks(a) == 22
        fprintf('Set for Weight\n');
        keepidx = ismember(measures.DisplayName,{'Weight'});
    elseif masks(a) == 23
        fprintf('Set for Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Wellness'});
    elseif masks(a) == 24
        fprintf('Set for Lung Function, Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction', 'PulseRate'});
    elseif masks(a) == 25
        fprintf('Set for Lung Function, Pulse Rate, Sleep Activity\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction', 'PulseRate', 'SleepActivity'});
    elseif masks(a) == 26
        fprintf('Set for Pulse Rate, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate', 'Wellness'});
    elseif masks(a) == 27
        fprintf('Set for O2 Saturation, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation', 'Wellness'});
    elseif masks(a) == 28
        fprintf('Set for O2 Saturation, Pulse Rate, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate', 'Wellness'});
    elseif masks(a) == 29
        fprintf('Set for Cough, O2 Saturation, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'Wellness'});
    elseif masks(a) == 30
        fprintf('Set for O2 Saturation, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation', 'Weight', 'Wellness'});
    elseif masks(a) == 31
        fprintf('Set for Cough, Wellness, Pulse Rate, LungFunction, Activity\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'PulseRate', 'Activity'});
    elseif masks(a) == 32
        fprintf('Set for O2 Saturation, Activity\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation', 'Activity'});
    elseif masks(a) == 33
        fprintf('Set for Pulse Rate, Wellness, Activity\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate', 'Wellness', 'Activity'});
    elseif masks(a) == 34
        fprintf('Set for Cough, Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'PulseRate'});
    elseif masks(a) == 35
        fprintf('Set for Pulse Rate, Weight\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate', 'Weight'});
    elseif masks(a) == 36
        fprintf('Set for LungFunction, O2Saturation\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction', 'O2Saturation'});
    elseif masks(a) == 37
        fprintf('Set for Cough, LungFunction\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction'});
    elseif masks(a) == 38
        fprintf('Set for O2 Saturation, PulseRate\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate'});
    elseif masks(a) == 39
        fprintf('Set for Cough, Wellness, SleepActivity\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'SleepActivity'});
    elseif masks(a) == 40
        fprintf('Set for Activity, LungFunction, O2Saturation, PulseRate, Weight\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight'});
    elseif masks(a) == 41
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Wellness'});
    elseif masks(a) == 42
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'Wellness'});
    elseif masks(a) == 43
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    elseif masks(a) == 44
        fprintf('Set for Cough, O2Saturation, PulseRate, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    elseif masks(a) == 45
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction','O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    elseif masks(a) == 46
        fprintf('Set for Cough, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    elseif masks(a) == 47
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    elseif masks(a) == 48
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'Weight', 'Wellness'});
    elseif masks(a) == 49
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    elseif masks(a) == 50
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, SleepActivity, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Wellness'});
    elseif masks(a) == 51
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    elseif masks(a) == 52
        fprintf('Set for Cough, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    elseif masks(a) == 53
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    elseif masks(a) == 54
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, SleepActivity, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Weight', 'Wellness'});
    elseif masks(a) == 55
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    elseif masks(a) == 56
        fprintf('Set for Activity, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    elseif masks(a) == 57
        fprintf('Set for Activity, Cough, O2Saturation, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    elseif masks(a) == 58
        fprintf('Set for Activity, Cough, LungFunction, PulseRate, SleepActivity, Temperature, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    elseif masks(a) == 59
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, SleepActivity, Temperature, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'SleepActivity', 'Temperature', 'Weight', 'Wellness'});
    elseif masks(a) == 60
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, Temperature, Weight, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'Temperature', 'Weight', 'Wellness'});
    elseif masks(a) == 61
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Wellness'});
    elseif masks(a) == 62
        fprintf('Set for Activity, Cough, LungFunction, O2Saturation, PulseRate, SleepActivity, Temperature, Weight\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Cough', 'LungFunction', 'O2Saturation', 'PulseRate', 'SleepActivity', 'Temperature', 'Weight'});
    elseif masks(a) == 63
        fprintf('Set for LungFunction, O2Saturation, PulseRate, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction', 'O2Saturation', 'PulseRate', 'Wellness'});
    elseif masks(a) == 64
        fprintf('Set for Cough, LungFunction, O2Saturation, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'Wellness'});
    elseif masks(a) == 65
        fprintf('Set for Cough, LungFunction, O2Saturation, PulseRate\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'LungFunction', 'O2Saturation', 'PulseRate'});
    elseif masks(a) == 101
        fprintf('Set for Calorie\n');
        keepidx = ismember(measures.DisplayName,{'Calorie'});
    elseif masks(a) == 102
        fprintf('Set for Cough\n');
        keepidx = ismember(measures.DisplayName,{'Cough'});
    elseif masks(a) == 103
        fprintf('Set for FEF2575\n');
        keepidx = ismember(measures.DisplayName,{'FEF2575'});
    elseif masks(a) == 104
        fprintf('Set for FEV075\n');
        keepidx = ismember(measures.DisplayName,{'FEV075'});
    elseif masks(a) == 105
        fprintf('Set for FEV1DivFEV6\n');
        keepidx = ismember(measures.DisplayName,{'FEV1DivFEV6'});
    elseif masks(a) == 106
        fprintf('Set for FEV1\n');
        keepidx = ismember(measures.DisplayName,{'FEV1'});
    elseif masks(a) == 107
        fprintf('Set for FEV6\n');
        keepidx = ismember(measures.DisplayName,{'FEV6'});
    elseif masks(a) == 108
        fprintf('Set for HasColdOrFlu\n');
        keepidx = ismember(measures.DisplayName,{'HasColdOrFlu'});
    elseif masks(a) == 109
        fprintf('Set for HasHayFever\n');
        keepidx = ismember(measures.DisplayName,{'HasHayFever'});
    elseif masks(a) == 110
        fprintf('Set for MinsAsleep\n');
        keepidx = ismember(measures.DisplayName,{'MinsAsleep'});
    elseif masks(a) == 111
        fprintf('Set for MinsAwake\n');
        keepidx = ismember(measures.DisplayName,{'MinsAwake'});
    elseif masks(a) == 112
        fprintf('Set for O2 Saturation\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation'});
    elseif masks(a) == 113
        fprintf('Set for Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate'});
    elseif masks(a) == 114
        fprintf('Set for RestingHR\n');
        keepidx = ismember(measures.DisplayName,{'RestingHR'});
    elseif masks(a) == 115
        fprintf('Set for Temperature\n');
        keepidx = ismember(measures.DisplayName,{'Temperature'});
    elseif masks(a) == 116
        fprintf('Set for Weight\n');
        keepidx = ismember(measures.DisplayName,{'Weight'});
    elseif masks(a) == 117
        fprintf('Set for Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Wellness'});
    elseif masks(a) == 118
        fprintf('Set for Cough, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    elseif masks(a) == 119
        fprintf('Set for FEV1, MinsAsleep, RestingHR, Temperature\n');
        keepidx = ismember(measures.DisplayName,{'FEV1', 'MinsAsleep', 'RestingHR', 'Temperature'});
    elseif masks(a) == 120
        fprintf('Set for FEV1, MinsAsleep, O2Saturation, RestingHR, Temperature\n');
        keepidx = ismember(measures.DisplayName,{'FEV1', 'MinsAsleep', 'O2Saturation', 'RestingHR', 'Temperature'});
    elseif masks(a) == 121
        fprintf('Set for Cough, FEV1, MinsAsleep, RestingHR, Temperature, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'MinsAsleep', 'RestingHR', 'Temperature', 'Wellness'});
    elseif masks(a) == 122
        fprintf('Set for Cough, FEV1, MinsAsleep, O2Saturation, RestingHR, Temperature, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'MinsAsleep', 'O2Saturation', 'RestingHR', 'Temperature', 'Wellness'});
    elseif masks(a) == 201
        fprintf('Set for Activity\n');
        keepidx = ismember(measures.DisplayName,{'Activity'});
    elseif masks(a) == 202
        fprintf('Set for Appetite\n');
        keepidx = ismember(measures.DisplayName,{'Appetite'});
    elseif masks(a) == 203
        fprintf('Set for Breathlessness\n');
        keepidx = ismember(measures.DisplayName,{'Breathlessness'});
    elseif masks(a) == 204
        fprintf('Set for Cough\n');
        keepidx = ismember(measures.DisplayName,{'Cough'});
    elseif masks(a) == 205
        fprintf('Set for FEV1\n');
        keepidx = ismember(measures.DisplayName,{'FEV1'});
    elseif masks(a) == 206
        fprintf('Set for InterpFEV1\n');
        keepidx = ismember(measures.DisplayName,{'InterpFEV1'});
    elseif masks(a) == 207
        fprintf('Set for InterpWeight\n');
        keepidx = ismember(measures.DisplayName,{'InterpWeight'});
    elseif masks(a) == 208
        fprintf('Set for O2Saturation\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation'});
    elseif masks(a) == 209
        fprintf('Set for PulseRate\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate'});
    elseif masks(a) == 210
        fprintf('Set for RespiratoryRate\n');
        keepidx = ismember(measures.DisplayName,{'RespiratoryRate'});
    elseif masks(a) == 211
        fprintf('Set for SleepActivity\n');
        keepidx = ismember(measures.DisplayName,{'SleepActivity'});
    elseif masks(a) == 212
        fprintf('Set for SleepDisturbance\n');
        keepidx = ismember(measures.DisplayName,{'SleepDisturbance'});
    elseif masks(a) == 213
        fprintf('Set for SputumVolume\n');
        keepidx = ismember(measures.DisplayName,{'SputumVolume'});
    elseif masks(a) == 214
        fprintf('Set for Temperature\n');
        keepidx = ismember(measures.DisplayName,{'Temperature'});
    elseif masks(a) == 215
        fprintf('Set for Tiredness\n');
        keepidx = ismember(measures.DisplayName,{'Tiredness'});
    elseif masks(a) == 216
        fprintf('Set for Weight\n');
        keepidx = ismember(measures.DisplayName,{'Weight'});
    elseif masks(a) == 217
        fprintf('Set for Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Wellness'});
    elseif masks(a) == 218
        fprintf('Set for Cough, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    elseif masks(a) == 219
        fprintf('Set for Appetite, SleepActivity, SputumVolume, Tiredness\n');
        keepidx = ismember(measures.DisplayName,{'Appetite', 'SleepActivity', 'SputumVolume', 'Tiredness'});
    elseif masks(a) == 220
        fprintf('Set for Appetite, Cough, SleepActivity, SputumVolume, Tiredness, Wellness,\n');
        keepidx = ismember(measures.DisplayName,{'Appetite', 'Cough', 'SleepActivity', 'SputumVolume', 'Tiredness', 'Wellness'});
    elseif masks(a) == 221
        fprintf('Set for FEV1, O2Saturation, PulseRate\n');
        keepidx = ismember(measures.DisplayName,{'FEV1', 'O2Saturation', 'PulseRate'});
    elseif masks(a) == 222
        fprintf('Set for FEV1, O2Saturation, PulseRate, Temperature, Weight\n');
        keepidx = ismember(measures.DisplayName,{'FEV1', 'O2Saturation', 'PulseRate', 'Temperature', 'Weight'});
    elseif masks(a) == 223
        fprintf('Set for Cough, FEV1, O2Saturation, PulseRate, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'FEV1', 'O2Saturation', 'PulseRate', 'Wellness'});
    elseif masks(a) == 224
        fprintf('Set for Appetite, Cough, FEV1, O2Saturation, PulseRate, SleepActivity, SputumVolume, Temperature, Tiredness, Weight, Wellness,\n');
        keepidx = ismember(measures.DisplayName,{'Appetite', 'Cough', 'FEV1', 'O2Saturation', 'PulseRate', ...
                                                'SleepActivity', 'SputumVolume', 'Temperature', 'Tiredness', 'Wellness', 'Weight'});
    elseif masks(a) == 225
        fprintf('Set for Appetite, Breathlessness, Cough, SleepActivity, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Appetite', 'Breathlessness', 'Cough', 'SleepActivity', 'Wellness'});
    elseif masks(a) == 226
        fprintf('Set for PulseRate, Temperature\n');
        keepidx = ismember(measures.DisplayName,{'PulseRate', 'Temperature'});
    elseif masks(a) == 227
        fprintf('Set for Appetite, Breathlessness, Cough, PulseRate, SleepActivity, Temperature, Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Appetite', 'Breathlessness', 'Cough', 'PulseRate', 'SleepActivity', 'Temperature', 'Wellness'});    
    elseif masks(a) == 228
        fprintf('Set for Activity, Appetite, Breathlessness, Cough, SleepActivity, SleepDisturbance, Tiredness, Wellness,\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Appetite', 'Breathlessness', 'Cough', 'SleepActivity', 'SleepDisturbance', 'Tiredness', 'Wellness'});
    elseif masks(a) == 229
        fprintf('Set for O2Saturation, PulseRate, Temperature, Weight\n');
        keepidx = ismember(measures.DisplayName,{'O2Saturation', 'PulseRate', 'Temperature', 'Weight'});
    elseif masks(a) == 230
        fprintf('Set for Activity, Appetite, Breathlessness, Cough, O2Saturation, PulseRate, SleepActivity, SleepDisturbance, Temperature, Tiredness, Weight, Wellness,\n');
        keepidx = ismember(measures.DisplayName,{'Activity', 'Appetite', 'Breathlessness', 'Cough', 'O2Saturation', ...
                                                 'PulseRate', 'SleepActivity', 'SleepDisturbance', 'Temperature', 'Tiredness', 'Weight', 'Wellness'});
    end
    
    mask(keepidx) = 1;
    measures(:, colnames(a)) = array2table(mask);
end

% If both raw and bucketed features are set for a given measure, update to
% have only bucketed to avoid duplicative features

for m = 1:nmeasures
    if measures.RawMeas(m) && measures.BucketMeas(m)
        fprintf('Both raw and bucketed features selected for %s - keep only bucketed\n', measures.DisplayName{m});
        measures.RawMeas(m) = 0;
    end
    if measures.PMean(m) && measures.BuckPMean(m)
        fprintf('Both raw and bucketed patient mean selected for %s - keep only bucketed\n', measures.DisplayName{m});
        measures.PMean(m) = 0;
    end
    if measures.PStd(m) && measures.BuckPStd(m)
        fprintf('Both raw and bucketed patient std selected for %s - keep only bucketed\n', measures.DisplayName{m});
        measures.PStd(m) = 0;
    end
end

end

