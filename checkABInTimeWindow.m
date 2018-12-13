function labelrow = checkABInTimeWindow(featureindexrow, ...
                    pabs, predictionduration)
                
% checkABInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

for b = 1:predictionduration
    labelrow(b) = any(pabs.RelStartdn >  featureindexrow.CalcDatedn & ...
                      pabs.RelStartdn <= featureindexrow.CalcDatedn + b);                  
end

end

