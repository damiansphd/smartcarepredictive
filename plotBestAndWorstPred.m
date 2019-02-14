function [pmampred] = plotBestAndWorstPred(pmPatients, pmAntibiotics, pmampred, pmRawDatacube, pmInterpDatacube, ...
                pmTrCVPatientSplit, pmTrCVFeatureIndex, trcvlabels, pmModelRes, pmOverallStats, pmPatientMeasStats, ...
                measures, nmeasures, labelidx, pmFeatureParamsRow, ...
                lbdisplayname, plotsubfolder, basefilename)
            
% plotBestAndWorstPred - compact plots of measures and prediction for the
% best and worst results

ninterventions = size(pmampred,1);
pmampred.SplitNbr(:) = -1.0;
pmampred.IntrDuration(:) = -1.0;
pmampred.MeanPred(:) = -1.0;
pmampred.MedianPred(:) = -1.0;
pmampred.MaxPred(:) = -1.0;
pmampred.MaxPredDay(:) = -1.0;

for i = 1:ninterventions
    pnbr = pmampred.PatientNbr(i);
    exstart = pmampred.Pred(i);
    ivstart = pmampred.IVScaledDateNum(i);
    intridx = pmTrCVFeatureIndex.PatientNbr == pnbr & pmTrCVFeatureIndex.CalcDatedn >= exstart & pmTrCVFeatureIndex.CalcDatedn < ivstart;
    if sum(intridx) ~= 0
        pmampred.SplitNbr(i) = pmTrCVPatientSplit.SplitNbr(pmTrCVPatientSplit.PatientNbr == pnbr);
        pmampred.IntrDuration(i) = ivstart - exstart;
        pmampred.MeanPred(i) = mean(pmModelRes.pmNDayRes(labelidx).Pred(intridx));
        pmampred.MedianPred(i) = median(pmModelRes.pmNDayRes(labelidx).Pred(intridx));
        [pmampred.MaxPred(i), pmampred.MaxPredDay(i)] = max(pmModelRes.pmNDayRes(labelidx).Pred(intridx));
    end
end

pmampred(pmampred.MeanPred == -1,:) = [];

patperpage  = 6;
plotsacross = 5;
npred       = 1;
npat        = ceil(size(pmampred,1) * 0.2);
%npat        = 4;
npages      = ceil(npat/patperpage);
cpage       = 1;
cpat        = 1;
dbfab       = 30; % number of days before ab start to plot
dafab       = 2;  % number of days after ab start to plot
bcolors     = [0.88, 0.88, 0.88; 
               0.95, 0.95, 0.95;
               0.88, 0.88, 0.88;
               0.95, 0.95, 0.95;
               0.88, 0.88, 0.88; 
               0.95, 0.95, 0.95;
               0.88, 0.88, 0.88;
               0.95, 0.95, 0.95];

% 1) Highest True Positives
baseplotname = sprintf('%s - Highest True Positives - Page %d of %d', basefilename, cpage, npages);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');

lgtype = 'TP';
pmampred = sortrows(pmampred, {'MaxPred'}, 'descend');

for i = 1:npat
    pnbr      = pmampred.PatientNbr(i);
    uipypos = 1 - cpat/patperpage;
    uipysz  = 1/patperpage;
    uiptitle = sprintf('Patient %d (Study %s, CV Fold %d): Max %.2f%% Mean %.2f%% Median %.2f%%', pnbr, ...
                pmFeatureParamsRow.StudyDisplayName{1}, pmampred.SplitNbr(i), ...
                100 * pmampred.MaxPred(i), 100 * pmampred.MeanPred(i), 100 * pmampred.MedianPred(i));
    sp(cpat) = uipanel('Parent', p, ...
                  'BorderType', 'none', 'BackgroundColor', bcolors(cpat,:), ...
                  'OuterPosition', [0.0,uipypos, 1.0, uipysz], ...
                  'Title', uiptitle, 'TitlePosition', 'centertop', 'FontSize', 8);
              
    plotCompactMeasAndPredForPatient(pmPatients(pmPatients.PatientNbr == pnbr, :), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr, :), ...
        pmampred(i,:), pmRawDatacube, pmInterpDatacube, ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, npred, plotsacross, dbfab, dafab, sp(cpat), labelidx, ...
        lbdisplayname, lgtype, pmFeatureParamsRow.featureduration)

    cpat = cpat + 1;
    
    if (i == npat)
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f); 
    elseif ((cpat - 1) == patperpage) 
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f);
        cpage = cpage + 1;
        cpat = 1;
        baseplotname = sprintf('%s - Highest True Positives - Page %d of %d', basefilename, cpage, npages);
        [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');    
    end
end

% 2) worst results where there should be a prediction

