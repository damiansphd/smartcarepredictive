function labelrow = checkIVInTimeWindow(featureindexrow, ...
                    pabs, predictionduration)
                
% checkIVInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

for b = 1:predictionduration
    labelrow(b) = any(ismember(pabs.Route, 'IV') & ...
                      pabs.StartDate >= featureindexrow.CalcDate & ...
                      pabs.StartDate <= (featureindexrow.CalcDate + days(b)));   
end

end

