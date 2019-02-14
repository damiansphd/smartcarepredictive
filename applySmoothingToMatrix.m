function [outputdata] = applySmoothingToMatrix(rawdata, interpdata, smtype, smfn, smwdth, smdirection)

% applySmoothingToMatrix - apply appropriate smoothing to given measurement
% matrix

if smtype == 1
    outputdata = rawdata;
else
    if smtype == 2
        width = smwdth;
    elseif smtype == 3
        width = [(smwdth - 1) 0];
    end
    outputdata = interpdata;
    if smfn == 1
        outputdata = movmean(outputdata, width, smdirection);
    elseif smfn == 2
        outputdata = movmedian(outputdata, width, smdirection);
    elseif smfn == 3
        outputdata = movmax(outputdata, width, smdirection);
    end
    outputdata(isnan(rawdata)) = nan;
end

end