cpage       = 1;
cpat        = 1;

baseplotname = sprintf('%s - Lowest False Negatives - Page %d of %d', basefilename, cpage, npages);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
lgtype = 'FN';
pmampred = sortrows(pmampred, {'MaxPred'}, 'ascend');

for i = 1:npat
    pnbr      = pmampred.PatientNbr(i);
    uipypos = 1 - cpat/patperpage;
    uipysz  = 1/patperpage;
    uiptitle = sprintf('Patient %d (Study %s, CV Fold %d): Max %.2f%% Mean %.2f%% Median %.2f%%', pnbr, ...
                pmFeatureParamsRow.StudyDisplayName{1}, pmampred.SplitNbr(i), ...
                100 * pmampred.MaxPred(i), 100 * pmampred.MeanPred(i), 100 * pmampred.MedianPred(i));
    sp(cpat) = uipanel('Parent', p, ...
                  'BorderType', 'none', 'BackgroundColor', bcolors(cpat,:), ...
                  'OuterPosition', [0.0,uipypos, 1.0, uipysz], ...
                  'Title', uiptitle, 'TitlePosition', 'centertop', 'FontSize', 8);
              
    plotCompactMeasAndPredForPatient(pmPatients(pmPatients.PatientNbr == pnbr, :), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr, :), ...
        pmampred(i,:), pmRawDatacube, pmInterpDatacube, ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, npred, plotsacross, dbfab, dafab, sp(cpat), labelidx, ...
        lbdisplayname, lgtype, pmFeatureParamsRow.featureduration)

    cpat = cpat + 1;
    
    if (i == npat)
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f); 
    elseif ((cpat - 1) == patperpage) 
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f);
        cpage = cpage + 1;
        cpat = 1;
        baseplotname = sprintf('%s - Lowest False Negatives - Page %d of %d', basefilename, cpage, npages);
        [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');    
    end
end

% 3) (worst) results - highest predictions where there should not be a
% prediction

flidx = trcvlabels(:,labelidx)==false;
flfeatind = pmTrCVFeatureIndex(flidx,:);
[fppred, worstsortidx] = sort(pmModelRes.pmNDayRes(labelidx).Pred(flidx), 'descend');
fpfeatind = flfeatind(worstsortidx,:);
fpfeatind.LBound(:)  = 0;
fpfeatind.UBound(:)  = 0;
fpfeatind.MaxPred(:) = 0;

example = 1;
npat = 15;
fpexamples = fpfeatind(1,:);
fpexamples(1,:) = [];
row = 1;
while example <= npat
    pnbr = fpfeatind.PatientNbr(row);
    if (~ismember(pnbr, fpexamples.PatientNbr) | ...
        (fpfeatind.CalcDatedn(row) < fpexamples.CalcDatedn(fpexamples.PatientNbr == pnbr) - 30 | ...
        fpfeatind.CalcDatedn(row) > fpexamples.CalcDatedn(fpexamples.PatientNbr == pnbr) + 30))
    
        fpexamples(example, :)      = fpfeatind(row,:); 
        fpexamples.LBound(example)  = fpexamples.CalcDatedn(example);
        fpexamples.UBound(example)  = fpexamples.CalcDatedn(example);
        fpexamples.MaxPred(example) = fppred(row);
        example = example + 1;
    end
    row = row + 1;
