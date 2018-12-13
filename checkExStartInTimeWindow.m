function labelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmampredrows, predictionduration, labeltype)
                
% checkexStartInTimeWindow - creates the label array for a given patient/day
labelrow = false(1, predictionduration);

if isequal(labeltype, 'Pred')
    for b = 1:predictionduration
        labelrow(b) = ...
            any((pmampredrows.Pred <=  featureindexrow.CalcDatedn) & ...
                (pmampredrows.Pred >= (featureindexrow.CalcDatedn - b)));   
    end
elseif isequal(labeltype, 'LB')
    for b = 1:predictionduration
        labelrow(b) = ...
            any((pmampredrows.RelLB1 <=  featureindexrow.CalcDatedn) & ...
                (pmampredrows.RelLB1 >= (featureindexrow.CalcDatedn - b)));   
    end
else
    fprintf('Unknown label type')
end

end

