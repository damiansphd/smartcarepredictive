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

