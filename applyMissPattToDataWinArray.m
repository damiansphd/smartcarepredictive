function [pmMSDataWinArray, mpidxrow, mpfeatsrow] = applyMissPattToDataWinArray(pmDataWinArray, ...
            mpidxrow, mpfeatsrow, measures, nmeasures, pmModFeatParamsRow)
        
% applyMissPattToDataWinArray - applies a particular missingness pattern to
% the Data Window Array

datawin = pmModFeatParamsRow.datawinduration;
normwin = pmModFeatParamsRow.normwinduration;
totalwin = datawin + normwin;

pmMSDataWinArray = pmDataWinArray;

if mpidxrow.ScenType == 0
    fprintf('Baseline scenario - no missingness to apply\n');
elseif mpidxrow.ScenType == 4
    msex = mpidxrow.MSExample;
    mc = 1;
    for m = 1:nmeasures
        mmsidx = isnan(pmDataWinArray(msex, :, m));
        pmMSDataWinArray(:, mmsidx, m) = nan;

        if measures.RawMeas(m) == 1
            mpfeatsrow( (((mc - 1) * datawin) + 1): (mc * datawin) ) = mmsidx((normwin + 1):totalwin);
            mc = mc + 1;
        end
    end
    mpidxrow.MSPct = sum(mpfeatsrow) * 100 / (datawin * sum(measures.RawMeas));
    fprintf('Actual missingness from example %5d with overall missingness of %2.2f%%\n', ...
        msex, mpidxrow.MSPct);
else
    fprintf('Synthetic scenario - yet to be implemented\n');
end

end

