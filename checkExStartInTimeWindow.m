function labelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmampredrows, predictionduration)
                
% checkexStartInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

for b = 1:predictionduration
    labelrow(b) = ...
        any((pmampredrows.Pred <=  featureindexrow.CalcDatedn) & ...
            (pmampredrows.Pred >= (featureindexrow.CalcDatedn - b)));   
end

end

