function [calibrow] = setCalibrationTableDisplayRow(resultrow, modelcalibration, nbins)

% setCalibrationTableDisplayRow - given a row for the BSQS scores, replace
% score columns with calibration buckets


calibrow = resultrow;
firstscorecol = find(strcmp(calibrow.Properties.VariableNames, 'PScore'), 1);
calibrow(:, firstscorecol:end) = [];


for i = 1:nbins
    tmptext =  strrep(strrep(strrep(modelcalibration.BinRange{i}, ' ', ''), '%', ''), '-','_');
    calibrow(1, {sprintf('Calib%s',tmptext)}) = array2table(modelcalibration.Calibration(i));
end
for i = 1:nbins
    tmptext =  strrep(strrep(strrep(modelcalibration.BinRange{i}, ' ', ''), '%', ''), '-','_');
    calibrow(1, {sprintf('NbrInBin%s', tmptext)}) = array2table(modelcalibration.NbrInBin(i));
end

end