end

threshold = 0.5;
wthreshidx = fppred > threshold;
for row = 1:size(fppred(wthreshidx),1)
    pnbr = fpfeatind.PatientNbr(row);
    if (fpfeatind.CalcDatedn(row) > fpexamples.CalcDatedn(fpexamples.PatientNbr == pnbr) - 30) & ...
        fpfeatind.CalcDatedn(row) < fpexamples.LBound(fpexamples.PatientNbr == pnbr)
        fpexamples.LBound(fpexamples.PatientNbr == pnbr) = fpfeatind.CalcDatedn(row);
    end
    if (fpfeatind.CalcDatedn(row) < fpexamples.CalcDatedn(fpexamples.PatientNbr == pnbr) + 30) & ...
            fpfeatind.CalcDatedn(row) > fpexamples.UBound(fpexamples.PatientNbr == pnbr)
        fpexamples.UBound(fpexamples.PatientNbr == pnbr) = fpfeatind.CalcDatedn(row);
    end
end

% fake Pred and IVScaledDateNum columns to mirror pmAMPred columns
fpexamples.Pred            = fpexamples.LBound;
fpexamples.IVScaledDateNum = fpexamples.UBound;

cpage       = 1;
cpat        = 1;
npages      = ceil(npat/patperpage);

baseplotname = sprintf('%s - Highest False Positives - Page %d of %d', basefilename, cpage, npages);
[f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');
lgtype = 'FP';

for i = 1:npat
    pnbr = fpexamples.PatientNbr(i);
    lb   = fpexamples.Pred(i);
    ub   = fpexamples.IVScaledDateNum(i);
    
    if (ub - lb) > 30
        dbfab = ub - lb + 5; % number of days before ab start to plot
    else
        dbfab = 30; % number of days before ab start to plot
    end
    dafab = 10; % number of days after ab start to plot
    
    uipypos = 1 - cpat/patperpage;
    uipysz  = 1/patperpage;
    uiptitle = sprintf('Patient %d (Study %s, CV Fold %d): Max %.2f%%', pnbr, ...
                pmFeatureParamsRow.StudyDisplayName{1}, ...
                pmTrCVPatientSplit.SplitNbr(pmTrCVPatientSplit.PatientNbr==pnbr), ...
                100 * fpexamples.MaxPred(i));
    sp(cpat) = uipanel('Parent', p, ...
                  'BorderType', 'none', 'BackgroundColor', bcolors(cpat,:), ...
                  'OuterPosition', [0.0,uipypos, 1.0, uipysz], ...
                  'Title', uiptitle, 'TitlePosition', 'centertop', 'FontSize', 8);
              
    plotCompactMeasAndPredForPatient(pmPatients(pmPatients.PatientNbr == pnbr, :), ...
        pmAntibiotics(pmAntibiotics.PatientNbr == pnbr, :), ...
        fpexamples(i,:), pmRawDatacube, pmInterpDatacube, ...
        pmTrCVFeatureIndex, trcvlabels, pmModelRes, ...
        pmOverallStats, pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr,:), ...
        measures, nmeasures, npred, plotsacross, dbfab, dafab, sp(cpat), labelidx, ...
        lbdisplayname, lgtype, pmFeatureParamsRow.featureduration)

    cpat = cpat + 1;
    
    if (i == npat)
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f); 
    elseif ((cpat - 1) == patperpage) 
        basedir = setBaseDir();
        savePlotInDir(f, baseplotname, basedir, plotsubfolder);
        close(f);
        cpage = cpage + 1;
        cpat = 1;
        baseplotname = sprintf('%s - Highest False Positives - Page %d of %d', basefilename, cpage, npages);
        [f,p] = createFigureAndPanel(baseplotname, 'Portrait', 'A4');    
    end
end
    
    
end
    
    