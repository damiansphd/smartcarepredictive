function [modelcalibration] = calcModelCalibration(testlabels, modeldaypred, binedges, nbins, fold)

% calcModelCalibration - calculates the model calibration (and plots the
% results)

nexamples = size(testlabels, 1);
modelcalibration = table('Size',[nbins, 6], ...
    'VariableTypes', {'double', 'double', 'cell',     'double',     'double',   'double'}, ...
    'VariableNames', {'Fold',   'Bin',    'BinRange', 'TrueLabels', 'NbrInBin', 'Calibration'});
results = [modeldaypred, testlabels, zeros(nexamples, 1)];

for n = 1:nbins
    if n < nbins
        idx = results(:,1) >= binedges(n) & results(:,1) < binedges(n + 1);
    else
        idx = results(:,1) >= binedges(n) & results(:,1) <= binedges(n + 1);
    end
    results(idx, 3) = n;
end

for n = 1:nbins
    modelcalibration.Fold(n) = fold;
    modelcalibration.Bin(n) = n;
    idx = (results(:, 3) == n);
    modelcalibration.BinRange{n}    = sprintf('%3.0f - %3.0f%%', 100 * binedges(n), 100 * binedges(n+1));
    modelcalibration.TrueLabels(n)  = sum(results(idx, 2));
    modelcalibration.NbrInBin(n)    = size(results(idx, 2), 1);
    modelcalibration.Calibration(n) = 100 * modelcalibration.TrueLabels(n) / modelcalibration.NbrInBin(n);
end
                
end

