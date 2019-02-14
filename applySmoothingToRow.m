function [outputrow] = applySmoothingToRow(rawdatarow, interpdatarow, smtype, smfn, smwdth)

% applySmoothingToRow - apply appropriate smoothing to given measurement
% row - only keeping points with underlying raw data points. For use in
% FEV1 vs O2 saturation analysis

if smtype == 1
    outputrow = rawdatarow;
else
    if smtype == 2
        width = smwdth;
    elseif smtype == 3
        width = [(smwdth - 1) 0];
    end
    outputrow = interpdatarow;
    if smfn == 1
        outputrow = movmean(outputrow, width);
    elseif smfn == 2
        outputrow = movmedian(outputrow, width);
    elseif smfn == 3
        outputrow = movmax(outputrow, width);
    end
    outputrow(isnan(rawdatarow)) = nan;
end

end

