function labelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmampredrows, predictionduration)
                
% checkexStartInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

for b = 1:predictionduration
    labelrow(b) = ...
        any((pmampredrows.Pred <  featureindexrow.CalcDatedn) & ...
            (pmampredrows.Pred >= (featureindexrow.CalcDatedn - b)));   

%        any((pmampredrows.IVStartDate + days(pmampredrows.Ex_Start + pmampredrows.Offset)) < featureindexrow.CalcDate & ...
%            (pmampredrows.IVStartDate + days(pmampredrows.Ex_Start + pmampredrows.Offset)) >= (featureindexrow.CalcDate - days(b)));   

end

end

