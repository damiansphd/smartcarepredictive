function [type, f4etype, mstype, doplot] = setTypeForQSCombPlot(filename)

% setTypeForQSCombPlot - set the type for the QS Combination plot

f4etype = 'Fig4E';
mstype = 'Missingness';

if contains(filename, {'ScenR3.13f', 'ScenR4.13f', 'ScenR4.13g', 'CLScen1.1', 'CLScen1.2', 'BRScen1.1', 'BRScen1.2', 'BRScen1.3'})
    type = f4etype;
    doplot = true;
elseif contains(filename, {'ScenM1.1', 'ScenM2.1'})
    type = mstype;
    doplot = true;
else
    type = '';
    doplot = false;
end

end
