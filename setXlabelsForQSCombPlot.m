function [xlabel] = setXlabelsForQSCombPlot(bsqstablerow, filename, type, f4etype, mstype)

% setXlabelsForQSCombPlot - sets the xlabel for the QS Comb plot

if ismember(type, {f4etype})
    if contains(filename, '-MS')
        tempstring = split(bsqstablerow.MSMeas{1}, ':');
    else
        tempstring = split(bsqstablerow.RawMeas{1}, ':');
        if ismember(tempstring(1), {'1'})
            tempstring = split(bsqstablerow.Volatility{1}, ':');
            if ismember(tempstring(1), {'1'})
                tempstring = split(bsqstablerow.PMean{1}, ':');
            end 
        end
    end
elseif ismember(type, {mstype})
    tempstring = split(bsqstablerow.InterpMthd{1}, ':');
end

xlabel = tempstring(2);

end

