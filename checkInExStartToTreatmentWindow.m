function labelrow = checkInExStartToTreatmentWindow(featureindexrow, ...
                    pmampredrows, pabs, labeltype)
                
% checkInExStartToTreatmentWindow - creates the label array for a given 
% patient/day

labelrow = false(1, 1);

if isequal(labeltype, 'All')
    ampredidx = find(pmampredrows.Pred <= featureindexrow.CalcDatedn & pmampredrows.IVScaledDateNum >= featureindexrow.CalcDatedn, 1, 'first');
elseif isequal(labeltype, 'xEl')
    ampredidx = find(pmampredrows.Pred <= featureindexrow.CalcDatedn & pmampredrows.IVScaledDateNum >= featureindexrow.CalcDatedn & pmampredrows.ElectiveTreatment ~= 'Y', 1, 'first');
else
    fprintf('Unknown Label type');
end

treatidx = find(pabs.RelStartdn >= featureindexrow.CalcDatedn, 1, 'first');

if size(ampredidx,1)~=0 && ...
        (featureindexrow.CalcDatedn >= pmampredrows.Pred(ampredidx) && ...
         featureindexrow.CalcDatedn <= pabs.RelStartdn(treatidx))    
    labelrow = true;
end

end
