function labelrow = checkIVInTimeWindow(featureindexrow, ...
                    pabs, predictionduration)
                
% checkIVInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

for b = 1:predictionduration
    labelrow(b) = any(ismember(pabs.Route, 'IV') & ...
                      pabs.RelStartdn >  featureindexrow.CalcDatedn & ...
                      pabs.RelStartdn <= featureindexrow.CalcDatedn + b);                  
end

end

