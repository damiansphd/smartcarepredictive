function labelrow = checkExStartInTimeWindow(featureindexrow, ...
                    ampredrows, ex_start, predictionduration)
                
% checkexStartInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

for b = 1:predictionduration
    labelrow(b) = ...
        any((ampredrows.IVStartDate + days(ex_start + ampredrows.Offset)) < featureindexrow.CalcDate & ...
            (ampredrows.IVStartDate + days(ex_start + ampredrows.Offset)) >= (featureindexrow.CalcDate - days(b)));   
end

end

