function [pmMSDataWinArray, mpidxrow, mpfeatsrow] = applyMissPattToDataWinArray(pmDataWinArray, ...
            mpidxrow, mpfeatsrow, measures, nmeasures, pmModFeatParamsRow, qcdrtw2Dam)
        
% applyMissPattToDataWinArray - applies a particular missingness pattern to
% the Data Window Array

datawin = pmModFeatParamsRow.datawinduration;
normwin = pmModFeatParamsRow.normwinduration;
totalwin = datawin + normwin;

pmMSDataWinArray = pmDataWinArray;

if mpidxrow.ScenType == 0
    fprintf('Baseline scenario - no missingness to apply\n');

elseif mpidxrow.ScenType == 2
    mspct      = mpidxrow.Percentage;
    ndwarrayel = totalwin * nmeasures;
    nmsfeats   = size(mpfeatsrow, 2);
    nrem       = ceil(ndwarrayel * mspct / 100);
    posarray   = randperm(ndwarrayel, nrem);
    featidx    = zeros(1, ndwarrayel);
    featidx(posarray) = 1;
    measfeats = reshape(featidx', totalwin, nmeasures)';
    % need to fix this - loop over all measures and check if rawmeas == 1
    % etc
    for m = 1:nmeasures
        pmMSDataWinArray(:, logical(measfeats(m, :)), m) = nan;
    end
    rmmeasfeats = measfeats(logical(measures.RawMeas), normwin+1:totalwin);
    mpfeatsrow  = reshape(rmmeasfeats', nmsfeats, 1)';
    mpidxrow.MSPct = sum(mpfeatsrow) * 100 / (datawin * sum(measures.RawMeas));
    fprintf('Random percentage missingness with overall missingness of %2.2f%%\n', ...
        mpidxrow.MSPct);
    
elseif mpidxrow.ScenType == 4
    msex = mpidxrow.MSExample;
    mc   = 1;
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

elseif mpidxrow.ScenType == 8
    mc   = 1;
    for m = 1:nmeasures
        mmsidx = logical(qcdrtw2Dam(m, :));
        pmMSDataWinArray(:, mmsidx, m) = nan;
        
        if measures.RawMeas(m) == 1
            mpfeatsrow( (((mc - 1) * datawin) + 1): (mc * datawin) ) = mmsidx((normwin + 1):totalwin);
            mc = mc + 1;
        end
    end
    mpidxrow.MSPct = sum(mpfeatsrow) * 100 / (datawin * sum(measures.RawMeas));
    fprintf('Min Data rules missingness with overall missingness of %2.2f%%\n', ...
        mpidxrow.MSPct);
else
    fprintf('Scenario - yet to be implemented\n');
end
  
end

