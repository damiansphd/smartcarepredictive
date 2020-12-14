function plotMissPattAnalysis(pmQCModelRes, pmMissPattIndex, pmMissPattArray, pmMissPattQSPct, labels, ...
        opthresh, labelthreshold, fpthresh, nexanal, measures, datawin, baseqcdatasetfile, plotsubfolder, qsmeasure)

% plotMissPattAnalysis - gets the extreme examples from the QC data set for
% each model outcome and presents them visually

nmeas = sum(measures.RawMeas);
measarray = measures.DisplayName(logical(measures.RawMeas));

nfeat = size(pmMissPattArray, 2);

qspctarray = table2array(pmMissPattQSPct(:, {qsmeasure}));
showlegend = false;
rectbuff   = 0.2;

ocarray = {'TP', 'FP1', 'FP2', 'TN', 'FN'};

for oc = 1:size(ocarray, 2)
    outcome = ocarray{oc};
    
    ocidx = getIndexForOutcome(pmQCModelRes.Pred, labels, qspctarray, opthresh, fpthresh / 100, outcome);

    switch outcome
        case {'TP', 'FN'}
            temp = sort(pmMissPattIndex.MSPct(ocidx), 'descend');
            xlowerb = temp(nexanal) - rectbuff;
            xupperb = max(pmMissPattIndex.MSPct(ocidx)) + rectbuff;
            ylowerb = labelthreshold - rectbuff;
            yupperb = 100 * max(qspctarray) + rectbuff;
        case {'FP1', 'FP2', 'TN'}
            temp = sort(pmMissPattIndex.MSPct(ocidx), 'ascend');
            xlowerb = min(pmMissPattIndex.MSPct(ocidx)) - rectbuff;
            xupperb = temp(nexanal) + rectbuff;
            ylowerb = 100 * min(qspctarray(ocidx)) - rectbuff;
            yupperb = labelthreshold + rectbuff;
    end

    xidx = extractIdxForRange(pmMissPattIndex.MSPct, xlowerb, xupperb);
    yidx = extractIdxForRange(100 * qspctarray, ylowerb, yupperb);

    anidx = xidx & yidx & ocidx;
    nanex = sum(anidx);

    anmisspattindex = pmMissPattIndex(anidx, :);
    %if ismember({outcome}, {'TP', 'FN'})
        anmisspattarray = ~pmMissPattArray(anidx, :);
    %else
    %    anmisspattarray = pmMissPattArray(anidx, :);
    %end

    anmisspattqspct = qspctarray(anidx);

    baseplotname = sprintf('%s%s%sMPAn', baseqcdatasetfile, qsmeasure, outcome);
    widthinch = 15;
    heightinch = 10;
    labelfontsize = 8;
    name = '';
    plotsacross = 2;
    plotsdown = 2;

    [f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
    ax = subplot(plotsdown, plotsacross, 1, 'Parent', p);

    tpidx  = false(size(labels, 1), 1);
    fp1idx = false(size(labels, 1), 1);
    fp2idx = false(size(labels, 1), 1);
    tnidx  = false(size(labels, 1), 1);
    fnidx  = false(size(labels, 1), 1);

    switch outcome
        case 'TP'
            tpidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'TP');
        case 'FP1'
            fp1idx = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'FP1');
        case 'FP2'
            fp2idx = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'FP2');
        case 'TN'
            tnidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'TN');
        case 'FN'
            fnidx  = getIndexForOutcome(pmQCModelRes.Pred, labels, table2array(pmMissPattQSPct(:, {qsmeasure})), opthresh, fpthresh / 100, 'FN');
    end

    plotMissQSByMeasPlotFcn(ax, pmMissPattIndex.MSPct, 100 * qspctarray, labelthreshold, fpthresh, ...
                qsmeasure, 'Overall', tpidx, fp1idx, fp2idx, tnidx, fnidx, outcome, showlegend);

    hold on;
    plotRectangle(ax, xlowerb, xupperb, ylowerb, yupperb, [0.5 0.5 0.5], 0.5, '-');
    hold off;

    ax = subplot(plotsdown, plotsacross, [3:4], 'Parent', p);

    for m = 0:nmeas
        line(ax, [(m * datawin) + 0.5  (m * datawin) + 0.5], [0 nexanal + 1], ...
            'Color', [0.5 0.5 0.5], ...
            'LineStyle', ':', ...
            'LineWidth', 0.5, ...
            'Marker', 'none');
    end

    xlim(ax, [0 nfeat + 0.5]);
    ylim(ax, [0 nexanal + 1.5]);
    xlabel('Features', 'FontSize', labelfontsize);
    ylabel('Examples', 'FontSize', labelfontsize);

    hbuff = 0.5;
    vbuff = 0.2;
    hold on;
    for n = nexanal:-1:1
        for i = 1:nfeat
            if logical(anmisspattarray(n, i))
                plotActFillArea(ax, i - hbuff, i + hbuff, n - vbuff, n + vbuff, [0.5 0.5 0.5], 1, 'none');
                %plotRectangle(ax, i - hbuff, i + hbuff, n - vbuff, n + vbuff, 'black', 0.5, '-');
            end
        end
    end
    
    n = nexanal + 1;
    misspattsum = sum(anmisspattarray, 1);
    maxval = max(misspattsum);
    minval = min(misspattsum);
    range = maxval - minval;
    %baseval = 1/size(anmisspattarray, 1);
    baseval = 1/range;
    basecol = [baseval baseval baseval];
    for i = 1:nfeat
        cellcol = 1 - (basecol * (misspattsum(i) - minval));
        plotActFillArea(ax, i - hbuff, i + hbuff, n - vbuff, n + vbuff, cellcol, 1, 'none');
    end
    

    hold off;

    basedir = setBaseDir();
    savePlotInDir(f, baseplotname, basedir, plotsubfolder);
    close(f);
    
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
                anmisspattindex.MSPct(i), 100 * anmisspattqspct(i), strrep(num2str(anmisspattarray(i, mfrom:mto)), ' ', ''));
        end
        fprintf('---- ---------- ----- ----- ---------------------------\n');
        fprintf('                             %25s\n', strrep(num2str(sum(anmisspattarray(:, mfrom:mto), 1)), ' ', ''));
        fprintf('\n');
        end

    end



end

