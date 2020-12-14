function analyseMissPatts(pmQCModelRes, pmMissPattIndex, pmMissPattArray, pmMissPattQSPct, labels, ...
        predthresh, labelthreshold, fpthreshold, outcome, qsmeasure, measures, featureparams)

% analyseMissPatt - gets the extreme examples from the QC data set for a
% given model outcome and presents them visually

datawin = featureparams.datawinduration;

nmeas = sum(measures.RawMeas);
measarray = measures.DisplayName(logical(measures.RawMeas));

switch outcome
        case 'TP'
            ocidx  = pmQCModelRes.Pred >= predthresh & labels == 1;
        case 'FP1'
            ocidx = pmQCModelRes.Pred >= predthresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) >= fpthreshold / 100;
        case 'FP2'
            ocidx = pmQCModelRes.Pred >= predthresh & labels == 0 & table2array(pmMissPattQSPct(:, {qsmeasure})) <  fpthreshold / 100;
        case 'TN'
            ocidx  = pmQCModelRes.Pred <  predthresh & labels == 0;
        case 'FN'
            ocidx  = pmQCModelRes.Pred <  predthresh & labels == 1;
end

% determine upper and lower bounds here
% hardcode for now
xlowerb = 65;
xupperb = 100;
ylowerb = 90;
yupperb = 200;

xidx = extractIdxForRange(pmMissPattIndex.MSPct, xlowerb, xupperb);
yidx = extractIdxForRange(100 * table2array(pmMissPattQSPct(:, {qsmeasure})), ylowerb, yupperb);

anidx = xidx & yidx & ocidx;
nanex = sum(anidx);

anmisspattindex = pmMissPattIndex(anidx, :);
if ismember({outcome}, {'TP', 'FN'})
    anmisspattarray = ~pmMissPattArray(anidx, :);
else
    anmisspattarray = pmMissPattArray(anidx, :);
end

anmisspattqspct = pmMissPattQSPct(anidx, :);

for m = 1:nmeas
    mfrom = (m - 1) * datawin + 1;
    mto   = m * datawin;
    
    fprintf('Measure: %13s\n', measarray{m});
    fprintf('----------------------\n');
    fprintf('\n');
    fprintf('Fold  Scenario  MSPct QSPct Inverse Missingness Pattern\n');
    fprintf('---- ---------- ----- ----- ---------------------------\n');
    
    for i = 1:nanex
        fprintf('  %1d  %10s %5.1f %5.1f  %25s\n', anmisspattindex.QCFold(i), anmisspattindex.Scenario{i}, ...
            anmisspattindex.MSPct(i), 100 * anmisspattqspct.AvgEPV(i), strrep(num2str(anmisspattarray(i, mfrom:mto)), ' ', ''));
    end
    fprintf('---- ---------- ----- ----- ---------------------------\n');
    fprintf('                             %25s\n', strrep(num2str(sum(anmisspattarray(:, mfrom:mto), 1)), ' ', ''));
    fprintf('\n');
end

end

