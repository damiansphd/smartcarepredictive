function labelrow = checkInExStartToTreatmentWindow(featureindexrow, ...
                    pmampredrows, pabs)
                
% checkInExStartToTreatmentWindow - creates the label array for a given 
% patient/day

labelrow = false(1, 1);

ampredidx = find(pmampredrows.Pred <= featureindexrow.CalcDatedn & pmampredrows.IVScaledDateNum >= featureindexrow.CalcDatedn, 1, 'first');

treatidx = find(pabs.RelStartdn >= featureindexrow.CalcDatedn, 1, 'first');

if size(ampredidx,1)~=0 && (featureindexrow.CalcDatedn >= pmampredrows.Pred(ampredidx) && ...
        featureindexrow.CalcDatedn <= pabs.RelStartdn(treatidx))    
    labelrow = true;
end

end

