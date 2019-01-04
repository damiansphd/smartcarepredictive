function [measures] = preprocessMeasuresMask(measures, nmeasures, featureparamsrow)

% preprocessMeasuresMask - set the various masks for different types of
% measure feature

masks = [featureparamsrow.rawmeasfeat; 
         featureparamsrow.bucketfeat ;
         featureparamsrow.rangefeat  ;
         featureparamsrow.volfeat];
     
colnames = {'RawMeas'; 'BucketMeas'; 'Range'; 'Volatility'};

for a = 1:size(masks,1)
    fprintf('Setting %s mask\n', colnames{a});
    keepidx = false(nmeasures,1);
    mask = zeros(nmeasures,1);
    if     masks(a) == 1
        fprintf('Set to use raw features for no measures\n');
    elseif masks(a) == 2
        fprintf('Set to use raw features for all measures\n');
        keepidx = true(nmeasures,1);
    elseif masks(a) == 3
        fprintf('Set to use raw features for LungFunction, O2Saturation, PulseRate\n');
        keepidx = ismember(measures.DisplayName,{'LungFunction','O2Saturation', 'PulseRate'});
    elseif masks(a) == 4
        fprintf('Set to use raw features for Cough and Wellness\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness'});
    elseif masks(a) == 5
        fprintf('Set to use raw features for Cough, Wellness, LungFunction\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction'});
    elseif masks(a) == 6
        fprintf('Set to use raw features for Cough, Wellness, LungFunction, O2 Saturation\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation'});
    elseif masks(a) == 7
        fprintf('Set to use raw features for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate'});
    elseif masks(a) == 8
        fprintf('Set to use raw features for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate, Weight\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight'});
    elseif masks(a) == 9
        fprintf('Set to use raw features for Cough, Wellness, LungFunction, O2 Saturation, Pulse Rate, Weight, Sleep Activity\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'O2Saturation', 'PulseRate', 'Weight', 'SleepActivity'});
    elseif masks(a) == 10
        fprintf('Set to use raw features for Cough, Wellness, Pulse Rate\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate'}); 
    elseif masks(a) == 11
        fprintf('Set to use raw features for Cough, Wellness, Pulse Rate, LungFunction\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'LungFunction', 'PulseRate'});
    elseif masks(a) == 12
        fprintf('Set to use raw features for Cough, Wellness, Pulse Rate, O2 Saturation\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'O2Saturation'});
    elseif masks(a) == 13
        fprintf('Set to use raw features for Cough, Wellness, Pulse Rate, Weight\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'Weight'});
    elseif masks(a) == 14
        fprintf('Set to use raw features for Cough, Wellness, Pulse Rate, Weight, Lung Function\n');
        keepidx = ismember(measures.DisplayName,{'Cough', 'Wellness', 'PulseRate', 'Weight', 'LungFunction'});
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
end

end

