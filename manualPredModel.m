function [pred] = manualPredModel(pmInterpNormcube, normfeatures, pred, measures, nmeasures, npatients, maxdays, featureduration)

% manualPredModel - function to manually predict based on a pre-defined set
% of rules/logic

measures.Weight(:) = 0;
measures.Cap(:)    = 0;
measures.Floor(:)  = 0;

for m = 1:nmeasures
    if ismember(measures.DisplayName(m), {'Activity', 'SleepActivity', 'Temperature'})
        measures.Weight(m) = 0.1;
    elseif ismember(measures.DisplayName(m), {'O2Saturation', 'Weight'})
        measures.Weight(m) = 0.2;
    elseif ismember(measures.DisplayName(m), {'LungFunction', 'PulseRate'})
        measures.Weight(m) = 0.4;
    elseif ismember(measures.DisplayName(m), {'Cough', 'Wellness'})
        measures.Weight(m) = 0.6;
    end
    data = reshape(pmInterpNormcube(:, :, m), [1 (npatients * maxdays)]);
    data = data(~isnan(data))';
    measures.Floor(m) = std(data);
    measures.Cap(m) = 2 * measures.Floor(m);
end

nexamples = size(normfeatures,1);
nrawmeas = sum(measures.RawMeas);
rmmeasures = measures(measures.RawMeas==1,:);
ntiles = 4;
navgsize = floor(featureduration/ntiles);
mavg = zeros(ntiles,1);
mscore = zeros(nrawmeas,1);

for n = 1:nexamples
    
    featurerow = normfeatures(n,:);
    
    for m = 1:nrawmeas
        
        factor = 1;
        if isequal(rmmeasures.DisplayName{m}, 'PulseRate')
            factor = -1;
        end
        
        for i = 1:ntiles
            idx = (m * featureduration) - ((i - 1) * navgsize);
            mavg(i) = factor * mean(featurerow((idx - navgsize + 1):idx));
        end
        
        for i = 2:ntiles
            if mavg(i) > mavg(i - 1)
                mscore(m) = mscore(m) + mavg(i) - mavg(i - 1);
            else
                break;
            end
        end
        
        if mscore(m) > rmmeasures.Cap(m)
            mscore(m) = rmmeasures.Cap(m);
        end
        if mscore(m) < rmmeasures.Floor(m);
            mscore(m) = rmmeasures.Floor(m)
        
        mscore(m) = (rmmeasures.Weight(m) * (mscore(m) - rmmeasures.Floor)) / (rmmeasures.Cap(m) - rmmeasures.Floor(m));
        
    end
    
    pred(n) = sum(mscore) / sum(rmmeasures.Weight);
end


end

